#
# Copyright:: Copyright (c) Chef Software Inc.
# Author:: Julien Huon
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
    class OpensslEcPrivateKey < Chef::Resource
      require_relative "../mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      unified_mode true

      provides :openssl_ec_private_key

      description "Use the **openssl_ec_private_key** resource to generate an elliptic curve (EC) private key file. If a valid EC key file can be opened at the specified location, no new file will be created. If the EC key file cannot be opened, either because it does not exist or because the password to the EC key file does not match the password in the recipe, then it will be overwritten."
      introduced "14.4"
      examples <<~DOC
        **Generate a new ec privatekey with prime256v1 key curve and default des3 cipher**

        ```ruby
        openssl_ec_private_key '/etc/ssl_files/eckey_prime256v1_des3.pem' do
          key_curve 'prime256v1'
          key_pass 'something'
          action :create
        end
        ```

        **Generate a new ec private key with prime256v1 key curve and aes-128-cbc cipher**

        ```ruby
        openssl_ec_private_key '/etc/ssl_files/eckey_prime256v1_des3.pem' do
          key_curve 'prime256v1'
          key_cipher 'aes-128-cbc'
          key_pass 'something'
          action :create
        end
        ```
      DOC

      property :path, String,
        description: "An optional property for specifying the path to write the file to if it differs from the resource block's name.",
        name_property: true

      property :key_curve, String,
        equal_to: %w{secp384r1 secp521r1 prime256v1 secp224r1 secp256k1},
        description: "The desired curve of the generated key (if key_type is equal to 'ec'). Run openssl ecparam -list_curves to see available options.",
        default: "prime256v1"

      property :key_pass, String,
        description: "The desired passphrase for the key."

      property :key_cipher, String,
        description: "The designed cipher to use when generating your key. Run `openssl list-cipher-algorithms` to see available options.",
        default: lazy { "des3" },
        default_description: "des3",
        callbacks: {
          "key_cipher must be a cipher known to openssl. Run `openssl list-cipher-algorithms` to see available options." =>
            proc { |v| OpenSSL::Cipher.ciphers.include?(v) },
        }

      property :owner, [String, Integer],
        description: "The owner applied to all files created by the resource."

      property :group, [String, Integer],
        description: "The group ownership applied to all files created by the resource."

      property :mode, [Integer, String],
        description: "The permission mode applied to all files created by the resource.",
        default: "0600"

      property :force, [TrueClass, FalseClass],
        description: "Force creation of the key even if the same key already exists on the node.",
        default: false, desired_state: false

      action :create, description: "Generate the EC private key file." do
        unless new_resource.force || priv_key_file_valid?(new_resource.path, new_resource.key_pass)
          converge_by("Create an EC private key #{new_resource.path}") do
            log "Generating an #{new_resource.key_curve} "\
                "EC key file at #{new_resource.path}, this may take some time"

            if new_resource.key_pass
              unencrypted_ec_key = gen_ec_priv_key(new_resource.key_curve)
              ec_key_content = encrypt_ec_key(unencrypted_ec_key, new_resource.key_pass, new_resource.key_cipher)
            else
              ec_key_content = gen_ec_priv_key(new_resource.key_curve).to_pem
            end

            file new_resource.path do
              action :create
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode new_resource.mode
              sensitive true
              content ec_key_content
            end
          end
        end
      end
    end
  end
end
