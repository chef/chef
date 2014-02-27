#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/http/auth_credentials'
require 'chef/exceptions'
require 'openssl'

class Chef
  class HTTP
    class Authenticator

      attr_reader :signing_key_filename
      attr_reader :raw_key
      attr_reader :attr_names
      attr_reader :auth_credentials

      attr_accessor :sign_request

      def initialize(opts={})
        @raw_key = nil
        @sign_request = true
        @signing_key_filename = opts[:signing_key_filename]
        @key = load_signing_key(opts[:signing_key_filename], opts[:raw_key])
        @auth_credentials = AuthCredentials.new(opts[:client_name], @key)
      end

      def handle_request(method, url, headers={}, data=false)
        headers.merge!(authentication_headers(method, url, data)) if sign_requests?
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

      def sign_requests?
        auth_credentials.sign_requests? && @sign_request
      end

      def client_name
        @auth_credentials.client_name
      end

      def load_signing_key(key_file, raw_key = nil)
        if (!!key_file)
          @raw_key = IO.read(key_file).strip
        elsif (!!raw_key)
          @raw_key = raw_key.strip
        else
          return nil
        end
        @key = OpenSSL::PKey::RSA.new(@raw_key)
      rescue SystemCallError, IOError => e
        Chef::Log.warn "Failed to read the private key #{key_file}: #{e.inspect}"
        raise Chef::Exceptions::PrivateKeyMissing, "I cannot read #{key_file}, which you told me to use to sign requests!"
      rescue OpenSSL::PKey::RSAError
        msg = "The file #{key_file} or :raw_key option does not contain a correctly formatted private key.\n"
        msg << "The key file should begin with '-----BEGIN RSA PRIVATE KEY-----' and end with '-----END RSA PRIVATE KEY-----'"
        raise Chef::Exceptions::InvalidPrivateKey, msg
      end

      def authentication_headers(method, url, json_body=nil)
        request_params = {:http_method => method, :path => url.path, :body => json_body, :host => "#{url.host}:#{url.port}"}
        request_params[:body] ||= ""
        auth_credentials.signature_headers(request_params)
      end

    end
  end
end
