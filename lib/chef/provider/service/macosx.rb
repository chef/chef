#
# Author:: Igor Afonov <afonov@gmail.com>
# Copyright:: Copyright 2011-2016, Igor Afonov
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "etc"
require "rexml/document"
require "chef/resource/service"
require "chef/resource/macosx_service"
require "chef/provider/service/simple"
require "chef/util/path_helper"

class Chef
  class Provider
    class Service
      class Macosx < Chef::Provider::Service::Simple

        provides :macosx_service, os: "darwin"
        provides :service, os: "darwin"

        def self.gather_plist_dirs
          locations = %w{/Library/LaunchAgents
                         /Library/LaunchDaemons
                         /System/Library/LaunchAgents
                         /System/Library/LaunchDaemons }
          Chef::Util::PathHelper.home("Library", "LaunchAgents") { |p| locations << p }
          locations
        end

        PLIST_DIRS = gather_plist_dirs

        def this_version_or_newer?(this_version)
          Gem::Version.new(node["platform_version"]) >= Gem::Version.new(this_version)
        end

        def load_current_resource
          @current_resource = Chef::Resource::MacosxService.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)
          @plist_size = 0
          @plist = @new_resource.plist ? @new_resource.plist : find_service_plist
          @service_label = find_service_label
          # LauchAgents should be loaded as the console user.
          @console_user = @plist ? @plist.include?("LaunchAgents") : false
          @session_type = @new_resource.session_type

          if @console_user
            @console_user = Etc.getlogin
            Chef::Log.debug("#{new_resource} console_user: '#{@console_user}'")
            cmd = "su "
            param = this_version_or_newer?("10.10") ? "" : "-l "
            @base_user_cmd = cmd + param + "#{@console_user} -c"
            # Default LauchAgent session should be Aqua
            @session_type = "Aqua" if @session_type.nil?
          end

          Chef::Log.debug("#{new_resource} Plist: '#{@plist}' service_label: '#{@service_label}'")
          set_service_status

          @current_resource
        end

        def define_resource_requirements
          requirements.assert(:reload) do |a|
            a.failure_message Chef::Exceptions::UnsupportedAction, "#{self} does not support :reload"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @plist_size < 2 }
            a.failure_message Chef::Exceptions::Service, "Several plist files match service name. Please use full service name."
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exists?(@plist.to_s) }
            a.failure_message Chef::Exceptions::Service,
              "Could not find plist for #{@new_resource}"
          end

          requirements.assert(:enable, :disable) do |a|
            a.assertion { !@service_label.to_s.empty? }
            a.failure_message Chef::Exceptions::Service,
              "Could not find service's label in plist file '#{@plist}'!"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @plist_size > 0 }
            # No failure here in original code - so we also will not
            # fail. Instead warn that the service is potentially missing
            a.whyrun "Assuming that the service would have been previously installed and is currently disabled." do
              @current_resource.enabled(false)
              @current_resource.running(false)
            end
          end
        end

        def start_service
          if @current_resource.running
            Chef::Log.debug("#{@new_resource} already running, not starting")
          else
            if @new_resource.start_command
              super
            else
              load_service
            end
          end
        end

        def stop_service
          unless @current_resource.running
            Chef::Log.debug("#{@new_resource} not running, not stopping")
          else
            if @new_resource.stop_command
              super
            else
              unload_service
            end
          end
        end

        def restart_service
          if @new_resource.restart_command
            super
          else
            unload_service
            sleep 1
            load_service
          end
        end

        # On OS/X, enabling a service has the side-effect of starting it,
        # and disabling a service has the side-effect of stopping it.
        #
        # This makes some sense on OS/X since launchctl is an "init"-style
        # supervisor that will restart daemons that are crashing, etc.
        def enable_service
          if @current_resource.enabled
            Chef::Log.debug("#{@new_resource} already enabled, not enabling")
          else
            load_service
          end
        end

        def disable_service
          unless @current_resource.enabled
            Chef::Log.debug("#{@new_resource} not enabled, not disabling")
          else
            unload_service
          end
        end

        def load_service
          session = @session_type ? "-S #{@session_type} " : ""
          cmd = "launchctl load -w " + session + @plist
          shell_out_as_user(cmd)
        end

        def unload_service
          cmd = "launchctl unload -w " + @plist
          shell_out_as_user(cmd)
        end

        def shell_out_as_user(cmd)
          if @console_user
            shell_out_with_systems_locale("#{@base_user_cmd} '#{cmd}'")
          else
            shell_out_with_systems_locale(cmd)

          end
        end

        def set_service_status
          return if @plist.nil? || @service_label.to_s.empty?

          cmd = "launchctl list #{@service_label}"
          res = shell_out_as_user(cmd)

          if res.exitstatus == 0
            @current_resource.enabled(true)
          else
            @current_resource.enabled(false)
          end

          if @current_resource.enabled
            res.stdout.each_line do |line|
              case line.downcase
              when /\s+\"pid\"\s+=\s+(\d+).*/
                pid = $1
                @current_resource.running(!pid.to_i.zero?)
                Chef::Log.debug("Current PID for #{@service_label} is #{pid}")
              end
            end
          else
            @current_resource.running(false)
          end
        end

        private

        def find_service_label
          # CHEF-5223 "you can't glob for a file that hasn't been converged
          # onto the node yet."
          return nil if @plist.nil?

          # Plist must exist by this point
          raise Chef::Exceptions::FileNotFound, "Cannot find #{@plist}!" unless ::File.exists?(@plist)

          # Most services have the same internal label as the name of the
          # plist file. However, there is no rule saying that *has* to be
          # the case, and some core services (notably, ssh) do not follow
          # this rule.

          # plist files can come in XML or Binary formats. this command
          # will make sure we get XML every time.
          plist_xml = shell_out_with_systems_locale!(
            "plutil -convert xml1 -o - #{@plist}"
          ).stdout

          plist_doc = REXML::Document.new(plist_xml)
          plist_doc.elements[
            "/plist/dict/key[text()='Label']/following::string[1]/text()"]
        end

        def find_service_plist
          plists = PLIST_DIRS.inject([]) do |results, dir|
            edir = ::File.expand_path(dir)
            entries = Dir.glob(
              "#{edir}/*#{Chef::Util::PathHelper.escape_glob_dir(@current_resource.service_name)}*.plist"
            )
            entries.any? ? results << entries : results
          end
          plists.flatten!
          @plist_size = plists.size
          plists.first
        end
      end
    end
  end
end
