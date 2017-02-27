#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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

class Chef
  module DSL
    # Lazy activation for the chef-provisioning gem. Specifically, we set up methods for
    # each resource and DSL method in chef-provisioning which, when invoked, will
    # require 'chef-provisioning' (which will define the actual method) and then call the
    # method chef-provisioning defined.
    module ChefProvisioning
      %w{
        add_machine_options
        current_image_options
        current_machine_options
        load_balancer
        machine_batch
        machine_execute
        machine_file
        machine_image
        machine
        with_driver
        with_image_options
        with_machine_options
      }.each do |method_name|
        eval(<<-EOM, binding, __FILE__, __LINE__ + 1)
          def #{method_name}(*args, &block)
            Chef::DSL::ChefProvisioning.load_chef_provisioning
            self.#{method_name}(*args, &block)
          end
        EOM
      end

      def self.load_chef_provisioning
        # Remove all chef-provisioning methods; they will be added back in by chef-provisioning
        public_instance_methods(false).each do |method_name|
          remove_method(method_name)
        end
        require "chef/provisioning"
      end
    end
  end
end
