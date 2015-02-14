#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/config'
require 'chef/rest'
require 'chef/exceptions'

class Chef
  class ApiClient

    # ==Chef::ApiClient::Registration
    # Manages the process of creating or updating a Chef::ApiClient on the
    # server and writing the resulting private key to disk. Registration uses
    # the validator credentials for its API calls. This allows it to bootstrap
    # a new client/node identity by borrowing the validator client identity
    # when creating a new client.
    class Registration
      attr_reader :destination
      attr_reader :name

      def initialize(name, destination, http_api: nil)
        @name                         = name
        @destination                  = destination
        @http_api                     = http_api
        @server_generated_private_key = nil
      end

      # Runs the client registration process, including creating the client on
      # the chef-server and writing its private key to disk.
      #--
      # If client creation fails with a 5xx, it is retried up to 5 times. These
      # retries are on top of the retries with randomized exponential backoff
      # built in to Chef::REST. The retries here are a workaround for failures
      # caused by resource contention in Hosted Chef when creating a very large
      # number of clients simultaneously, (e.g., spinning up 100s of ec2 nodes
      # at once). Future improvements to the affected component should make
      # these retries unnecessary.
      def run
        assert_destination_writable!
        retries = Config[:client_registration_retries] || 5
        begin
          create_or_update
        rescue Net::HTTPFatalError => e
          # HTTPFatalError implies 5xx.
          raise if retries <= 0
          retries -= 1
          Chef::Log.warn("Failed to register new client, #{retries} tries remaining")
          Chef::Log.warn("Response: HTTP #{e.response.code} - #{e}")
          retry
        end
        write_key
      end

      def assert_destination_writable!
        if (File.exists?(destination) && !File.writable?(destination)) or !File.writable?(File.dirname(destination))
          raise Chef::Exceptions::CannotWritePrivateKey, "I cannot write your private key to #{destination} - check permissions?"
        end
      end

      def write_key
        ::File.open(destination, file_flags, 0600) do |f|
          f.print(private_key)
        end
      rescue IOError => e
        raise Chef::Exceptions::CannotWritePrivateKey, "Error writing private key to #{destination}: #{e}"
      end

      def create_or_update
        create
      rescue Net::HTTPServerException => e
        # If create fails because the client exists, attempt to update. This
        # requires admin privileges.
        raise unless e.response.code == "409"
        update
      end

      def create
        response = http_api.post("clients", post_data)
        @server_generated_private_key = response["private_key"]
        response
      end

      def update
        response = http_api.put("clients/#{name}", put_data)
        if response.respond_to?(:private_key) # Chef 11
          @server_generated_private_key = response.private_key
        else # Chef 10
          @server_generated_private_key = response["private_key"]
        end
        response
      end

      def put_data
        base_put_data = { :name => name, :admin => false }
        if self_generate_keys?
          base_put_data[:public_key] = generated_public_key
        else
          base_put_data[:private_key] = true
        end
        base_put_data
      end

      def post_data
        post_data = { :name => name, :admin => false }
        post_data[:public_key] = generated_public_key if self_generate_keys?
        post_data
      end

      def http_api
        @http_api ||= Chef::REST.new(Chef::Config[:chef_server_url],
                                     Chef::Config[:validation_client_name],
                                     Chef::Config[:validation_key])
      end

      # Whether or not to generate keys locally and post the public key to the
      # server. Delegates to `Chef::Config.local_key_generation`. Servers
      # before 11.0 do not support this feature.
      def self_generate_keys?
        Chef::Config.local_key_generation
      end

      def private_key
        if self_generate_keys?
          generated_private_key.to_pem
        else
          @server_generated_private_key
        end
      end

      def generated_private_key
        @generated_key ||= OpenSSL::PKey::RSA.generate(2048)
      end

      def generated_public_key
        generated_private_key.public_key.to_pem
      end

      def file_flags
        base_flags = File::CREAT|File::TRUNC|File::RDWR
        # Windows doesn't have symlinks, so it doesn't have NOFOLLOW
        if defined?(File::NOFOLLOW) && !Chef::Config[:follow_client_key_symlink]
          base_flags |= File::NOFOLLOW
        end
        base_flags
      end
    end
  end
end
