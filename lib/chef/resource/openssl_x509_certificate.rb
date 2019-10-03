#
# License:: Apache License, Version 2.0
# Author:: Julien Huon
# Copyright:: Copyright 2018, Chef Software Inc.
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
    class OpensslX509Certificate < Chef::Resource
      require_relative "../mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      resource_name :openssl_x509_certificate
      provides(:openssl_x509) { true } # legacy cookbook name.

      description "Use the openssl_x509_certificate resource to generate signed or self-signed, PEM-formatted x509 certificates. If no existing key is specified, the resource will automatically generate a passwordless key with the certificate. If a CA private key and certificate are provided, the certificate will be signed with them. Note: This resource was renamed from openssl_x509 to openssl_x509_certificate. The legacy name will continue to function, but cookbook code should be updated for the new resource name."
      introduced "14.4"

      property :path, String,
        description: "An optional property for specifying the path to write the file to if it differs from the resource block's name.",
        name_property: true

      property :owner, [String, Integer],
        description: "The owner applied to all files created by the resource."

      property :group, [String, Integer],
        description: "The group ownership applied to all files created by the resource."

      property :expire, Integer,
        description: "Value representing the number of days from now through which the issued certificate cert will remain valid. The certificate will expire after this period.",
        default: 365

      property :mode, [Integer, String],
        description: "The permission mode applied to all files created by the resource."

      property :country, String,
        description: "Value for the C certificate field."

      property :state, String,
        description: "Value for the ST certificate field."

      property :city, String,
        description: "Value for the L certificate field."

      property :org, String,
        description: "Value for the O certificate field."

      property :org_unit, String,
        description: "Value for the OU certificate field."

      property :common_name, String,
        description: "Value for the CN certificate field."

      property :email, String,
        description: "Value for the email certificate field."

      property :extensions, Hash,
        description: "Hash of X509 Extensions entries, in format { 'keyUsage' => { 'values' => %w( keyEncipherment digitalSignature), 'critical' => true } }.",
        default: lazy { {} }

      property :subject_alt_name, Array,
        description: "Array of Subject Alternative Name entries, in format DNS:example.com or IP:1.2.3.4.",
        default: lazy { [] }

      property :key_file, String,
        description: "The path to a certificate key file on the filesystem. If the key_file property is specified, the resource will attempt to source a key from this location. If no key file is found, the resource will generate a new key file at this location. If the key_file property is not specified, the resource will generate a key file in the same directory as the generated certificate, with the same name as the generated certificate."

      property :key_pass, String,
        description: "The passphrase for an existing key's passphrase."

      property :key_type, String,
        equal_to: %w{rsa ec},
        description: "The desired type of the generated key (rsa or ec).",
        default: "rsa"

      property :key_length, Integer,
        equal_to: [1024, 2048, 4096, 8192],
        description: "The desired bit length of the generated key (if key_type is equal to 'rsa').",
        default: 2048

      property :key_curve, String,
        description: "The desired curve of the generated key (if key_type is equal to 'ec'). Run openssl ecparam -list_curves to see available options.",
        equal_to: %w{secp384r1 secp521r1 prime256v1},
        default: "prime256v1"

      property :csr_file, String,
        description: "The path to a X509 Certificate Request (CSR) on the filesystem. If the csr_file property is specified, the resource will attempt to source a CSR from this location. If no CSR file is found, the resource will generate a Self-Signed Certificate and the certificate fields must be specified (common_name at last)."

      property :ca_cert_file, String,
        description: "The path to the CA X509 Certificate on the filesystem. If the ca_cert_file property is specified, the ca_key_file property must also be specified, the certificate will be signed with them."

      property :ca_key_file, String,
        description: "The path to the CA private key on the filesystem. If the ca_key_file property is specified, the 'ca_cert_file' property must also be specified, the certificate will be signed with them."

      property :ca_key_pass, String,
        description: "The passphrase for CA private key's passphrase."

      action :create do
        description "Generate a certificate"

        unless ::File.exist? new_resource.path
          converge_by("Create #{@new_resource}") do
            file new_resource.path do
              action :create_if_missing
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode new_resource.mode unless new_resource.mode.nil?
              sensitive true
              content cert.to_pem
            end

            if new_resource.csr_file.nil?
              file new_resource.key_file do
                action :create_if_missing
                owner new_resource.owner unless new_resource.owner.nil?
                group new_resource.group unless new_resource.group.nil?
                mode new_resource.mode unless new_resource.mode.nil?
                sensitive true
                content key.to_pem
              end
            end
          end
        end
      end

      action_class do
        def generate_key_file
          unless new_resource.key_file
            path, file = ::File.split(new_resource.path)
            filename = ::File.basename(file, ::File.extname(file))
            new_resource.key_file path + "/" + filename + ".key"
          end
          new_resource.key_file
        end

        def key
          @key ||= if priv_key_file_valid?(generate_key_file, new_resource.key_pass)
                     OpenSSL::PKey.read ::File.read(generate_key_file), new_resource.key_pass
                   elsif new_resource.key_type == "rsa"
                     gen_rsa_priv_key(new_resource.key_length)
                   else
                     gen_ec_priv_key(new_resource.key_curve)
                   end
          @key
        end

        def request
          request = if new_resource.csr_file.nil?
                      gen_x509_request(subject, key)
                    else
                      OpenSSL::X509::Request.new ::File.read(new_resource.csr_file)
                    end
          request
        end

        def subject
          subject = OpenSSL::X509::Name.new
          subject.add_entry("C", new_resource.country) unless new_resource.country.nil?
          subject.add_entry("ST", new_resource.state) unless new_resource.state.nil?
          subject.add_entry("L", new_resource.city) unless new_resource.city.nil?
          subject.add_entry("O", new_resource.org) unless new_resource.org.nil?
          subject.add_entry("OU", new_resource.org_unit) unless new_resource.org_unit.nil?
          subject.add_entry("CN", new_resource.common_name)
          subject.add_entry("emailAddress", new_resource.email) unless new_resource.email.nil?
          subject
        end

        def ca_private_key
          ca_private_key = if new_resource.csr_file.nil?
                             key
                           else
                             OpenSSL::PKey.read ::File.read(new_resource.ca_key_file), new_resource.ca_key_pass
                           end
          ca_private_key
        end

        def ca_info
          # Will contain issuer (if any) & expiration
          ca_info = {}

          unless new_resource.ca_cert_file.nil?
            ca_info["issuer"] = OpenSSL::X509::Certificate.new ::File.read(new_resource.ca_cert_file)
          end
          ca_info["validity"] = new_resource.expire

          ca_info
        end

        def extensions
          extensions = gen_x509_extensions(new_resource.extensions)

          unless new_resource.subject_alt_name.empty?
            extensions += gen_x509_extensions("subjectAltName" => { "values" => new_resource.subject_alt_name, "critical" => false })
          end

          extensions
        end

        def cert
          cert = gen_x509_cert(request, extensions, ca_info, ca_private_key)
          cert
        end
      end
    end
  end
end
