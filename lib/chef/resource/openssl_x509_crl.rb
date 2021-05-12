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
    class OpensslX509Crl < Chef::Resource
      require_relative "../mixin/openssl_helper"
      include Chef::Mixin::OpenSSLHelper

      unified_mode true

      provides :openssl_x509_crl

      description "Use the **openssl_x509_crl** resource to generate PEM-formatted x509 certificate revocation list (CRL) files."
      introduced "14.4"
      examples <<~DOC
      **Create a certificate revocation file**

      ```ruby
      openssl_x509_crl '/etc/ssl_test/my_ca.crl' do
        ca_cert_file '/etc/ssl_test/my_ca.crt'
        ca_key_file '/etc/ssl_test/my_ca.key'
      end
      ```

      **Create a certificate revocation file for a particular serial**

      ```ruby
      openssl_x509_crl '/etc/ssl_test/my_ca.crl' do
        ca_cert_file '/etc/ssl_test/my_ca.crt'
        ca_key_file '/etc/ssl_test/my_ca.key'
        serial_to_revoke C7BCB6602A2E4251EF4E2827A228CB52BC0CEA2F
      end
      ```
      DOC

      property :path, String,
        description: "An optional property for specifying the path to write the file to if it differs from the resource block's name.",
        name_property: true

      property :serial_to_revoke, [Integer, String],
        description: "Serial of the X509 Certificate to revoke."

      property :revocation_reason, Integer,
        description: "Reason for the revocation.",
        default: 0

      property :expire, Integer,
        description: "Value representing the number of days from now through which the issued CRL will remain valid. The CRL will expire after this period.",
        default: 8

      property :renewal_threshold, Integer,
        description: "Number of days before the expiration. It this threshold is reached, the CRL will be renewed.",
        default: 1

      property :ca_cert_file, String,
        description: "The path to the CA X509 Certificate on the filesystem. If the `ca_cert_file` property is specified, the `ca_key_file` property must also be specified, the CRL will be signed with them.",
        required: true

      property :ca_key_file, String,
        description: "The path to the CA private key on the filesystem. If the `ca_key_file` property is specified, the `ca_cert_file` property must also be specified, the CRL will be signed with them.",
        required: true

      property :ca_key_pass, String,
        description: "The passphrase for CA private key's passphrase."

      property :owner, [String, Integer],
        description: "The owner permission for the CRL file."

      property :group, [String, Integer],
        description: "The group permission for the CRL file."

      property :mode, [Integer, String],
        description: "The permission mode of the CRL file."

      action :create, description: "Create the certificate revocation list (CRL) file." do
        file new_resource.path do
          owner new_resource.owner unless new_resource.owner.nil?
          group new_resource.group unless new_resource.group.nil?
          mode new_resource.mode unless new_resource.mode.nil?
          content crl.to_pem
          action :create
        end
      end

      action_class do
        def crl_info
          # Will contain issuer & expiration
          crl_info = {}

          crl_info["issuer"] = ::OpenSSL::X509::Certificate.new ::File.read(new_resource.ca_cert_file)
          crl_info["validity"] = new_resource.expire

          crl_info
        end

        def revoke_info
          # Will contain Serial to revoke & reason
          revoke_info = {}

          revoke_info["serial"] = new_resource.serial_to_revoke
          revoke_info["reason"] = new_resource.revocation_reason

          revoke_info
        end

        def ca_private_key
          ::OpenSSL::PKey.read ::File.read(new_resource.ca_key_file), new_resource.ca_key_pass
        end

        def crl
          if crl_file_valid?(new_resource.path)
            crl = ::OpenSSL::X509::CRL.new ::File.read(new_resource.path)
          else
            log "Creating a CRL #{new_resource.path} for CA #{new_resource.ca_cert_file}"
            crl = gen_x509_crl(ca_private_key, crl_info)
          end

          if !new_resource.serial_to_revoke.nil? && serial_revoked?(crl, new_resource.serial_to_revoke) == false
            log "Revoking serial #{new_resource.serial_to_revoke} in CRL #{new_resource.path}"
            crl = revoke_x509_crl(revoke_info, crl, ca_private_key, crl_info)
          elsif crl.next_update <= Time.now + 3600 * 24 * new_resource.renewal_threshold
            log "Renewing CRL for CA #{new_resource.ca_cert_file}"
            crl = renew_x509_crl(crl, ca_private_key, crl_info)
          end

          crl
        end
      end

    end
  end
end
