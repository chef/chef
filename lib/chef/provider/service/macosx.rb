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

require 'chef/provider/service'

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
          set_service_status

          @current_resource
        end

        def define_resource_requirements
          #super
          requirements.assert(:enable) do |a|
            a.failure_message Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :enable"
          end

          requirements.assert(:disable) do |a|
            a.failure_message Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :disable"
          end

          requirements.assert(:reload) do |a|
            a.failure_message Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :reload"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @plist_size < 2 }
            a.failure_message Chef::Exceptions::Service, "Several plist files match service name. Please use full service name."
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


        def set_service_status
          return if @plist == nil

          @current_resource.enabled(!@plist.nil?)

          if @current_resource.enabled
            @owner_uid = ::File.stat(@plist).uid
            @owner_gid = ::File.stat(@plist).gid

            shell_out!("launchctl list", :user => @owner_uid, :group => @owner_gid).stdout.each_line do |line|
              case line
              when /(\d+|-)\s+(?:\d+|-)\s+(.*\.?)#{@current_resource.service_name}/
                pid = $1
                @current_resource.running(!pid.to_i.zero?)
              end
            end
          else
            @current_resource.running(false)
          end
        end

      private

        def find_service_plist
          plists = PLIST_DIRS.inject([]) do |results, dir|
            entries = Dir.glob("#{::File.expand_path(dir)}/*#{@current_resource.service_name}*.plist")
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
