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

require 'chef/provider/service'
require 'chef/provider/service/init'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Invokercd < Chef::Provider::Service::Init
        
        def initialize(new_resource, run_context)
          super
          # cause chef to fail for policy violations
          if @new_resource.error_on_policy_violation
            @init_command = "/usr/sbin/invoke-rc.d --disclose-deny #{@new_resource.service_name}"
          else
            @init_command = "/usr/sbin/invoke-rc.d #{@new_resource.service_name}"
          end
          @policy_command = "/usr/sbin/policy-rc.d #{@new_resource.service_name}"
          if ::File.exists?("/usr/sbin/policy-rc.d")
             test_policy()
          end
        end
       
        def test_policy
          policy_status = run_command(:command => "#{@policy_command} start", :ignore_failure => "true")
          if policy_status != 0 
             Chef::Log.warn("#{@policy_command} returned non-zero(#{policy_status}) exit status")
             Chef::Log.warn("#{@new_resource} will likely fail to start/stop silently")
          end
        end 

      end
    end
  end
end
