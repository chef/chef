#
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

require_relative "../resource"

class Chef
  class Resource
    class OpensslDhparam < Chef::Resource
      require_relative "../mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      unified_mode true

      provides(:openssl_dhparam) { true }

      description "Use the **openssl_dhparam** resource to generate `dhparam.pem` files. If a valid `dhparam.pem` file is found at the specified location, no new file will be created. If a file is found at the specified location but it is not a valid `dhparam.pem` file, it will be overwritten."
      introduced "14.0"
      examples <<~DOC
        **Create a dhparam file**

        ```ruby
        openssl_dhparam '/etc/httpd/ssl/dhparam.pem'
        ```

        **Create a dhparam file with a specific key length**

        ```ruby
        openssl_dhparam '/etc/httpd/ssl/dhparam.pem' do
          key_length 4096
        end
        ```

        **Create a dhparam file with specific user/group ownership**

        ```ruby
        openssl_dhparam '/etc/httpd/ssl/dhparam.pem' do
          owner 'www-data'
          group 'www-data'
        end
        ```

        **Manually specify the dhparam file path**

        ```ruby
        openssl_dhparam 'httpd_dhparam' do
          path '/etc/httpd/ssl/dhparam.pem'
        end
        ```
      DOC

      property :path, String,
        description: "An optional property for specifying the path to write the file to if it differs from the resource block's name.",
        name_property: true

      property :key_length, Integer,
        equal_to: [1024, 2048, 4096, 8192],
        validation_message: "key_length must be 1024, 2048, 4096, or 8192.",
        description: "The desired bit length of the generated key.",
        default: 2048

      property :generator, Integer,
        equal_to: [2, 5],
        validation_message: "generator must be either 2 or 5.",
        description: "The desired Diffie-Hellmann generator.",
        default: 2

      property :owner, [String, Integer],
        description: "The owner applied to all files created by the resource."

      property :group, [String, Integer],
        description: "The group ownership applied to all files created by the resource."

      property :mode, [Integer, String],
        description: "The permission mode applied to all files created by the resource.",
        default: "0640"

      action :create, description: "Create the `dhparam.pem` file." do
        dhparam_content = nil
        unless dhparam_pem_valid?(new_resource.path)
          dhparam_content = gen_dhparam(new_resource.key_length, new_resource.generator).to_pem
          Chef::Log.debug("Valid dhparam content not found at #{new_resource.path}, creating new")
        end

        file new_resource.path do
          action :create
          owner new_resource.owner
          group new_resource.group
          mode new_resource.mode
          sensitive true
          content dhparam_content
        end
      end
    end
  end
end
