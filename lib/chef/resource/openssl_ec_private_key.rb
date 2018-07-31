#
# Copyright:: Copyright 2018, Chef Software Inc.
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
    class OpensslEcPrivateKey < Chef::Resource
      require "chef/mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      resource_name :openssl_ec_private_key
      provides(:openssl_ec_private_key) { true }

      description "Use the openssl_ec_private_key resource to generate..."
      introduced "14.4"

      property :path, String,
               description: "The path to write the file to it's different than the resource name.",
               name_property: true

      property :key_curve, String,
               equal_to: %w{secp384r1 secp521r1 prime256v1 secp224r1 secp256k1},
               description: "The desired curve of the generated key (if key_type is equal to 'ec'). Run openssl ecparam -list_curves to see available options.",
               default: "prime256v1"

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
        unless new_resource.force || priv_key_file_valid?(new_resource.path, new_resource.key_pass)
          converge_by("Create an EC private key #{new_resource.path}") do
            log "Generating an #{new_resource.key_curve} "\
                "EC key file at #{new_resource.name}, this may take some time"

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
