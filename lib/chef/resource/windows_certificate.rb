#
# Author:: Richard Lavey (richard.lavey@calastone.com)
#
# Copyright:: 2015-2017, Calastone Ltd.
# Copyright:: 2018, Chef Software, Inc.
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
require "win32-certstore" if Chef::Platform.windows?
require "openssl"

class Chef
  class Resource
    class WindowsCertificate < Chef::Resource
      preview_resource true
      resource_name :windows_certificate

      description "The the windows_certificate resource to install a certificate into the Windows certificate store from a file. The resource grants read-only access to the private key for designated accounts. Due to current limitations in WinRM, installing certificated remotely may not work if the operation requires a user profile. Operations on the local machine store should still work."
      introduced "14.6"

      property :source, String,
               description: "The source file (for create and acl_add), thumbprint (for delete and acl_add) or subject (for delete).",
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
               description: ""

      action :create do
        description "Creates or updates a certificate."

        add_cert(OpenSSL::X509::Certificate.new(raw_source))
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
          hash = "\"#{new_resource.source.gsub(/\s/, '')}\""
          code_script = ""
          guard_script = ""
        end
        code_script << acl_script(hash)
        guard_script << cert_exists_script(hash)

        powershell_script "setting the acls on #{new_resource.source} in #{cert_location}\\#{new_resource.store_name}" do
          guard_interpreter :powershell_script
          convert_boolean_return true
          code code_script
          only_if guard_script
        end
      end

      action :delete do
        description "Deletes a certificate."

        delete_cert
      end

      action :fetch do
        description "Fetches a certificate."

        cert_obj = fetch_cert
        if cert_obj
          show_or_store_cert(cert_obj)
        else
          Chef::Log.info("Certificate not found")
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

        def delete_cert
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.delete(new_resource.source)
        end

        def fetch_cert
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.get(new_resource.source)
        end

        def verify_cert
          store = ::Win32::Certstore.open(new_resource.store_name)
          store.valid?(new_resource.source)
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
            cert_out = powershell_out("openssl x509 -text -inform DER -in #{cert_obj.to_pem} -outform CER").stdout
            out_file.puts(cert_out)
          when ".crt"
            cert_out = powershell_out("openssl x509 -text -inform DER -in #{cert_obj.to_pem} -outform CRT").stdout
            out_file.puts(cert_out)
          when ".pfx"
            cert_out = powershell_out("openssl pkcs12 -export -nokeys -in #{cert_obj.to_pem} -outform PFX").stdout
            out_file.puts(cert_out)
          when ".p7b"
            cert_out = powershell_out("openssl pkcs7 -export -nokeys -in #{cert_obj.to_pem} -outform P7B").stdout
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
          file = win_friendly_path(new_resource.source)
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

        def raw_source
          ext = ::File.extname(new_resource.source)
          convert_pem(ext, new_resource.source)
        end

        def convert_pem(ext, source)
          out = case ext
                when ".crt", ".der"
                  powershell_out("openssl x509 -text -inform DER -in #{source} -outform PEM").stdout
                when ".cer"
                  powershell_out("openssl x509 -text -inform DER -in #{source} -outform PEM").stdout
                when ".pfx"
                  powershell_out("openssl pkcs12 -in #{source} -nodes -passin pass:#{new_resource.pfx_password}").stdout
                when ".p7b"
                  powershell_out("openssl pkcs7 -print_certs -in #{source} -outform PEM").stdout
                end
          out = ::File.read(source) if out.nil? || out.empty?
          format_raw_out(out)
        end

        def format_raw_out(out)
          begin_cert = "-----BEGIN CERTIFICATE-----"
          end_cert = "-----END CERTIFICATE-----"
          begin_cert + out[/#{begin_cert}(.*?)#{end_cert}/m, 1] + end_cert
        end
      end

    end
  end
end
