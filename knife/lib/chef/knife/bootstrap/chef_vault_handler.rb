#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
  class Knife
    class Bootstrap < Knife
      class ChefVaultHandler

        # @return [Hash] knife merged config, typically @config
        attr_accessor :config

        # @return [Chef::Knife::UI] ui object for output
        attr_accessor :ui

        # @return [Chef::ApiClient] vault client
        attr_reader :client

        # @param config [Hash] knife merged config, typically @config
        # @param ui [Chef::Knife::UI] ui object for output
        def initialize(config: {}, knife_config: nil, ui: nil)
          @config = config
          unless knife_config.nil?
            @config = knife_config
            Chef.deprecated(:knife_bootstrap_apis, "The knife_config option to the Bootstrap::ClientBuilder object is deprecated and has been renamed to just 'config'")
          end
          @ui = ui
        end

        # Updates the chef vault items for the newly created client.
        #
        # @param client [Chef::ApiClient] vault client
        def run(client)
          return unless doing_chef_vault?

          sanity_check

          @client = client

          update_bootstrap_vault_json!
        end

        # Iterate through all the vault items to update.  Items may be either a String
        # or an Array of Strings:
        #
        # {
        #   "vault1":  "item",
        #   "vault2":  [ "item1", "item2", "item2" ]
        # }
        #
        def update_bootstrap_vault_json!
          vault_json.each do |vault, items|
            [ items ].flatten.each do |item|
              update_vault(vault, item)
            end
          end
        end

        # @return [Boolean] if we've got chef vault options to act on or not
        def doing_chef_vault?
          !!(bootstrap_vault_json || bootstrap_vault_file || bootstrap_vault_item)
        end

        private

        # warn if the user has given mutual conflicting options
        def sanity_check
          if bootstrap_vault_item && (bootstrap_vault_json || bootstrap_vault_file)
            ui.warn "--vault-item given with --vault-list or --vault-file, ignoring the latter"
          end

          if bootstrap_vault_json && bootstrap_vault_file
            ui.warn "--vault-list given with --vault-file, ignoring the latter"
          end
        end

        # @return [String] string with serialized JSON representing the chef vault items
        def bootstrap_vault_json
          config[:bootstrap_vault_json]
        end

        # @return [String] JSON text in a file representing the chef vault items
        def bootstrap_vault_file
          config[:bootstrap_vault_file]
        end

        # @return [Hash] Ruby object representing the chef vault items to create
        def bootstrap_vault_item
          config[:bootstrap_vault_item]
        end

        # Helper to return a ruby object representing all the data bags and items
        # to update via chef-vault.
        #
        # @return [Hash] deserialized ruby hash with all the vault items
        def vault_json
          @vault_json ||=
            if bootstrap_vault_item
              bootstrap_vault_item
            else
              json = bootstrap_vault_json || File.read(bootstrap_vault_file)
              Chef::JSONCompat.from_json(json)
            end
        end

        # Update an individual vault item and save it
        #
        # @param vault [String] name of the chef-vault encrypted data bag
        # @param item [String] name of the chef-vault encrypted item
        def update_vault(vault, item)
          require_chef_vault!
          bootstrap_vault_item = load_chef_bootstrap_vault_item(vault, item)
          bootstrap_vault_item.clients(client)
          bootstrap_vault_item.save
        end

        # Hook to stub out ChefVault
        #
        # @param vault [String] name of the chef-vault encrypted data bag
        # @param item [String] name of the chef-vault encrypted item
        # @return [ChefVault::Item] ChefVault::Item object
        def load_chef_bootstrap_vault_item(vault, item)
          ChefVault::Item.load(vault, item)
        end

        public :load_chef_bootstrap_vault_item # for stubbing

        # Helper to very lazily require the chef-vault gem
        def require_chef_vault!
          @require_chef_vault ||=
            begin
              error_message = "Knife bootstrap requires version 2.6.0 or higher of the chef-vault gem to configure vault items"
              require "chef-vault"
              if Gem::Version.new(ChefVault::VERSION) < Gem::Version.new("2.6.0")
                raise error_message
              end

              true
            rescue LoadError
              raise error_message
            end
        end

      end
    end
  end
end
