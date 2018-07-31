#
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
    class OpensslX509Certificate < Chef::Resource
      require "chef/mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      resource_name :openssl_x509_certificate
      provides(:openssl_x509) { true }
      provides(:openssl_x509_certificate) { true }

      property :path, String, name_property: true

      property :owner, [String, nil],
               description: "The owner of all files created by the resource."

      property :group, [String, nil],
               description: "The group of all files created by the resource."

      property :expire,           Integer, default: 365
      property :mode,             [Integer, String], default: "0644"
      property :country,          String
      property :state,            String
      property :city,             String
      property :org,              String
      property :org_unit,         String
      property :common_name,      String
      property :email,            String
      property :extensions,       Hash, default: {}
      property :subject_alt_name, Array, default: []
      property :key_file,         String
      property :key_pass,         String
      property :key_type,         equal_to: %w{rsa ec}, default: "rsa"
      property :key_length,       equal_to: [1024, 2048, 4096, 8192], default: 2048
      property :key_curve,        equal_to: %w{secp384r1 secp521r1 prime256v1}, default: "prime256v1"
      property :csr_file,         String
      property :ca_cert_file,     String
      property :ca_key_file,      String
      property :ca_key_pass,      String

      action :create do
        unless ::File.exist? new_resource.path
          converge_by("Create #{@new_resource}") do
            file new_resource.path do
              action :create_if_missing
              mode new_resource.mode
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              sensitive true
              content cert.to_pem
            end

            if new_resource.csr_file.nil?
              file new_resource.key_file do
                action :create_if_missing
                mode new_resource.mode
                owner new_resource.owner unless new_resource.owner.nil?
                group new_resource.group unless new_resource.group.nil?
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
          subject = OpenSSL::X509::Name.new()
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
