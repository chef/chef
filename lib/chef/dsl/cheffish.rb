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
    # Lazy activation for the cheffish gem. Specifically, we set up methods for
    # each resource and DSL method in cheffish which, when invoked, will
    # require 'cheffish' (which will define the actual method) and then call the
    # method cheffish defined.
    module Cheffish
      %w{
        chef_acl
        chef_client
        chef_container
        chef_data_bag_item
        chef_data_bag
        chef_environment
        chef_group
        chef_mirror
        chef_node
        chef_organization
        chef_role
        chef_user
        private_key
        public_key
        with_chef_data_bag
        with_chef_environment
        with_chef_data_bag_item_encryption
        with_chef_server
        with_chef_local_server
        get_private_key
      }.each do |method_name|
        eval(<<-EOM, binding, __FILE__, __LINE__ + 1)
          def #{method_name}(*args, &block)
            Chef::DSL::Cheffish.load_cheffish
            self.#{method_name}(*args, &block)
          end
        EOM
      end

      def self.load_cheffish
        # Remove all cheffish methods; they will be added back in by cheffish
        public_instance_methods(false).each do |method_name|
          remove_method(method_name)
        end
        require "cheffish"
      end
    end
  end
end
