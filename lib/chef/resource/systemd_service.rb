#
# Author:: Davide Cavalca (<dcavalca@fb.com>)
# Copyright:: Copyright (c) 2015 Facebook
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

require 'chef/resource/service'
require 'chef/provider/service/systemd'

class Chef
  class Resource
    class SystemdService < Chef::Resource::Service
      provides :service, os: "linux" do |node|
        Chef::Platform::ServiceHelpers.service_resource_providers.include?(:systemd)
      end

      state_attrs :enabled, :running, :masked

      allowed_actions :enable, :disable, :start, :stop, :restart, :reload,
                      :mask, :unmask

      def initialize(name, run_context=nil)
        super
        @masked = nil
      end

      # if the service is masked or not
      def masked(arg=nil)
        set_or_return(
          :masked,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end
    end
  end
end
