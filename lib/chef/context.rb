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
      def test_kitchen_context?
        return @context unless @context.nil?

        @context = false
        return @context if context_secret.nil? || context_secret.empty?

        if File.exist?(signed_file_path)
          # Read the nonce, timestamp and signature from the file
          received_nonce, received_timestamp, received_signature = read_file_content
          current_time = Time.now.utc.to_i
          # Check if the nonce is within 30 seconds of the current time
          if (current_time - received_timestamp.to_i).abs < 30
            if expected_signature(received_nonce, received_timestamp) == received_signature
              @context = true
            end
          end
          # Delete the file after reading the content
          File.delete(signed_file_path)
        end

        @context
      end

      def switch_to_workstation_entitlement
        puts "Running under Test-Kitchen: Switching License to Chef Workstation entitlement"
        ChefLicensing.configure do |config|
          # Reset entitlement ID to the ID of Chef Workstation
          config.chef_entitlement_id = Chef::LicensingConfig::WORKSTATION_ENTITLEMENT_ID
        end
      end

      private

      def context_secret
        ENV.fetch("TEST_KITCHEN_CONTEXT", "")
      end

      def signed_file_path
        "#{Dir.tmpdir}/kitchen/#{context_secret}"
      end

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