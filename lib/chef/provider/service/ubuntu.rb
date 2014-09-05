#
# Author:: Lamont Granquist <lamont@getchef.com>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/provider/service/upstart'
require 'chef/provider/service/debian'
require 'forwardable'

class Chef
  class Provider
    class Service
      class Ubuntu
        extend Forwardable

        attr_reader :sub_service

        def_delegator :@sub_service, :load_current_resource
        def_delegator :@sub_service, :action_start
        def_delegator :@sub_service, :action_stop
        def_delegator :@sub_service, :action_restart
        def_delegator :@sub_service, :action_enable
        def_delegator :@sub_service, :action_disable
        def_delegator :@sub_service, :define_resource_requirements
        def_delegator :@sub_service, :whyrun_supported?
        def_delegator :@sub_service, :action=
        def_delegator :@sub_service, :run_action

        def initialize(new_resource, run_context)
          platform, version = Chef::Platform.find_platform_and_version(run_context.node)
          if platform == "ubuntu" && (8.04..9.04).include?(version.to_f)
            upstart_job_dir = "/etc/event.d"
            upstart_conf_suffix = ""
          else
            upstart_job_dir = "/etc/init"
            upstart_conf_suffix = ".conf"
          end

          @sub_service =
            if ::File.exists?("#{upstart_job_dir}/#{new_resource.service_name}#{upstart_conf_suffix}")
              Chef::Provider::Service::Upstart.new(new_resource, run_context)
            else
              Chef::Provider::Service::Debian.new(new_resource, run_context)
            end
        end
      end
    end
  end
end
