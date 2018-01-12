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
    # A resource for generating rsa public key files given a rsa private key.
    #
    # @since 14.0
    class OpensslRsaPublicKey < Chef::Resource
      require "chef/mixin/openssl"
      include Chef::Mixin::OpenSSL

      resource_name :openssl_rsa_public_key

      property :path,                String, name_property: true
      property :private_key_path,    String
      property :private_key_content, String
      property :private_key_pass,    String
      property :owner,               [String, nil]
      property :group,               [String, nil]
      property :mode,                [Integer, String], default: "0640"

      action :create do
        raise ArgumentError, "You cannot specify both 'private_key_path' and 'private_key_content' properties at the same time." if new_resource.private_key_path && new_resource.private_key_content
        raise ArgumentError, "You must specify the private key with either 'private_key_path' or 'private_key_content' properties." unless new_resource.private_key_path || new_resource.private_key_content
        raise "#{new_resource.private_key_path} not a valid private RSA key or password is invalid" unless priv_key_file_valid?((new_resource.private_key_path || new_resource.private_key_content), new_resource.private_key_pass)

        rsa_key_content = gen_rsa_pub_key((new_resource.private_key_path || new_resource.private_key_content), new_resource.private_key_pass)

        declare_resource(:file, new_resource.path) do
          action :create
          owner new_resource.owner unless new_resource.owner.nil?
          group new_resource.group unless new_resource.group.nil?
          mode new_resource.mode
          content rsa_key_content
        end
      end
    end
  end
end
