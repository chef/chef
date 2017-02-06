#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

require "chef/provider/service/init"

class Chef
  class Provider
    class Service
      class Redhat < Chef::Provider::Service::Init

        # @api private
        attr_accessor :service_missing
        # @api private
        attr_accessor :current_run_levels

        provides :service, platform_family: %w{rhel fedora suse} do |node|
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:redhat)
        end

        CHKCONFIG_ON = /\d:on/
        CHKCONFIG_MISSING = /No such/

        def self.supports?(resource, action)
          Chef::Platform::ServiceHelpers.config_for_service(resource.service_name).include?(:initd)
        end

        def initialize(new_resource, run_context)
          super
          @init_command = "/sbin/service #{new_resource.service_name}"
          @service_missing = false
          @current_run_levels = []
        end

        # @api private
        def run_levels
          new_resource.run_levels
        end

        def define_resource_requirements
          shared_resource_requirements

          requirements.assert(:all_actions) do |a|
            chkconfig_file = "/sbin/chkconfig"
            a.assertion { ::File.exists? chkconfig_file  }
            a.failure_message Chef::Exceptions::Service, "#{chkconfig_file} does not exist!"
          end

          requirements.assert(:enable) do |a|
            a.assertion { !@service_missing }
            a.failure_message Chef::Exceptions::Service, "#{new_resource}: Service is not known to chkconfig."
            a.whyrun "Assuming service would be enabled. The init script is not presently installed."
          end

          requirements.assert(:start, :reload, :restart) do |a|
            a.assertion do
              new_resource.init_command || custom_command_for_action?(action) || !@service_missing
            end
            a.failure_message Chef::Exceptions::Service, "#{new_resource}: No custom command for #{action} specified and unable to locate the init.d script!"
            a.whyrun "Assuming service would be enabled. The init script is not presently installed."
          end
        end

        def load_current_resource
          supports[:status] = true if supports[:status].nil?

          super

          if ::File.exists?("/sbin/chkconfig")
            chkconfig = shell_out!("/sbin/chkconfig --list #{current_resource.service_name}", :returns => [0, 1])
            unless run_levels.nil? || run_levels.empty?
              all_levels_match = true
              chkconfig.stdout.split(/\s+/)[1..-1].each do |level|
                index = level.split(":").first
                status = level.split(":").last
                if level =~ CHKCONFIG_ON
                  @current_run_levels << index.to_i
                  all_levels_match = false unless run_levels.include?(index.to_i)
                else
                  all_levels_match = false if run_levels.include?(index.to_i)
                end
              end
              current_resource.enabled(all_levels_match)
            else
              current_resource.enabled(!!(chkconfig.stdout =~ CHKCONFIG_ON))
            end
            @service_missing = !!(chkconfig.stderr =~ CHKCONFIG_MISSING)
          end

          current_resource
        end

        # @api private
        def levels
          (run_levels.nil? || run_levels.empty?) ? "" : "--level #{run_levels.join('')} "
        end

        def enable_service
          unless run_levels.nil? || run_levels.empty?
            disable_levels = current_run_levels - run_levels
            shell_out! "/sbin/chkconfig --level #{disable_levels.join('')} #{new_resource.service_name} off" unless disable_levels.empty?
          end
          shell_out! "/sbin/chkconfig #{levels}#{new_resource.service_name} on"
        end

        def disable_service
          shell_out! "/sbin/chkconfig #{levels}#{new_resource.service_name} off"
        end
      end
    end
  end
end
