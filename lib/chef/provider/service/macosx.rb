#
# Author:: Igor Afonov <afonov@gmail.com>
# Copyright:: Copyright (c) 2011 Igor Afonov
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

require 'rexml/document'
require 'chef/resource/service'
require 'chef/provider/service/simple'

class Chef
  class Provider
    class Service
      class Macosx < Chef::Provider::Service::Simple
        include Chef::Mixin::ShellOut

        def self.gather_plist_dirs
          locations = %w{/Library/LaunchAgents
                         /Library/LaunchDaemons
                         /System/Library/LaunchAgents
                         /System/Library/LaunchDaemons }

          locations << "#{ENV['HOME']}/Library/LaunchAgents" if ENV['HOME']
          locations
        end

        PLIST_DIRS = gather_plist_dirs

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)
          @plist_size = 0
          @plist = find_service_plist
          @service_label = find_service_label
          set_service_status

          @current_resource
        end

        def define_resource_requirements
          #super
          requirements.assert(:reload) do |a|
            a.failure_message Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :reload"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @plist_size < 2 }
            a.failure_message Chef::Exceptions::Service, "Several plist files match service name. Please use full service name."
          end

          requirements.assert(:enable, :disable) do |a|
            a.assertion { !@service_label.to_s.empty? }
            a.failure_message Chef::Exceptions::Service,
              "Could not find service's label in plist file '#{@plist}'!"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @plist_size > 0 }
            # No failrue here in original code - so we also will not
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
              shell_out!("launchctl load -w '#{@plist}'", :user => @owner_uid, :group => @owner_gid)
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
              shell_out!("launchctl unload '#{@plist}'", :user => @owner_uid, :group => @owner_gid)
            end
          end
        end

        def restart_service
          if @new_resource.restart_command
            super
          else
            stop_service
            sleep 1
            start_service
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
            shell_out!(
              "launchctl load -w '#{@plist}'",
              :user => @owner_uid, :group => @owner_gid
            )
          end
        end

        def disable_service
          unless @current_resource.enabled
            Chef::Log.debug("#{@new_resource} not enabled, not disabling")
          else
            shell_out!(
              "launchctl unload -w '#{@plist}'",
              :user => @owner_uid, :group => @owner_gid
            )
          end
        end

        def set_service_status
          return if @plist == nil or @service_label.to_s.empty?

          cmd = shell_out(
            "launchctl list #{@service_label}",
            :user => @owner_uid, :group => @owner_gid
          )

          if cmd.exitstatus == 0
            @current_resource.enabled(true)
          else
            @current_resource.enabled(false)
          end

          if @current_resource.enabled
            @owner_uid = ::File.stat(@plist).uid
            @owner_gid = ::File.stat(@plist).gid

            shell_out!(
              "launchctl list", :user => @owner_uid, :group => @owner_gid
            ).stdout.each_line do |line|
              case line
              when /(\d+|-)\s+(?:\d+|-)\s+(.*\.?)#{@service_label}/
                pid = $1
                @current_resource.running(!pid.to_i.zero?)
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

          # Most services have the same internal label as the name of the
          # plist file. However, there is no rule saying that *has* to be
          # the case, and some core services (notably, ssh) do not follow
          # this rule.

          # plist files can come in XML or Binary formats. this command
          # will make sure we get XML every time.
          plist_xml = shell_out!("plutil -convert xml1 -o - #{@plist}").stdout

          plist_doc = REXML::Document.new(plist_xml)
          plist_doc.elements[
            "/plist/dict/key[text()='Label']/following::string[1]/text()"]
        end

        def find_service_plist
          plists = PLIST_DIRS.inject([]) do |results, dir|
            edir = ::File.expand_path(dir)
            entries = Dir.glob(
              "#{edir}/*#{@current_resource.service_name}*.plist"
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
