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
require_relative "../exceptions"
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
        description: "The source file (for `create` and `acl_add`), thumbprint (for `delete`, `export`, and `acl_add`), or subject (for `delete` or `export`) if it differs from the resource block's name.",
        name_property: true

      property :pfx_password, String,
        description: "The password to access the object with if it is a PFX file."

      property :private_key_acl, Array,
        description: "An array of 'domain\\account' entries to be granted read-only access to the certificate's private key. Not idempotent."

      property :store_name, String,
        description: "The certificate store to manipulate.",
        default: "MY", equal_to: ["TRUSTEDPUBLISHER", "TrustedPublisher", "CLIENTAUTHISSUER", "REMOTE DESKTOP", "ROOT", "TRUSTEDDEVICES", "WEBHOSTING", "CA", "AUTHROOT", "TRUSTEDPEOPLE", "MY", "SMARTCARDROOT", "TRUST", "DISALLOWED"]

      property :user_store, [TrueClass, FalseClass],
        description: "Use the `CurrentUser` store instead of the default `LocalMachine` store. Note: Prior to #{ChefUtils::Dist::Infra::CLIENT}. 16.10 this property was ignored.",
        default: false

      deprecated_property_alias :cert_path, :output_path, "The cert_path property was renamed output_path in the 17.0 release of #{ChefUtils::Dist::Infra::CLIENT}. Please update your cookbooks to use the new property name."

      # lazy used to set default value of sensitive to true if password is set
      property :sensitive, [TrueClass, FalseClass],
        description: "Ensure that sensitive resource data is not logged by the #{ChefUtils::Dist::Infra::CLIENT}.",
        default: lazy { pfx_password ? true : false }, skip_docs: true

      property :exportable, [TrueClass, FalseClass],
        description: "Ensure that imported pfx certificate is exportable. Please provide 'true' if you want the certificate to be exportable.",
        default: false,
        introduced: "16.8"

      property :output_path, String,
        description: "A path on the node where a certificate object (PFX, PEM, CER, KEY, etc) can be exported to.",
        introduced: "17.0"

      action :create, description: "Creates or updates a certificate." do
        ext = get_file_extension(new_resource.source)

        # PFX certificates contains private keys and we import them with some other approach
        # import_certificates(fetch_cert_object(ext), (ext == ".pfx"))
        import_certificates(fetch_cert_object_from_file(ext), (ext == ".pfx"))
      end

      # acl_add is a modify-if-exists operation : not idempotent
      action :acl_add, description: "Adds read-only entries to a certificate's private key ACL." do

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

        powershell_script "setting the acls on #{new_resource.source} in #{ps_cert_location}\\#{new_resource.store_name}" do
          convert_boolean_return true
          code code_script
          only_if guard_script
          sensitive if new_resource.sensitive
        end
      end

      action :delete, description: "Deletes a certificate." do
        cert_obj = fetch_cert

        if cert_obj
          converge_by("Deleting certificate #{new_resource.source} from Store #{new_resource.store_name}") do
            delete_cert
          end
        else
          Chef::Log.debug("Certificate not found")
        end
      end

      action :fetch, description: "Fetches a certificate." do
        unless new_resource.output_path
          raise Chef::Exceptions::ResourceNotFound, "You must include an output_path parameter when calling the fetch action"
        end

        if ::File.extname(new_resource.output_path) == ".pfx"
          powershell_exec!(pfx_ps_cmd(resolve_thumbprint(new_resource.source), store_location: ps_cert_location, store_name: new_resource.store_name, output_path: new_resource.output_path, password: new_resource.pfx_password ))
        else
          cert_obj = fetch_cert
        end

        if cert_obj
          converge_by("Fetching certificate #{new_resource.source} from Store \\#{ps_cert_location}\\#{new_resource.store_name}") do
            export_cert(cert_obj, output_path: new_resource.output_path, store_name: new_resource.store_name , store_location: ps_cert_location, pfx_password: new_resource.pfx_password)
          end
        else
          Chef::Log.debug("Certificate not found")
        end
      end

      action :verify, description: "Verifies a certificate and logs the result." do
        out = verify_cert
        if !!out == out
          out = out ? "Certificate is valid" : "Certificate not valid"
        end
        Chef::Log.info(out.to_s)
      end

      action_class do
        @local_pfx_path = ""

        CERT_SYSTEM_STORE_LOCAL_MACHINE                    = 0x00020000
        CERT_SYSTEM_STORE_CURRENT_USER                     = 0x00010000

        def add_cert(cert_obj)
          store = ::Win32::Certstore.open(new_resource.store_name, store_location: native_cert_location)
          store.add(cert_obj)
        end

        def add_pfx_cert(path)
          exportable = new_resource.exportable ? 1 : 0
          store = ::Win32::Certstore.open(new_resource.store_name, store_location: native_cert_location)
          store.add_pfx(path, new_resource.pfx_password, exportable)
        end

        def delete_cert
          store = ::Win32::Certstore.open(new_resource.store_name, store_location: native_cert_location)
          store.delete(resolve_thumbprint(new_resource.source))
        end

        def fetch_cert
          store = ::Win32::Certstore.open(new_resource.store_name, store_location: native_cert_location)
          if new_resource.output_path && ::File.extname(new_resource.output_path) == ".key"
            fetch_key

          else
            store.get(resolve_thumbprint(new_resource.source), store_name: new_resource.store_name, store_location: native_cert_location)
          end
        end

        def fetch_key
          require "openssl" unless defined?(OpenSSL)
          file_name = ::File.basename(new_resource.output_path, ::File.extname(new_resource.output_path))
          directory = ::File.dirname(new_resource.output_path)
          pfx_file = file_name + ".pfx"
          new_pfx_output_path = ::File.join(Chef::FileCache.create_cache_path("pfx_files"), pfx_file)
          powershell_exec(pfx_ps_cmd(resolve_thumbprint(new_resource.source), store_location: ps_cert_location, store_name: new_resource.store_name, output_path: new_pfx_output_path, password: new_resource.pfx_password ))
          pkcs12 = OpenSSL::PKCS12.new(::File.binread(new_pfx_output_path), new_resource.pfx_password)
          f = ::File.open(new_resource.output_path, "w")
          f.write(pkcs12.key.to_s)
          f.flush
          f.close
        end

        def get_file_extension(file_name)
          if is_file?(file_name)
            ::File.extname(file_name)
          elsif is_url?(file_name)
            require "open-uri" unless defined?(OpenURI)
            uri = URI.parse(file_name)
            output_file = ::File.basename(uri.path)
            ::File.extname(output_file)
          end
        end

        def get_file_name(path_name)
          if is_file?(path_name)
            ::File.extname(path_name)
          elsif is_url?(path_name)
            require "open-uri" unless defined?(OpenURI)
            uri = URI.parse(path_name)
            ::File.basename(uri.path)
          end
        end

        def is_url?(source)
          require "uri" unless defined?(URI)
          uri = URI.parse(source)
          uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        end

        def is_file?(source)
          ::File.file?(source)
        end

        def is_file?(source)
          ::File.file?(source)
        end

        # Thumbprints should be exactly 40 Hex characters
        def valid_thumbprint?(string)
          string.match?(/[0-9A-Fa-f]/) && string.length == 40
        end

        def get_thumbprint(store_name, location, source)
          <<-GETTHUMBPRINTCODE
            $content = Get-ChildItem  -Path Cert:\\#{location}\\#{store_name} | Where-Object {$_.Subject -Match "#{source}"} | Select-Object Thumbprint
            $content.thumbprint
          GETTHUMBPRINTCODE
        end

        def resolve_thumbprint(thumbprint)
          return thumbprint if valid_thumbprint?(thumbprint)

          powershell_exec!(get_thumbprint(new_resource.store_name, ps_cert_location, new_resource.source)).result
        end

        # Checks whether a certificate with the given thumbprint
        # is already present and valid in certificate store
        # If the certificate is not present, verify_cert returns a String: "Certificate not found"
        # But if it is present but expired, it returns a Boolean: false
        # Otherwise, it returns a Boolean: true
        # updated this method to accept either a subject name or a thumbprint - 1/29/2021

        def verify_cert(thumbprint = new_resource.source)
          store = ::Win32::Certstore.open(new_resource.store_name, store_location: native_cert_location)
          if new_resource.pfx_password.nil?
            store.valid?(resolve_thumbprint(thumbprint), store_location: native_cert_location, store_name: new_resource.store_name )
          else
            store.valid?(resolve_thumbprint(thumbprint), store_location: native_cert_location, store_name: new_resource.store_name)
          end
        end

        # this array structure is solving 2 problems. The first is that we need to have support for both the CurrentUser AND LocalMachine stores
        # Secondly, we need to pass the proper constant name for each store to win32-certstore but also pass the short name to powershell scripts used here
        def ps_cert_location
          new_resource.user_store ? "CurrentUser" : "LocalMachine"
        end

        def pfx_ps_cmd(thumbprint, store_location: "LocalMachine", store_name: "My", output_path:, password: )
          <<-CMD
            $my_pwd = ConvertTo-SecureString -String "#{password}" -Force -AsPlainText
            $cert = Get-ChildItem -path cert:\\#{store_location}\\#{store_name} -Recurse | Where { $_.Thumbprint -eq "#{thumbprint.upcase}" }
            Export-PfxCertificate -Cert $cert -FilePath "#{output_path}" -Password $my_pwd
          CMD
        end

        def native_cert_location
          new_resource.user_store ? CERT_SYSTEM_STORE_CURRENT_USER : CERT_SYSTEM_STORE_LOCAL_MACHINE
        end

        def cert_script(persist)
          cert_script = "$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2"
          file = Chef::Util::PathHelper.cleanpath(new_resource.source, ps_cert_location)
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
  Test-Path "Cert:\\#{ps_cert_location}\\#{new_resource.store_name}\\$hash"
          EOH
        end

        def within_store_script
          inner_script = yield "$store"
          <<-EOH
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "#{new_resource.store_name}", ([System.Security.Cryptography.X509Certificates.StoreLocation]::#{ps_cert_location})
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
  $storeCert = Get-ChildItem "cert:\\#{ps_cert_location}\\#{new_resource.store_name}\\$hash"
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

        def fetch_cert_object_from_file(ext)
          if is_file?(new_resource.source)
            begin
              ::File.exist?(new_resource.source)
              contents = ::File.binread(new_resource.source)
            rescue => exception
              message = "Unable to load the certificate object from the specified local path : #{new_resource.source}\n"
              message << exception.message
              raise Chef::Exceptions::FileNotFound, message
            end
          elsif is_url?(new_resource.source)
            require "uri" unless defined?(URI)
            uri = URI(new_resource.source)
            state = uri.is_a?(URI::HTTP) && !uri.host.nil? ? true : false
            if state
              begin
                output_file_name = get_file_name(new_resource.source)
                unless Dir.exist?(Chef::Config[:file_cache_path])
                  Dir.mkdir(Chef::Config[:file_cache_path])
                end
                local_path = ::File.join(Chef::Config[:file_cache_path], output_file_name)
                @local_pfx_path = local_path
                ::File.open(local_path, "wb") do |file|
                  file.write URI.open(new_resource.source).read
                end
              rescue => exception
                message = "Not Able to Download Certificate Object at the URL specified : #{new_resource.source}\n"
                message << exception.message
                raise Chef::Exceptions::FileNotFound, message
              end

              contents = ::File.binread(local_path)

            else
              message = "Not Able to Download Certificate Object at the URL specified : #{new_resource.source}\n"
              message << exception.message
              raise Chef::Exceptions::InvalidRemoteFileURI, message
            end
          else
            message = "You passed an invalid file or url to import. Please check the spelling and try again."
            message << exception.message
            raise Chef::Exceptions::ArgumentError, message
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

        def export_cert(cert_obj, output_path:, store_name:, store_location:, pfx_password:)
          # Delete the cert if it exists. This is non-destructive in that it only removes the file and not the entire path.
          # We want to ensure we're not randomly loading an old stinky cert.
          if ::File.exists?(output_path)
            ::File.delete(output_path)
          end

          unless ::File.directory?(::File.dirname(output_path))
            FileUtils.mkdir_p(::File.dirname(output_path))
          end

          out_file = ::File.new(output_path, "w+")

          case ::File.extname(output_path)
          when ".pem"
            out_file.puts(cert_obj)
          when ".der"
            out_file.puts(cert_obj.to_der)
          when ".cer"
            cert_out = shell_out("openssl x509 -text -inform DER -in #{cert_obj.to_pem} -outform CER").stdout
            out_file.puts(cert_out)
          when ".crt"
            cert_out = shell_out("openssl x509 -text -inform DER -in #{cert_obj} -outform CRT").stdout
            out_file.puts(cert_out)
          when ".pfx"
            pfx_ps_cmd(resolve_thumbprint(new_resource.source), store_location: store_location, store_name: store_name, output_path: output_path, password: pfx_password )
          when ".p7b"
            cert_out = shell_out("openssl pkcs7 -export -nokeys -in #{cert_obj.to_pem} -outform P7B").stdout
            out_file.puts(cert_out)
          when ".key"
            out_file.puts(cert_obj)
          else
            Chef::Log.info("Supported certificate format .pem, .der, .cer, .crt, and .p7b")
          end

          out_file.close
        end

        # Imports the certificate object into cert store
        #
        # @param cert_objs [OpenSSL::X509::Certificate] Object containing certificate's attributes
        #
        # @param is_pfx [Boolean] true if we want to import a PFX certificate
        #
        def import_certificates(cert_objs, is_pfx, store_name: new_resource.store_name, store_location: native_cert_location)
          [cert_objs].flatten.each do |cert_obj|
            # thumbprint = OpenSSL::Digest.new("SHA1", cert_obj.to_der).to_s
            # pkcs = OpenSSL::PKCS12.new(cert_obj, new_resource.pfx_password)
            # cert = OpenSSL::X509::Certificate.new(pkcs.certificate.to_pem)
            thumbprint = OpenSSL::Digest.new("SHA1", cert_obj.to_der).to_s
            if is_pfx
              if verify_cert(thumbprint) == true
                Chef::Log.debug("Certificate is already present")
              else
                if is_file?(new_resource.source)
                  converge_by("Creating a PFX #{new_resource.source} for Store #{new_resource.store_name}") do
                    add_pfx_cert(new_resource.source)
                  end
                elsif is_url?(new_resource.source)
                  converge_by("Creating a PFX #{@local_pfx_path} for Store #{new_resource.store_name}") do
                    add_pfx_cert(@local_pfx_path)
                  end
                else
                  message = "You passed an invalid file or url to import. Please check the spelling and try again."
                  message << exception.message
                  raise Chef::Exceptions::ArgumentError, message
                end
              end
            else
              if verify_cert(thumbprint) == true
                Chef::Log.debug("Certificate is already present")
              else
                converge_by("Creating a certificate #{new_resource.source} for Store #{new_resource.store_name}") do
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
