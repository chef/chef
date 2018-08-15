#
# Author:: Cary Penniman (<cary@rightscale.com>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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
  class Provider
    class Log
      # Chef log provider, allows logging to chef's logs
      class ChefLog < Chef::Provider
        provides :log

        # No concept of a 'current' resource for logs, this is a no-op
        #
        # @return [true] Always returns true
        def load_current_resource
          true
        end

        # Write the log to Chef's log
        #
        # @return [true] Always returns true
        def action_write
          logger.send(new_resource.level, new_resource.message)
          new_resource.updated_by_last_action(true) if Chef::Config[:count_log_resource_updates]
        end
      end
    end
  end
end
