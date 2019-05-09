#
# Copyright:: Copyright 2018, Chef Software Inc.
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
    class OpensslEcPublicKey < Chef::Resource
      require_relative "../mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      resource_name :openssl_ec_public_key

      description "Use the openssl_ec_public_key resource to generate elliptic curve (EC) public key files from a given EC private key."
      introduced "14.4"

      property :path, String,
               description: "An optional property for specifying the path to write the file to if it differs from the resource block's name.",
               name_property: true

      property :private_key_path, String,
               description: "The path to the private key file."

      property :private_key_content, String,
               description: "The content of the private key including new lines. This property is used in place of private_key_path in instances where you want to avoid having to first write the private key to disk"

      property :private_key_pass, String,
               description: "The passphrase of the provided private key."

      property :owner, [String, Integer],
               description: "The owner applied to all files created by the resource."

      property :group, [String, Integer],
               description: "The group ownership applied to all files created by the resource."

      property :mode, [Integer, String],
               description: "The permission mode applied to all files created by the resource.",
               default: "0640"

      action :create do
        description "Generate the ec public key from a private key"

        raise ArgumentError, "You cannot specify both 'private_key_path' and 'private_key_content' properties at the same time." if new_resource.private_key_path && new_resource.private_key_content
        raise ArgumentError, "You must specify the private key with either 'private_key_path' or 'private_key_content' properties." unless new_resource.private_key_path || new_resource.private_key_content
        raise "#{new_resource.private_key_path} not a valid private EC key or password is invalid" unless priv_key_file_valid?((new_resource.private_key_path || new_resource.private_key_content), new_resource.private_key_pass)

        ec_key_content = gen_ec_pub_key((new_resource.private_key_path || new_resource.private_key_content), new_resource.private_key_pass)

        file new_resource.path do
          action :create
          owner new_resource.owner unless new_resource.owner.nil?
          group new_resource.group unless new_resource.group.nil?
          mode new_resource.mode
          content ec_key_content
        end
      end
    end
  end
end
