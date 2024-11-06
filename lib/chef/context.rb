# freeze_string_literal: true
#
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

require_relative "licensing_config"

class Chef
  class Context
    class << self
      # The test kitchen will generate a nonce and sign it with a secret key.
      # All these details are written to a file in the temp directory with the same name as the secret key.
      # The file looks like:
      # nonce:<nonce>
      # timestamp:<timestamp>
      # signature:<signature>
      #
      # The nonce is valid for 60 seconds from the time it was generated.
      # The secret key will be passed to chef-infra client through env variable.
      #
      # This method reads the file and verifies the nonce, timestamp and signature.
      # If the received timestamp is within 60 seconds of the current time and the signature is valid
      # this confirms that the execution is initiated from the test-kitchen.
      def test_kitchen_context?
        return @context unless @context.nil?

        @context = false
        return @context if context_secret.nil? || context_secret.empty?

        if File.exist?(signed_file_path)
          # Read the nonce, timestamp and signature from the file
          received_nonce, received_timestamp, received_signature = read_file_content
          current_time = Time.now.utc.to_i
          # Check if the nonce is within 60 seconds of the current time
          if (current_time - received_timestamp.to_i).abs < 60
            if expected_signature(received_nonce, received_timestamp) == received_signature
              @context = true
            end
          end
          # Delete the file after reading the content
          File.delete(signed_file_path)
        end

        @context
      end

      # This method will switch the license entitlement to Chef Workstation entitlement.
      def switch_to_workstation_entitlement
        puts "Running under Test-Kitchen: Switching License to Chef Workstation entitlement"
        ChefLicensing.configure do |config|
          # Reset entitlement ID to the ID of Chef Workstation
          config.chef_entitlement_id = Chef::LicensingConfig::WORKSTATION_ENTITLEMENT_ID
        end
      end

      private

      # The secret key is passed as an environment variable to the chef-infra client.
      def context_secret
        ENV.fetch("TEST_KITCHEN_CONTEXT", "")
      end

      # The file contains the nonce, timestamp and signature which are written by the test-kitchen.
      def signed_file_path
        "#{Dir.tmpdir}/kitchen/#{context_secret}"
      end

      # Reads the file and return the nonce, timestamp and signature
      def read_file_content
        file_content = {}
        File.open(signed_file_path, "r:bom|utf-16le:utf-8") do |file|
          file.each_line do |line|
            key, value = line.strip.split(":")
            file_content[key] = value
          end
        end

        [file_content["nonce"], file_content["timestamp"], file_content["signature"]]
      end

      # Generate the signature using the nonce and timestamp and the received secret key
      def expected_signature(nonce, timestamp)
        message = "#{nonce}:#{timestamp}"
        OpenSSL::HMAC.hexdigest("SHA256", context_secret, message)
      end

      def reset_context
        @context = nil
      end
    end
  end
end