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

class Chef
  class Context
    class << self
      COMMON_KEY = "2f3b66cbbafa2d326b2856bccc4c8ebe"
      FILE_NAME = "c769508738d671db424b7442"

      def test_kitchen_context?
        return @context if defined?(@context)

        @context = false
        file_path = (ChefUtils.windows? ? Dir.tmpdir : "/tmp") + "/kitchen/#{FILE_NAME}"
        if File.exist?(file_path)
          file_content = {}
          File.open(file_path, "r:bom|utf-16le:utf-8") do |file|
            file.each_line do |line|
              key, value = line.strip.split(':')
              file_content[key] = value
            end
          end

          received_nonce = file_content['nonce']
          received_timestamp = file_content['timestamp']
          received_signature = file_content['signature']

          current_time = Time.now.utc.to_i
          if (current_time - received_timestamp.to_i).abs < 30
            message = "#{received_nonce}:#{received_timestamp}"
            expected_signature = OpenSSL::HMAC.hexdigest('SHA256', COMMON_KEY, message)
            if expected_signature == received_signature
              @context = true
            end
          end
          File.delete(TMP_FILE_PATH)
        end

        @context
      end

      def switch_to_workstation_entitlement
        puts "Running under Test-Kitchen: Switching License to Chef Workstation entitlement"
        ChefLicensing.configure do |config|
          # Reset entitlement ID to the ID of Chef Workstation
          config.chef_entitlement_id = "x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0"
        end
      end
    end
  end
end