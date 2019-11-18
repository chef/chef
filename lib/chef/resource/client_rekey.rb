#
# Copyright:: Copyright (c) 2014-2019, Chef Software Inc.
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

require_relative "../resource"
require_relative "../dist"

class Chef
  class Resource
    class ClientRekey < Chef::Resource
      provides :client_rekey
      resource_name :client_rekey

      description "The client_rekey resource regenerates the key used by #{Chef::Dist::PRODUCT} to communicate with the #{Chef::Dist::SERVER_PRODUCT}."
      introduced "15.6"

      examples <<~DOC
        Rekey the node
        ```ruby
        client_rekey
        ```

        Rekey the node with a custom key path
        ```ruby
        client_rekey 'Rotate client key' do
          client_key '/etc/my_corp_keys/key.pem'
        end
        ````
      DOC

      property :name, String, default: "", skip_docs: true

      property :node_name, String, default: lazy { Chef::Config[:node_name] },
               description: "The name of the node.",
               default_description: "The node_node value defined in your client.rb."

      property :client_key, String, default: lazy { Chef::Config[:client_key] },
               description: "The path to the Chef Infra Client key on disk.",
               default_description: "The client_key value defined in your client.rb."

      action_class do
        def client_key
          new_resource.client_key
        end

        def node_name
          new_resource.node_name
        end

        def assert_destination_writable!
          if (::File.exist?(client_key) && !::File.writable?(client_key)) || !::File.writable?(::File.dirname(client_key))
            raise Chef::Exceptions::CannotWritePrivateKey, "I cannot write your private key to #{client_key} - check permissions?"
          end
        end

        def write_key
          ::File.open(client_key, file_flags, 0600) do |f|
            f.print(private_key)
          end
        rescue IOError => e
          raise Chef::Exceptions::CannotWritePrivateKey, "Error writing private key to #{client_key}: #{e}"
        end

        def put_data
          {
            name: node_name,
            admin: false,
            public_key: generated_public_key,
          }
        end

        def private_key
          generated_private_key.to_pem
        end

        def generated_private_key
          @generated_private_key ||= OpenSSL::PKey::RSA.generate(2048)
        end

        def generated_public_key
          generated_private_key.public_key.to_pem
        end

        def file_flags
          base_flags = ::File::CREAT | ::File::TRUNC | ::File::RDWR
          # Windows doesn't have symlinks, so it doesn't have NOFOLLOW
          base_flags |= ::File::NOFOLLOW if defined?(::File::NOFOLLOW)
          base_flags
        end
      end

      action :rekey do
        description "Rekey the client"

        assert_destination_writable!
        run_context.rest.put("clients/#{node_name}", put_data)
        write_key
      end
    end
  end
end
