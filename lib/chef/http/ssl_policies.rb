#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Thom May (<thom@clearairturbulence.org>)
# Author:: Nuo Yan (<nuo@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
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

autoload :OpenSSL, "openssl"
require_relative "../util/path_helper"

class Chef
  class HTTP

    # == Chef::HTTP::DefaultSSLPolicy
    # Configures SSL behavior on an HTTP object via visitor pattern.
    class DefaultSSLPolicy

      def self.apply_to(http_client)
        new(http_client).apply
        http_client
      end

      attr_reader :http_client

      def initialize(http_client)
        @http_client = http_client
      end

      def apply
        set_verify_mode
        set_ca_store
        set_custom_certs
        set_client_credentials
      end

      def set_verify_mode
        if config[:ssl_verify_mode] == :verify_none
          http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
        elsif config[:ssl_verify_mode] == :verify_peer
          http_client.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
      end

      def set_ca_store
        if config[:ssl_ca_path]
          unless ::File.exist?(config[:ssl_ca_path])
            raise Chef::Exceptions::ConfigurationError, "The configured ssl_ca_path #{config[:ssl_ca_path]} does not exist"
          end

          http_client.ca_path = config[:ssl_ca_path]
        elsif config[:ssl_ca_file]
          unless ::File.exist?(config[:ssl_ca_file])
            raise Chef::Exceptions::ConfigurationError, "The configured ssl_ca_file #{config[:ssl_ca_file]} does not exist"
          end

          http_client.ca_file = config[:ssl_ca_file]
        elsif ENV["SSL_CERT_FILE"]
          unless ::File.exist?(ENV["SSL_CERT_FILE"])
            raise Chef::Exceptions::ConfigurationError, "The configured ssl_ca_file #{ENV["SSL_CERT_FILE"]} does not exist"
          end

          http_client.ca_file = ENV["SSL_CERT_FILE"]
        end
      end

      def set_custom_certs
        unless http_client.cert_store
          http_client.cert_store = OpenSSL::X509::Store.new
          http_client.cert_store.set_default_paths
        end
        if config.trusted_certs_dir
          certs = Dir.glob(::File.join(Chef::Util::PathHelper.escape_glob_dir(config.trusted_certs_dir), "*.{crt,pem}"))
          certs.each do |cert_file|
            cert = begin
              OpenSSL::X509::Certificate.new(::File.binread(cert_file))
                   rescue OpenSSL::X509::CertificateError => e
                     raise Chef::Exceptions::ConfigurationError, "Error reading cert file '#{cert_file}', original error '#{e.class}: #{e.message}'"
            end
            add_trusted_cert(cert)
          end
        end
      end

      def set_client_credentials
        return unless config[:ssl_client_cert] || config[:ssl_client_key]

        unless config[:ssl_client_cert] && config[:ssl_client_key]
          raise Chef::Exceptions::ConfigurationError, "You must configure ssl_client_cert and ssl_client_key together"
        end
        unless ::File.exists?(config[:ssl_client_cert])
          raise Chef::Exceptions::ConfigurationError, "The configured ssl_client_cert #{config[:ssl_client_cert]} does not exist"
        end
        unless ::File.exists?(config[:ssl_client_key])
          raise Chef::Exceptions::ConfigurationError, "The configured ssl_client_key #{config[:ssl_client_key]} does not exist"
        end

        begin
          http_client.cert = OpenSSL::X509::Certificate.new(::File.binread(config[:ssl_client_cert]))
        rescue OpenSSL::X509::CertificateError => e
          raise Chef::Exceptions::ConfigurationError, "Error reading cert file '#{config[:ssl_client_cert]}', original error '#{e.class}: #{e.message}'"
        end

        begin
          http_client.key = OpenSSL::PKey::RSA.new(::File.binread(config[:ssl_client_key]))
        rescue OpenSSL::PKey::RSAError => e
          raise Chef::Exceptions::ConfigurationError, "Error reading key file '#{config[:ssl_client_key]}', original error '#{e.class}: #{e.message}'"
        end
      end

      def config
        Chef::Config
      end

      private

      def add_trusted_cert(cert)
        http_client.cert_store.add_cert(cert)
      rescue OpenSSL::X509::StoreError => e
        raise e unless e.message == "cert already in hash table"
      end

    end

    class APISSLPolicy < DefaultSSLPolicy

      def set_verify_mode
        if config[:ssl_verify_mode] == :verify_peer || config[:verify_api_cert]
          http_client.verify_mode = OpenSSL::SSL::VERIFY_PEER
        elsif config[:ssl_verify_mode] == :verify_none
          http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
    end

    # This policy is used when we want to explicitly turn on verification
    # for a specific request regardless of the API Policy. For example, when
    # doing a `remote_file` where the user specified `verify_mode :verify_peer`
    class VerifyPeerSSLPolicy < DefaultSSLPolicy
      def set_verify_mode
        http_client.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end

    # This policy is used when we want to explicitly turn off verification
    # for a specific request regardless of the API Policy. For example, when
    # doing a `remote_file` where the user specified `verify_mode :verify_none`
    class VerifyNoneSSLPolicy < DefaultSSLPolicy
      def set_verify_mode
        http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

  end
end
