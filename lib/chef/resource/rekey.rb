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

class Chef
  class Resource
    class Rekey < Chef::Resource
      provides :rekey
      resource_name :rekey

      property :name, String, default: ""
      property :node_name, String, default: lazy { Chef::Config[:node_name] }
      property :client_key, String, default: lazy { Chef::Config[:client_key] }

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
        assert_destination_writable!
        run_context.rest.put("clients/#{node_name}", put_data)
        write_key
      end
    end
  end
end
