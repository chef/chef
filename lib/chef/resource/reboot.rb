#
# Author:: Chris Doherty <cdoherty@chef.io>)
# Copyright:: Copyright 2014-2016, Chef, Inc.
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

require "chef/resource"

# In using this resource via notifications, it's important to *only* use
# immediate notifications. Delayed notifications produce unintuitive and
# probably undesired results.
class Chef
  class Resource
    class Reboot < Chef::Resource
      allowed_actions :request_reboot, :reboot_now, :cancel

      def initialize(name, run_context = nil)
        super
        @provider = Chef::Provider::Reboot

        @reason = "Reboot by Chef"
        @delay_mins = 0

        # no default action.
      end

      def reason(arg = nil)
        set_or_return(:reason, arg, :kind_of => String)
      end

      def delay_mins(arg = nil)
        set_or_return(:delay_mins, arg, :kind_of => Integer)
      end
    end
  end
end
