#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

      def self.check_certstore_for_key(client_name)
        powershell_code = <<~CODE
          $cert = Get-ChildItem -path cert:\\LocalMachine\\My -Recurse -Force  | Where-Object { $_.Subject -Match "#{client_name}" } -ErrorAction Stop
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

        if key_file == nil? && raw_key == nil?
          puts "\nNo key detected\n"
        elsif results != false
          # results variable can be 1 of 2 values - "False" or the contents of a key.
          @raw_key = results
        elsif !!key_file
          @raw_key = IO.read(key_file).strip
        elsif !!raw_key
          @raw_key = raw_key.strip
        else
          return nil
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

      # takes no parameters. Checks for the password in the registry and returns it if there, otherwise returns false
      def self.get_cert_password
        @win32registry = Chef::Win32::Registry.new
        path = "HKEY_LOCAL_MACHINE\\Software\\Progress\\Authentication"
        present = @win32registry.get_values(path)
        if present.nil? || present.empty?
          raise Chef::Exceptions::Win32RegKeyMissing
        end

        if present.map { |h| h[:name] }[0] == "PfxPass"
          present.map { |h| h[:data] }[0].to_s
        end
      rescue Chef::Exceptions::Win32RegKeyMissing
        # if we don't have a password, log that and generate one
        Chef::Log.warn "Authentication Hive and value not present in registry, creating it now"
        new_path = "HKEY_LOCAL_MACHINE\\Software\\Progress\\Authentication"
        # cspell:disable-next-line
        some_chars = "~!@#$%^&*_-+=`|\\(){}[<]:;'>,.?/0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".each_char.to_a
        password = some_chars.sample(1 + rand(some_chars.count)).join[0...14]
        values = { name: "PfxPass", type: :string, data: password }
        @win32registry.set_value(new_path, values)
        password
      end

      def self.retrieve_certificate_key(client_name)
        require "openssl" unless defined?(OpenSSL)

        if ChefUtils.windows?

          password = get_cert_password

          unless password
            return false
          end

          powershell_code = <<~CODE
              Try {
                $my_pwd = ConvertTo-SecureString -String "#{password}" -Force -AsPlainText;
                $cert = Get-ChildItem -path cert:\\LocalMachine\\My -Recurse | Where-Object { $_.Subject -match "#{client_name}" } -ErrorAction Stop;
                $tempfile = [System.IO.Path]::GetTempPath() + "export_pfx.pfx";
                Export-PfxCertificate -Cert $cert -Password $my_pwd -FilePath $tempfile;
              }
              Catch {
                return $false
              }
          CODE
          my_result = powershell_exec!(powershell_code).result

          if my_result != false
            pkcs = OpenSSL::PKCS12.new(File.binread(my_result["PSPath"].split("::")[1]), password)
            ::File.delete(my_result["PSPath"].split("::")[1])
            OpenSSL::PKey::RSA.new(pkcs.key.to_pem)
          else
            false
          end
        else # doing nothing for the Mac and Linux clients for now
          false
        end
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
