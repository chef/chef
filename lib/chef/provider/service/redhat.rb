#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/provider/service/init'

class Chef
  class Provider
    class Service
      class Redhat < Chef::Provider::Service::Init

        CHKCONFIG_ON = /\d:on/
        CHKCONFIG_MISSING = /No such/

        provides :service, platform_family: [ "rhel", "fedora", "suse" ]

        def self.provides?(node, resource)
          super && Chef::Platform::ServiceHelpers.service_resource_providers.include?(:redhat)
        end

        def self.supports?(resource, action)
          Chef::Platform::ServiceHelpers.config_for_service(resource.service_name).include?(:initd)
        end

        def initialize(new_resource, run_context)
          super
          @init_command = "/sbin/service #{@new_resource.service_name}"
          @new_resource.supports[:status] = true
          @service_missing = false
        end

        def define_resource_requirements
          shared_resource_requirements

          requirements.assert(:all_actions) do |a|
            chkconfig_file = "/sbin/chkconfig"
            a.assertion { ::File.exists? chkconfig_file  }
            a.failure_message Chef::Exceptions::Service, "#{chkconfig_file} does not exist!"
          end

          requirements.assert(:start, :enable, :reload, :restart) do |a|
            a.assertion { !@service_missing }
            a.failure_message Chef::Exceptions::Service, "#{@new_resource}: unable to locate the init.d script!"
            a.whyrun "Assuming service would be disabled. The init script is not presently installed."
          end
        end

        def load_current_resource
          super

          if ::File.exists?("/sbin/chkconfig")
            chkconfig = shell_out!("/sbin/chkconfig --list #{@current_resource.service_name}", :returns => [0,1])
            @current_resource.enabled(!!(chkconfig.stdout =~ CHKCONFIG_ON))
            @service_missing = !!(chkconfig.stderr =~ CHKCONFIG_MISSING)
          end

          @current_resource
        end

        def enable_service()
          shell_out! "/sbin/chkconfig #{@new_resource.service_name} on"
        end

        def disable_service()
          shell_out! "/sbin/chkconfig #{@new_resource.service_name} off"
        end
      end
    end
  end
end
