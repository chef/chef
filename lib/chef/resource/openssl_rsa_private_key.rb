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
    class OpensslRsaPrivateKey < Chef::Resource
      require_relative "../mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      unified_mode true

      provides(:openssl_rsa_private_key) { true }
      provides(:openssl_rsa_key) { true } # legacy cookbook resource name

      description "Use the **openssl_rsa_private_key** resource to generate RSA private key files. If a valid RSA key file can be opened at the specified location, no new file will be created. If the RSA key file cannot be opened, either because it does not exist or because the password to the RSA key file does not match the password in the recipe, it will be overwritten."
      introduced "14.0"
      examples <<~DOC
        Generate new 2048bit key with the default des3 cipher

        ```ruby
        openssl_rsa_private_key '/etc/ssl_files/rsakey_des3.pem' do
          key_length 2048
          action :create
        end
        ```

        Generate new 1024bit key with the aes-128-cbc cipher

        ```ruby
        openssl_rsa_private_key '/etc/ssl_files/rsakey_aes128cbc.pem' do
          key_length 1024
          key_cipher 'aes-128-cbc'
          action :create
        end
        ```
      DOC

      property :path, String,
        description: "An optional property for specifying the path to write the file to if it differs from the resource block's name.",
        name_property: true

      property :key_length, Integer,
        equal_to: [1024, 2048, 4096, 8192],
        validation_message: "key_length (bits) must be 1024, 2048, 4096, or 8192!",
        description: "The desired bit length of the generated key.",
        default: 2048

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

      action :create, description: "Create the RSA private key file." do
        return if new_resource.force || priv_key_file_valid?(new_resource.path, new_resource.key_pass)

        converge_by("create #{new_resource.key_length} bit RSA key #{new_resource.path}") do
          if new_resource.key_pass
            unencrypted_rsa_key = gen_rsa_priv_key(new_resource.key_length)
            rsa_key_content = encrypt_rsa_key(unencrypted_rsa_key, new_resource.key_pass, new_resource.key_cipher)
          else
            rsa_key_content = gen_rsa_priv_key(new_resource.key_length).to_pem
          end

          file new_resource.path do
            action :create
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode new_resource.mode
            sensitive true
            content rsa_key_content
          end
        end
      end
    end
  end
end
