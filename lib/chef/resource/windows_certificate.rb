#
# Author:: Richard Lavey (richard.lavey@calastone.com)
#
# Copyright:: 2015-2017, Calastone Ltd.
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

require_relative "../util/path_helper"
require_relative "../resource"
module Win32
  autoload :Certstore, "win32-certstore" if Chef::Platform.windows?
end
autoload :OpenSSL, "openssl"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class WindowsCertificate < Chef::Resource
      unified_mode true

      provides :windows_certificate

      description "Use the **windows_certificate** resource to install a certificate into the Windows certificate store from a file. The resource grants read-only access to the private key for designated accounts. Due to current limitations in WinRM, installing certificates remotely may not work if the operation requires a user profile. Operations on the local machine store should still work."
      introduced "14.7"
      examples <<~DOC
      **Add PFX cert to local machine personal store and grant accounts read-only access to private key**

      ```ruby
      windows_certificate 'c:/test/mycert.pfx' do
        pfx_password 'password'
        private_key_acl ["acme\\fred", "pc\\jane"]
      end
      ```

      **Add cert to trusted intermediate store**

      ```ruby
      windows_certificate 'c:/test/mycert.cer' do
        store_name 'CA'
      end
      ```

      **Remove all certificates matching the subject**

      ```ruby
      windows_certificate 'me.acme.com' do
        action :delete
      end
      ```
      DOC

      property :source, String,
        description: "The source file (for create and acl_add), thumbprint (for delete and acl_add) or subject (for delete) if it differs from the resource block's name.",
        name_property: true

      property :pfx_password, String,
        description: "The password to access the source if it is a pfx file."

      property :private_key_acl, Array,
        description: "An array of 'domain\account' entries to be granted read-only access to the certificate's private key. Not idempotent."

      property :store_name, String,
        description: "The certificate store to manipulate.",
        default: "MY", equal_to: ["TRUSTEDPUBLISHER", "TrustedPublisher", "CLIENTAUTHISSUER", "REMOTE DESKTOP", "ROOT", "TRUSTEDDEVICES", "WEBHOSTING", "CA", "AUTHROOT", "TRUSTEDPEOPLE", "MY", "SMARTCARDROOT", "TRUST", "DISALLOWED"]

      property :user_store, [TrueClass, FalseClass],
        description: "Use the user store of the local machine store if set to false.",
        default: false

      property :cert_path, String,
        description: "The path to the certificate."

      # lazy used to set default value of sensitive to true if password is set
      property :sensitive, [TrueClass, FalseClass],
        description: "Ensure that sensitive resource data is not logged by the #{ChefUtils::Dist::Infra::CLIENT}.",
        default: lazy { pfx_password ? true : false }, skip_docs: true

      action :create do
        description "Creates or updates a certificate."

        # Extension of the certificate
        ext = ::File.extname(new_resource.source)

        # PFX certificates contains private keys and we import them with some other approach
        import_certificates(fetch_cert_object(ext), (ext == ".pfx"))
      end

      # acl_add is a modify-if-exists operation : not idempotent
      action :acl_add do
        description "Adds read-only entries to a certificate's private key ACL."

        if ::File.exist?(new_resource.source)
          hash = "$cert.GetCertHashString()"
          code_script = cert_script(false)
          guard_script = cert_script(false)
        else
          # make sure we have no spaces in the hash string
          hash = "\"#{new_resource.source.gsub(/\s/, "")}\""
          code_script = ""
          guard_script = ""
        end
        code_script << acl_script(hash)
        guard_script << cert_exists_script(hash)

        powershell_script "setting the acls on #{new_resource.source} in #{cert_location}\\#{new_resource.store_name}" do
          convert_boolean_return true
          code code_script
          only_if guard_script
          sensitive if new_resource.sensitive
        end
      end

      action :delete do
        description "Deletes a certificate."
        cert_obj = fetch_cert
        if cert_obj
          converge_by("Deleting certificate #{new_resource.source} from Store #{new_resource.store_name}") do
            delete_cert
          end
        else
          Chef::Log.debug("Certificate not found")
        end
      end

      action :fetch do
        description "Fetches a certificate."

        cert_obj = fetch_cert
        if cert_obj
          show_or_store_cert(cert_obj)
        else
          Chef::Log.debug("Certificate not found")
        end
      end

      action :verify do
        description ""

        out = verify_cert
        if !!out == out
          out = out ? "Certificate is valid" : "Certificate not valid"
        end
        Chef::Log.info(out.to_s)
      end

      action_class do
        def add_cert(cert_obj)
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.add(cert_obj)
        end

        def add_pfx_cert
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.add_pfx(new_resource.source, new_resource.pfx_password)
        end

        def delete_cert
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.delete(new_resource.source)
        end

        def fetch_cert
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.get(new_resource.source)
        end

        # Checks whether a certificate with the given thumbprint
        # is already present and valid in certificate store
        # If the certificate is not present, verify_cert returns a String: "Certificate not found"
        # But if it is present but expired, it returns a Boolean: false
        # Otherwise, it returns a Boolean: true
        def verify_cert(thumbprint = new_resource.source)
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.valid?(thumbprint)
        end

        def show_or_store_cert(cert_obj)
          if new_resource.cert_path
            export_cert(cert_obj, new_resource.cert_path)
            if ::File.size(new_resource.cert_path) > 0
              Chef::Log.info("Certificate export in #{new_resource.cert_path}")
            else
              ::File.delete(new_resource.cert_path)
            end
          else
            Chef::Log.info(cert_obj.display)
          end
        end

        def export_cert(cert_obj, cert_path)
          out_file = ::File.new(cert_path, "w+")
          case ::File.extname(cert_path)
          when ".pem"
            out_file.puts(cert_obj.to_pem)
          when ".der"
            out_file.puts(cert_obj.to_der)
          when ".cer"
            cert_out = shell_out("openssl x509 -text -inform DER -in #{cert_obj.to_pem} -outform CER").stdout
            out_file.puts(cert_out)
          when ".crt"
            cert_out = shell_out("openssl x509 -text -inform DER -in #{cert_obj.to_pem} -outform CRT").stdout
            out_file.puts(cert_out)
          when ".pfx"
            cert_out = shell_out("openssl pkcs12 -export -nokeys -in #{cert_obj.to_pem} -outform PFX").stdout
            out_file.puts(cert_out)
          when ".p7b"
            cert_out = shell_out("openssl pkcs7 -export -nokeys -in #{cert_obj.to_pem} -outform P7B").stdout
            out_file.puts(cert_out)
          else
            Chef::Log.info("Supported certificate format .pem, .der, .cer, .crt, .pfx and .p7b")
          end
          out_file.close
        end

        def cert_location
          @location ||= new_resource.user_store ? "CurrentUser" : "LocalMachine"
        end

        def cert_script(persist)
          cert_script = "$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2"
          file = Chef::Util::PathHelper.cleanpath(new_resource.source)
          cert_script << " \"#{file}\""
          if ::File.extname(file.downcase) == ".pfx"
            cert_script << ", \"#{new_resource.pfx_password}\""
            if persist && new_resource.user_store
              cert_script << ", ([System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)"
            elsif persist
              cert_script << ", ([System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeyset)"
            end
          end
          cert_script << "\n"
        end

        def cert_exists_script(hash)
          <<-EOH
  $hash = #{hash}
  Test-Path "Cert:\\#{cert_location}\\#{new_resource.store_name}\\$hash"
          EOH
        end

        def within_store_script
          inner_script = yield "$store"
          <<-EOH
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "#{new_resource.store_name}", ([System.Security.Cryptography.X509Certificates.StoreLocation]::#{cert_location})
  $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
  #{inner_script}
  $store.Close()
          EOH
        end

        def acl_script(hash)
          return "" if new_resource.private_key_acl.nil? || new_resource.private_key_acl.empty?

          # this PS came from http://blogs.technet.com/b/operationsguy/archive/2010/11/29/provide-access-to-private-keys-commandline-vs-powershell.aspx
          # and from https://msdn.microsoft.com/en-us/library/windows/desktop/bb204778(v=vs.85).aspx
          set_acl_script = <<-EOH
  $hash = #{hash}
  $storeCert = Get-ChildItem "cert:\\#{cert_location}\\#{new_resource.store_name}\\$hash"
  if ($storeCert -eq $null) { throw 'no key exists.' }
  $keyname = $storeCert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
  if ($keyname -eq $null) { throw 'no private key exists.' }
  if ($storeCert.PrivateKey.CspKeyContainerInfo.MachineKeyStore)
  {
    $fullpath = "$Env:ProgramData\\Microsoft\\Crypto\\RSA\\MachineKeys\\$keyname"
  }
  else
  {
    $currentUser = New-Object System.Security.Principal.NTAccount($Env:UserDomain, $Env:UserName)
    $userSID = $currentUser.Translate([System.Security.Principal.SecurityIdentifier]).Value
    $fullpath = "$Env:ProgramData\\Microsoft\\Crypto\\RSA\\$userSID\\$keyname"
  }
          EOH
          new_resource.private_key_acl.each do |name|
            set_acl_script << "$uname='#{name}'; icacls $fullpath /grant $uname`:RX\n"
          end
          set_acl_script
        end

        # Method returns an OpenSSL::X509::Certificate object. Might also return multiple certificates if present in certificate path
        #
        # Based on its extension, the certificate contents are used to initialize
        # PKCS12 (PFX), PKCS7 (P7B) objects which contains OpenSSL::X509::Certificate.
        #
        # @note Other then PEM, all the certificates are usually in binary format, and hence
        #       their contents are loaded by using File.binread
        #
        # @param ext [String] Extension of the certificate
        #
        # @return [OpenSSL::X509::Certificate] Object containing certificate's attributes
        #
        # @raise [OpenSSL::PKCS12::PKCS12Error] When incorrect password is provided for PFX certificate
        #
        def fetch_cert_object(ext)
          contents = if binary_cert?
                       ::File.binread(new_resource.source)
                     else
                       ::File.read(new_resource.source)
                     end

          case ext
          when ".pfx"
            pfx = OpenSSL::PKCS12.new(contents, new_resource.pfx_password)
            if pfx.ca_certs.nil?
              pfx.certificate
            else
              [pfx.certificate] + pfx.ca_certs
            end
          when ".p7b"
            OpenSSL::PKCS7.new(contents).certificates
          else
            OpenSSL::X509::Certificate.new(contents)
          end
        end

        # @return [Boolean] Whether the certificate file is binary encoded or not
        #
        def binary_cert?
          shell_out!("file -b --mime-encoding #{new_resource.source}").stdout.strip == "binary"
        end

        # Imports the certificate object into cert store
        #
        # @param cert_objs [OpenSSL::X509::Certificate] Object containing certificate's attributes
        #
        # @param is_pfx [Boolean] true if we want to import a PFX certificate
        #
        def import_certificates(cert_objs, is_pfx)
          [cert_objs].flatten.each do |cert_obj|
            thumbprint = OpenSSL::Digest.new("SHA1", cert_obj.to_der).to_s # Fetch its thumbprint
            # Need to check if return value is Boolean:true
            # If not then the given certificate should be added in certstore
            if verify_cert(thumbprint) == true
              Chef::Log.debug("Certificate is already present")
            else
              converge_by("Adding certificate #{new_resource.source} into Store #{new_resource.store_name}") do
                if is_pfx
                  add_pfx_cert
                else
                  add_cert(cert_obj)
                end
              end
            end
          end
        end
      end
    end
  end
end
