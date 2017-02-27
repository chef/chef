#
# Author:: Phil Dibowitz (<phild@fb.com>)
# Copyright:: Copyright 2013-2016, Facebook
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
    class WhyrunSafeRubyBlock < Chef::Provider::RubyBlock
      provides :whyrun_safe_ruby_block

      def action_run
        new_resource.block.call
        new_resource.updated_by_last_action(true)
        @run_context.events.resource_update_applied(new_resource, :create, "execute the whyrun_safe_ruby_block #{new_resource.name}")
        Chef::Log.info("#{new_resource} called")
      end
    end
  end
end
