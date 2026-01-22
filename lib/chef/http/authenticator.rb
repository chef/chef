#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "chef/mixin/powershell_exec"
require_relative "auth_credentials"
require_relative "../exceptions"
require_relative "../win32/registry"
autoload :OpenSSL, "openssl"

class Chef
  class HTTP
    class Authenticator
      DEFAULT_SERVER_API_VERSION = "2".freeze

      extend Chef::Mixin::PowershellExec

      attr_reader :signing_key_filename
      attr_reader :raw_key
      attr_reader :attr_names
      attr_reader :auth_credentials
      attr_reader :version_class
      attr_reader :api_version

      attr_accessor :sign_request

      def initialize(opts = {})
        @raw_key = nil
        @sign_request = true
        @signing_key_filename = opts[:signing_key_filename]
        @key = load_signing_key(opts[:signing_key_filename], opts[:raw_key])
        @auth_credentials = AuthCredentials.new(opts[:client_name], @key, use_ssh_agent: opts[:ssh_agent_signing])
        @version_class = opts[:version_class]
        @api_version = opts[:api_version]
      end

      def handle_request(method, url, headers = {}, data = false)
        headers["X-Ops-Server-API-Version"] = request_version
        headers.merge!(authentication_headers(method, url, data, headers)) if sign_requests?
        [method, url, headers, data]
      end

      def handle_response(http_response, rest_request, return_value)
        [http_response, rest_request, return_value]
      end

      def stream_response_handler(response)
        nil
      end

      def handle_stream_complete(http_response, rest_request, return_value)
        [http_response, rest_request, return_value]
      end

      def request_version
        if version_class
          version_class.best_request_version
        elsif api_version
          api_version
        elsif Chef::ServerAPIVersions.instance.negotiated?
          Chef::ServerAPIVersions.instance.max_server_version.to_s
        else
          DEFAULT_SERVER_API_VERSION
        end
      end

      def sign_requests?
        auth_credentials.sign_requests? && @sign_request
      end

      def client_name
        @auth_credentials.client_name
      end

      def detect_certificate_key(client_name)
        self.class.detect_certificate_key(client_name)
      end

      def check_certstore_for_key(client_name)
        self.class.check_certstore_for_key(client_name)
      end

      def retrieve_certificate_key(client_name)
        self.class.retrieve_certificate_key(client_name)
      end

      def get_cert_password
        self.class.get_cert_password
      end

      def encrypt_pfx_pass_with_vector
        self.class.encrypt_pfx_pass_with_vector
      end

      def decrypt_pfx_pass_with_vector
        self.class.decrypt_pfx_pass_with_vector
      end

      # Detects if a private key exists in a certificate repository like Keychain (macOS) or Certificate Store (Windows)
      #
      # @param client_name - we're using the node name to store and retrieve any keys
      # Returns true if a key is found, false if not. False will trigger a registration event which will lead to a certificate based key being created
      #
      def self.detect_certificate_key(client_name)
        if ChefUtils.windows?
          check_certstore_for_key(client_name)
        else # generic return for Mac and LInux clients
          false
        end
      end

      def self.get_cert_user
        Chef::Config[:auth_key_registry_type] == "user" ? "CurrentUser" : "LocalMachine"
      end

      def self.get_registry_user
        Chef::Config[:auth_key_registry_type] == "user" ? "HKEY_CURRENT_USER" : "HKEY_LOCAL_MACHINE"
      end

      def self.check_certstore_for_key(client_name)
        store = get_cert_user
        powershell_code = <<~CODE
          $cert = Get-ChildItem -path cert:\\#{store}\\My -Recurse -Force  | Where-Object { $_.Subject -Match "chef-#{client_name}" } -ErrorAction Stop
          if (($cert.HasPrivateKey -eq $true) -and ($cert.PrivateKey.Key.ExportPolicy -ne "NonExportable")) {
            return $true
          }
          else{
            return $false
          }
        CODE
        powershell_exec!(powershell_code).result
      end

      def load_signing_key(key_file, raw_key = nil)
        results = retrieve_certificate_key(Chef::Config[:node_name])

        if !!results
          @raw_key = results
        elsif key_file == nil? && raw_key == nil?
          puts "\nNo key detected\n"
        elsif !!key_file
          @raw_key = IO.read(key_file).strip
        elsif !!raw_key
          @raw_key = raw_key.strip
        else
          return
        end
        # Pass in '' as the passphrase to avoid OpenSSL prompting on the TTY if
        # given an encrypted key. This also helps if using a single file for
        # both the public and private key with ssh-agent mode.
        @key = OpenSSL::PKey::RSA.new(@raw_key, "")
      rescue SystemCallError, IOError => e
        Chef::Log.warn "Failed to read the private key #{key_file}: #{e.inspect}"
        raise Chef::Exceptions::PrivateKeyMissing, "I cannot read #{key_file}, which you told me to use to sign requests!"
      rescue OpenSSL::PKey::RSAError
        msg = "The file #{key_file} or :raw_key option does not contain a correctly formatted private key or the key is encrypted.\n"
        msg << "The key file should begin with '-----BEGIN RSA PRIVATE KEY-----' and end with '-----END RSA PRIVATE KEY-----'"
        raise Chef::Exceptions::InvalidPrivateKey, msg
      end

      def self.get_cert_password
        store = get_registry_user
        @win32registry = Chef::Win32::Registry.new
        path = "#{store}\\Software\\Progress\\Authentication"
        # does the registry key even exist?
        # password_blob should be an array of hashes
        password_blob = @win32registry.get_values(path)
        if password_blob.nil? || password_blob.empty?
          raise Chef::Exceptions::Win32RegKeyMissing
        end

        # Did someone have just the password stored in the registry?
        raw_data = password_blob.map { |x| x[:data] }
        vector = raw_data[2]
        if !!vector
          decrypted_password = decrypt_pfx_pass_with_vector(password_blob)
        else
          decrypted_password = decrypt_pfx_pass_with_password(password_blob)
          if !!decrypted_password
            migrate_pass_to_use_vector(decrypted_password)
          else
            Chef::Log.error("Failed to retrieve certificate password")
          end
        end
        decrypted_password
      rescue Chef::Exceptions::Win32RegKeyMissing
        # if we don't have a password, log that and generate one
        store = get_registry_user
        new_path = "#{store}\\Software\\Progress\\Authentication"
        unless @win32registry.key_exists?(new_path)
          @win32registry.create_key(new_path, true)
        end
        create_and_store_new_password
      end

      def self.encrypt_pfx_pass_with_vector(password)
        powershell_code = <<~CODE
          $AES = [System.Security.Cryptography.Aes]::Create()
          $key_temp = [System.Convert]::ToBase64String($AES.Key)
          $iv_temp = [System.Convert]::ToBase64String($AES.IV)
          $encryptor = $AES.CreateEncryptor()
          [System.Byte[]]$Bytes =  [System.Text.Encoding]::Unicode.GetBytes("#{password}")
          $EncryptedBytes = $encryptor.TransformFinalBlock($Bytes,0,$Bytes.Length)
          $EncryptedBase64String = [System.Convert]::ToBase64String($EncryptedBytes)
          # create array of encrypted pass, key, iv
          $password_blob = @($EncryptedBase64String, $key_temp, $iv_temp)
          return $password_blob
        CODE
        powershell_exec!(powershell_code).result
      end

      def self.decrypt_pfx_pass_with_vector(password_blob)
        raw_data = password_blob.map { |x| x[:data] }
        password = raw_data[0]
        key = raw_data[1]
        vector = raw_data[2]

        powershell_code = <<~CODE
          $KeyBytes = [System.Convert]::FromBase64String("#{key}")
          $IVBytes = [System.Convert]::FromBase64String("#{vector}")
          $aes = [System.Security.Cryptography.Aes]::Create()
          $aes.Key = $KeyBytes
          $aes.IV = $IVBytes
          $EncryptedBytes = [System.Convert]::FromBase64String("#{password}")
          $Decryptor = $aes.CreateDecryptor()
          $DecryptedBytes = $Decryptor.TransformFinalBlock($EncryptedBytes,0,$EncryptedBytes.Length)
          $DecryptedString = [System.Text.Encoding]::Unicode.GetString($DecryptedBytes)
          return $DecryptedString
        CODE
        results = powershell_exec!(powershell_code).result
      end

      def self.decrypt_pfx_pass_with_password(password_blob)
        password = ""
        password_blob.each do |secret|
          if secret[:name] == "PfxPass"
            password = secret[:data]
          else
            Chef::Log.error("Failed to retrieve a password for the private key")
          end
        end
        powershell_code = <<~CODE
          $secure_string = "#{password}" | ConvertTo-SecureString
          $string = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($secure_string))))
          return $string
        CODE
        powershell_exec!(powershell_code).result
      end

      def self.migrate_pass_to_use_vector(password)
        store = get_cert_user
        corrected_store = (store == "CurrentUser" ? "HKCU" : "HKLM")
        powershell_code = <<~CODE
          Remove-ItemProperty -Path "#{corrected_store}:\\Software\\Progress\\Authentication" -Name "PfXPass"
        CODE
        powershell_exec!(powershell_code)
        create_and_store_new_password(password)
      end

      # This method name is a bit of a misnomer. We call it to legit create a new password using the vector format.
      # But we also call it with a password that needs to be migrated to use the vector format too.
      def self.create_and_store_new_password(password = nil)
        @win32registry = Chef::Win32::Registry.new
        store = get_registry_user
        path = "#{store}\\Software\\Progress\\Authentication"
        if password.nil?
          require "securerandom" unless defined?(SecureRandom)
          size = 14
          password = SecureRandom.alphanumeric(size)
        end
        encrypted_blob = encrypt_pfx_pass_with_vector(password)
        encrypted_password = encrypted_blob[0]
        key = encrypted_blob[1]
        vector = encrypted_blob[2]
        values = [
                  { name: "PfxPass", type: :string, data: encrypted_password },
                  { name: "PfxKey", type: :string, data: key },
                  { name: "PfxIV", type: :string, data: vector },
                ]
        values.each do |i|
          @win32registry.set_value(path, i)
        end
        password
      end

      def self.retrieve_certificate_key(client_name)
        if ChefUtils.windows?
          require "openssl" unless defined?(OpenSSL)
          password = get_cert_password
          return false unless password

          if !!check_certstore_for_key(client_name)
            ps_blob = powershell_exec!(get_the_key_ps(client_name, password)).result
            file_path = ps_blob["PSPath"].split("::")[1]
            pkcs = OpenSSL::PKCS12.new(File.binread(file_path), password)

            # We check the pfx we just extracted the private key from
            # if that cert is expiring in 7 days or less we generate a new pfx/p12 object
            # then we post the new public key from that to the client endpoint on
            # chef server.
            File.delete(file_path)
            key_expiring = is_certificate_expiring?(pkcs)
            if key_expiring
              powershell_exec!(delete_old_key_ps(client_name))
              ::Chef::Client.update_key_and_register(Chef::Config[:client_name], pkcs)
            end

            return pkcs.key.private_to_pem
          end
        end

        false
      end

      def self.is_certificate_expiring?(pkcs)
        today = Date.parse(Time.now.utc.iso8601)
        future = Date.parse(pkcs.certificate.not_after.iso8601)
        future.mjd - today.mjd <= 7
      end

      def self.get_the_key_ps(client_name, password)
        store = get_cert_user
        powershell_code = <<~CODE
            Try {
              $my_pwd = ConvertTo-SecureString -String "#{password}" -Force -AsPlainText;
              $cert = Get-ChildItem -path cert:\\#{store}\\My -Recurse | Where-Object { $_.Subject -match "chef-#{client_name}$" } -ErrorAction Stop;
              $tempfile = [System.IO.Path]::GetTempPath() + "export_pfx.pfx";
              Export-PfxCertificate -Cert $cert -Password $my_pwd -FilePath $tempfile;
            }
            Catch {
              return $false
            }
        CODE
      end

      def self.delete_old_key_ps(client_name)
        store = get_cert_user
        powershell_code = <<~CODE
          Get-ChildItem -path cert:\\#{store}\\My -Recurse | Where-Object { $_.Subject -match "chef-#{client_name}$" } | Remove-Item -ErrorAction Stop;
        CODE
      end

      def authentication_headers(method, url, json_body = nil, headers = nil)
        request_params = {
          http_method: method,
          path: url.path,
          body: json_body,
          host: "#{url.host}:#{url.port}",
          headers: headers,
        }
        request_params[:body] ||= ""
        auth_credentials.signature_headers(request_params)
      end
    end
  end
end
