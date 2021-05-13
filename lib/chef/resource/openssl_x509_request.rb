#
# License:: Apache License, Version 2.0
# Author:: Julien Huon
# Copyright:: Copyright (c) Chef Software Inc.
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
    class OpensslX509Request < Chef::Resource
      require_relative "../mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      unified_mode true

      provides :openssl_x509_request

      description "Use the **openssl_x509_request** resource to generate PEM-formatted x509 certificates requests. If no existing key is specified, the resource will automatically generate a passwordless key with the certificate."
      introduced "14.4"
      examples <<~DOC
        **Generate new EC key and CSR file**

        ```ruby
        openssl_x509_request '/etc/ssl_files/my_ec_request.csr' do
          common_name 'myecrequest.example.com'
          org 'Test Kitchen Example'
          org_unit 'Kitchens'
          country 'UK'
        end
        ```

        **Generate a new CSR file from an existing EC key**

        ```ruby
        openssl_x509_request '/etc/ssl_files/my_ec_request2.csr' do
          common_name 'myecrequest2.example.com'
          org 'Test Kitchen Example'
          org_unit 'Kitchens'
          country 'UK'
          key_file '/etc/ssl_files/my_ec_request.key'
        end
        ```

        **Generate new RSA key and CSR file**

        ```ruby
        openssl_x509_request '/etc/ssl_files/my_rsa_request.csr' do
          common_name 'myrsarequest.example.com'
          org 'Test Kitchen Example'
          org_unit 'Kitchens'
          country 'UK'
          key_type 'rsa'
        end
        ```
      DOC

      property :path, String, name_property: true,
               description: "An optional property for specifying the path to write the file to if it differs from the resource block's name."

      property :owner, [String, Integer],
        description: "The owner applied to all files created by the resource."

      property :group, [String, Integer],
        description: "The group ownership applied to all files created by the resource."

      property :mode, [Integer, String],
        description: "The permission mode applied to all files created by the resource."

      property :country, String,
        description: "Value for the `C` certificate field."

      property :state, String,
        description: "Value for the `ST` certificate field."

      property :city, String,
        description: "Value for the `L` certificate field."

      property :org, String,
        description: "Value for the `O` certificate field."

      property :org_unit, String,
        description: "Value for the `OU` certificate field."

      property :common_name, String,
        required: true,
        description: "Value for the `CN` certificate field."

      property :email, String,
        description: "Value for the `email` certificate field."

      property :key_file, String,
        description: "The path to a certificate key file on the filesystem. If the `key_file` property is specified, the resource will attempt to source a key from this location. If no key file is found, the resource will generate a new key file at this location. If the `key_file` property is not specified, the resource will generate a key file in the same directory as the generated certificate, with the same name as the generated certificate."

      property :key_pass, String,
        description: "The passphrase for an existing key's passphrase."

      property :key_type, String,
        equal_to: %w{rsa ec}, default: "ec",
        description: "The desired type of the generated key."

      property :key_length, Integer,
        equal_to: [1024, 2048, 4096, 8192], default: 2048,
        description: "The desired bit length of the generated key (if key_type is equal to `rsa`)."

      property :key_curve, String,
        equal_to: %w{secp384r1 secp521r1 prime256v1}, default: "prime256v1",
        description: "The desired curve of the generated key (if key_type is equal to `ec`). Run `openssl ecparam -list_curves` to see available options."

      action :create, description: "Generate a certificate request file." do
        unless ::File.exist? new_resource.path
          converge_by("Create CSR #{@new_resource}") do
            file new_resource.path do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode new_resource.mode unless new_resource.mode.nil?
              content csr.to_pem
              action :create
            end

            file key_file do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode new_resource.mode unless new_resource.mode.nil?
              content key.to_pem
              sensitive true
              action :create_if_missing
            end
          end
        end
      end

      action_class do
        def key_file
          @key_file ||=
            if new_resource.key_file
              new_resource.key_file
            else
              path, file = ::File.split(new_resource.path)
              filename = ::File.basename(file, ::File.extname(file))
              path + "/" + filename + ".key"
            end
        end

        def key
          @key ||= if priv_key_file_valid?(key_file, new_resource.key_pass)
                     OpenSSL::PKey.read ::File.read(key_file), new_resource.key_pass
                   elsif new_resource.key_type == "rsa"
                     gen_rsa_priv_key(new_resource.key_length)
                   else
                     gen_ec_priv_key(new_resource.key_curve)
                   end
        end

        def subject
          OpenSSL::X509::Name.new.tap do |csr_subject|
            csr_subject.add_entry("C", new_resource.country) unless new_resource.country.nil?
            csr_subject.add_entry("ST", new_resource.state) unless new_resource.state.nil?
            csr_subject.add_entry("L", new_resource.city) unless new_resource.city.nil?
            csr_subject.add_entry("O", new_resource.org) unless new_resource.org.nil?
            csr_subject.add_entry("OU", new_resource.org_unit) unless new_resource.org_unit.nil?
            csr_subject.add_entry("CN", new_resource.common_name)
            csr_subject.add_entry("emailAddress", new_resource.email) unless new_resource.email.nil?
          end
        end

        def csr
          gen_x509_request(subject, key)
        end
      end
    end
  end
end
