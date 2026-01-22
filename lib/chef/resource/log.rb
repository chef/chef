#
# Author:: Cary Penniman (<cary@rightscale.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require_relative "../resource"

class Chef
  class Resource
    # @example logging at default info level
    #   log "your string to log"
    #
    # @example logging at specified debug level
    #   log "a debug string" do
    #     level :debug
    #   end
    class Log < Chef::Resource

      provides :log, target_mode: true
      target_mode support: :full,
        introduced: "15.1"

      description "Use the **log** resource to create log entries. The log resource behaves" \
                  " like any other resource: built into the resource collection during the" \
                  " compile phase, and then run during the execution phase. (To create a log" \
                  " entry that is not built into the resource collection, use Chef::Log instead" \
                  " of the log resource.)"

      property :message, String,
        name_property: true, identity: true,
        description: "The message to be added to a log file. If not specified we'll use the resource's name instead."

      property :level, Symbol,
        equal_to: %i{debug info warn error fatal}, default: :info,
        description: "The logging level to display this message at."

      allowed_actions :write
      default_action :write

      def suppress_up_to_date_messages?
        true
      end

      # Write the log to Chef's log
      #
      # @return [true] Always returns true
      action :write do
        logger.send(new_resource.level, new_resource.message)
        new_resource.updated_by_last_action(true) if Chef::Config[:count_log_resource_updates]
      end
    end
  end
end
