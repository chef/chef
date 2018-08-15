#
# Copyright:: Copyright 2009-2018, Chef Software Inc.
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

require "chef/resource"

class Chef
  class Resource
    class OpensslRsaPrivateKey < Chef::Resource
      require "chef/mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      resource_name :openssl_rsa_private_key
      provides(:openssl_rsa_private_key) { true }
      provides(:openssl_rsa_key) { true } # legacy cookbook resource name

      description "Use the openssl_rsa_private_key resource to generate RSA private key files."\
                  " If a valid RSA key file can be opened at the specified location, no new file"\
                  " will be created. If the RSA key file cannot be opened, either because it does"\
                  " not exist or because the password to the RSA key file does not match the"\
                  " password in the recipe, it will be overwritten."
      introduced "14.0"

      property :path, String,
               description: "The path to write the file to it's different than the resource name.",
               name_property: true

      property :key_length, Integer,
               equal_to: [1024, 2048, 4096, 8192],
               validation_message: "key_length (bits) must be 1024, 2048, 4096, or 8192.",
               description: "The desired bit length of the generated key.",
               default: 2048

      property :key_pass, String,
               description: "The desired passphrase for the key."

      property :key_cipher, String,
               equal_to: OpenSSL::Cipher.ciphers,
               validation_message: "key_cipher must be a cipher known to openssl. Run `openssl list-cipher-algorithms` to see available options.",
               description: "The designed cipher to use when generating your key. Run `openssl list-cipher-algorithms` to see available options.",
               default: "des3"

      property :owner, [String, nil],
               description: "The owner of all files created by the resource."

      property :group, [String, nil],
               description: "The group of all files created by the resource."

      property :mode, [Integer, String],
               description: "The permission mode of all files created by the resource.",
               default: "0600"

      property :force, [TrueClass, FalseClass],
               description: "Force creating the key even if the existing key exists.",
               default: false, desired_state: false

      action :create do
        description "Create the RSA private key."

        return if new_resource.force || priv_key_file_valid?(new_resource.path, new_resource.key_pass)

        converge_by("create #{new_resource.key_length} bit RSA key #{new_resource.path}") do
          if new_resource.key_pass
            unencrypted_rsa_key = gen_rsa_priv_key(new_resource.key_length)
            rsa_key_content = encrypt_rsa_key(unencrypted_rsa_key, new_resource.key_pass, new_resource.key_cipher)
          else
            rsa_key_content = gen_rsa_priv_key(new_resource.key_length).to_pem
          end

          declare_resource(:file, new_resource.path) do
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
