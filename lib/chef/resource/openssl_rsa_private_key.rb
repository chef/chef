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
    # A resource for generating rsa private key files.
    # If a valid rsa key file can be opened at the specified location, no new file
    # will be created. If the RSA key file cannot be opened, either because it
    # does not exist or because the password to the RSA key file does not match
    # the password in the recipe, it will be overwritten.
    #
    # @since 14.0
    class OpensslRsaPrivateKey < Chef::Resource
      require "chef/mixin/openssl"
      include Chef::Mixin::OpenSSL

      resource_name :openssl_rsa_private_key
      provides :openssl_rsa_private_key
      provides :openssl_rsa_key # legacy cookbook resource name

      property :path,        String, name_property: true
      property :key_length,  equal_to: [1024, 2048, 4096, 8192], default: 2048
      property :key_pass,    String
      property :key_cipher,  String, default: "des3", equal_to: OpenSSL::Cipher.ciphers
      property :owner,       [String, nil]
      property :group,       [String, nil]
      property :mode,        [Integer, String], default: "0600"
      property :force,       [true, false], default: false

      action :create do
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
