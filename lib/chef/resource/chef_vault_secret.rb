#
# Author:: Joshua Timberman <joshua@chef.io>
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"
autoload :ChefVault, "chef-vault"

class Chef
  class Resource
    class ChefVaultSecret < Chef::Resource
      unified_mode true

      provides :chef_vault_secret

      introduced "16.0"
      description "Use the **chef_vault_secret** resource to store secrets in Chef Vault items. Where possible and relevant, this resource attempts to map behavior and functionality to the knife vault sub-commands."
      examples <<~DOC
        **To create a 'foo' item in an existing 'bar' data bag**:

        ```ruby
        chef_vault_secret 'foo' do
          data_bag 'bar'
          raw_data({'auth' => 'baz'})
          admins 'jtimberman'
          search '*:*'
        end
        ```

        **To allow multiple admins access to an item**:

        ```ruby
        chef_vault_secret 'root-password' do
          admins 'jtimberman,paulmooring'
          data_bag 'secrets'
          raw_data({'auth' => 'DoNotUseThisPasswordForRoot'})
          search '*:*'
        end
        ```
      DOC

      property :id, String, name_property: true,
        description: "The name of the data bag item if it differs from the name of the resource block"

      property :data_bag, String, required: true, desired_state: false,
        description: "The data bag that contains the item."

      property :admins, [String, Array], required: true, desired_state: false,
        description: "A list of admin users who should have access to the item. Corresponds to the 'admin' option when using the chef-vault knife plugin. Can be specified as a comma separated string or an array."

      property :clients, [String, Array], desired_state: false,
        description: "A search query for the nodes' API clients that should have access to the item."

      property :search, String, default: "*:*", desired_state: false,
        description: "Search query that would match the same used for the clients, gets stored as a field in the item."

      property :raw_data, [Hash, Mash], default: {},
        description: "The raw data, as a Ruby Hash, that will be stored in the item."

      property :environment, [String, NilClass], desired_state: false,
        description: "The Chef environment of the data if storing per environment values."

      load_current_value do

        item = ChefVault::Item.load(data_bag, id)
        raw_data item.raw_data
        clients item.get_clients
        admins item.get_admins
        search item.search
      rescue ChefVault::Exceptions::SecretDecryption
        current_value_does_not_exist!
      rescue ChefVault::Exceptions::KeysNotFound
        current_value_does_not_exist!
      rescue Net::HTTPClientException => e
        current_value_does_not_exist! if e.response_code == "404"

      end

      action :create, description: "Creates the item, or updates it if it already exists." do

        converge_if_changed do
          item = ChefVault::Item.new(new_resource.data_bag, new_resource.id)

          Chef::Log.debug("#{new_resource.id} environment: '#{new_resource.environment}'")
          item.raw_data = if new_resource.environment.nil?
                            new_resource.raw_data.merge("id" => new_resource.id)
                          else
                            { "id" => new_resource.id, new_resource.environment => new_resource.raw_data }
                          end

          Chef::Log.debug("#{new_resource.id} search query: '#{new_resource.search}'")
          item.search(new_resource.search)
          Chef::Log.debug("#{new_resource.id} clients: '#{new_resource.clients}'")
          item.clients([new_resource.clients].flatten.join(",")) unless new_resource.clients.nil?
          Chef::Log.debug("#{new_resource.id} admins (users): '#{new_resource.admins}'")
          item.admins([new_resource.admins].flatten.join(","))
          item.save
        end
      end

      action :create_if_missing, description: "Calls the create action unless it exists." do
        action_create if current_resource.nil?
      end

      action :delete, description: "Deletes the item and the item's keys ('id'_keys)." do
        chef_data_bag_item new_resource.id do
          data_bag new_resource.data_bag
          action :delete
        end

        chef_data_bag_item [new_resource.id, "keys"].join("_") do
          data_bag new_resource.data_bag
          action :delete
        end
      end
    end
  end
end
