# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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

require_relative "../knife"

class Chef
  class Knife
    class WindowsCertGenerate < Knife

      attr_accessor :thumbprint, :hostname

      banner "knife windows cert generate FILE_PATH (options)"

      deps do
        require "openssl" unless defined?(OpenSSL)
        require "socket" unless defined?(Socket)
      end

      option :hostname,
        short: "-H HOSTNAME",
        long: "--hostname HOSTNAME",
        description: "Use to specify the hostname for the listener.
        For example, --hostname something.mydomain.com or *.mydomain.com.",
        required: true

      option :output_file,
        short: "-o PATH",
        long: "--output-file PATH",
        description: "Specifies the file path at which to generate the 3 certificate files of type .pfx, .b64, and .pem. The default is './winrmcert'.",
        default: "winrmcert"

      option :key_length,
        short: "-k LENGTH",
        long: "--key-length LENGTH",
        description: "Specifies the key length of the certificate. The default is 2048",
        default: "2048"

      option :cert_validity,
        short: "-cv MONTHS",
        long: "--cert-validity MONTHS",
        description: "Specifies how long the certificate will be valid. The default is 24 months",
        default: "24"

      option :cert_passphrase,
        short: "-cp PASSWORD",
        long: "--cert-passphrase PASSWORD",
        description: "Specifies certificate's passphrase."

      def generate_keypair
        OpenSSL::PKey::RSA.new(config[:key_length].to_i)
      end

      def prompt_for_passphrase
        passphrase = ""
        loop do
          print "Passphrases do not match. Try again.\n" unless passphrase.empty?
          passphrase = ui.ask("Enter certificate passphrase (empty for no passphrase):", echo: false)
          confirm_passphrase = ui.ask("Confirm the passphrase:", echo: false)
          break if passphrase == confirm_passphrase
        end
      end

      def generate_certificate(rsa_key)
        @hostname = config[:hostname] if config[:hostname]

        # Create a self-signed X509 certificate from the rsa_key (unencrypted)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = Random.rand(65534) + 1 # 2 digit byte range random number for better security aspect

        cert.subject = OpenSSL::X509::Name.parse "/CN=#{@hostname}"
        cert.issuer = cert.subject
        cert.public_key = rsa_key.public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + 2 * 365 * config[:cert_validity].to_i * 60 * 60 # 2 years validity
        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
        cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
        cert.add_extension(ef.create_extension("extendedKeyUsage", "1.3.6.1.5.5.7.3.1", false))
        cert.sign(rsa_key, OpenSSL::Digest.new("SHA1"))
        @thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der)
        cert
      end

      def write_certificate_to_file(cert, file_path, rsa_key)
        File.open(file_path + ".pem", "wb") { |f| f.print cert.to_pem }
        config[:cert_passphrase] = prompt_for_passphrase unless config[:cert_passphrase]
        pfx = OpenSSL::PKCS12.create("#{config[:cert_passphrase]}", "winrmcert", rsa_key, cert)
        File.open(file_path + ".pfx", "wb") { |f| f.print pfx.to_der }
        File.open(file_path + ".b64", "wb") { |f| f.print Base64.strict_encode64(pfx.to_der) }
      end

      def certificates_already_exist?(file_path)
        certs_exists = false
        %w{pem pfx b64}.each do |extn|
          unless Dir.glob("#{file_path}.*#{extn}").empty?
            certs_exists = true
            break
          end
        end

        if certs_exists
          begin
            confirm("Do you really want to overwrite existing certificates")
          rescue SystemExit # Need to handle this as confirming with N/n raises SystemExit exception
            exit!
          end
        end
      end

      def run
        # takes user specified first cli value as a destination file path for generated cert.
        file_path = @name_args.empty? ? config[:output_file].sub(/\.(\w+)$/, "") : @name_args.first

        # check if certs already exists at given file path
        certificates_already_exist? file_path

        begin
          filename = File.basename(file_path)
          rsa_key = generate_keypair
          cert = generate_certificate rsa_key
          write_certificate_to_file cert, file_path, rsa_key
          ui.info "Generated Certificates:"
          ui.info "- #{filename}.pfx - PKCS12 format key pair. Contains public and private keys, can be used with an SSL server."
          ui.info "- #{filename}.b64 - Base64 encoded PKCS12 key pair. Contains public and private keys, used by some cloud provider API's to configure SSL servers."
          ui.info "- #{filename}.pem - Base64 encoded public certificate only. Required by the client to connect to the server."
          ui.info "Certificate Thumbprint: #{@thumbprint.to_s.upcase}"
        rescue => e
          puts "ERROR: + #{e}"
        end
      end

    end
  end
end
