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
#

class Chef
  module Compliance
    # InSpec is only needed when the Compliance Phase runs, so it is loaded on
    # demand rather than with chef/client. Loading it runs
    # inspec/utils/licensing_config.rb, which reconfigures the process-wide
    # ChefLicensing settings for InSpec (product, entitlement, executable,
    # server URL, logger). Snapshot that configuration and restore it so the
    # client keeps its own settings for the rest of the process.
    def self.load_inspec!
      return if defined?(::Inspec::Runner)

      require "chef-licensing"
      config = ChefLicensing::Config
      saved = config.instance_variables.to_h { |iv| [iv, config.instance_variable_get(iv)] }
      begin
        require "inspec"
      ensure
        (config.instance_variables - saved.keys).each { |iv| config.remove_instance_variable(iv) }
        saved.each { |iv, value| config.instance_variable_set(iv, value) }
      end
    end
  end
end
