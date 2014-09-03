#
# Author:: Chris Doherty <cdoherty@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef, Inc.
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

require 'chef/log'
require 'chef/provider'

if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require 'win32/registry'
end

# require 'chef/mixin/shell_out'
# require 'chef/mixin/command'

class Chef
  class Provider
    class Reboot < Chef::Provider

      # TODO: support whyrun?

      def load_current_resource
        @current_resource ||= Chef::Resource::Reboot.new(@new_resource.name)
        @current_resource.reason(@new_resource.reason)
        @current_resource.delay_mins(@new_resource.delay_mins)
        @current_resource.timestamp(@new_resource.timestamp)
        @current_resource
      end

      def action_request
        Chef::Log.warn "Reboot requested:'#{@new_resource.name}'"
        node.run_context.request_reboot(
          :delay_mins => @new_resource.delay_mins,
          :reason => @new_resource.reason,
          :timestamp => Time.now,
          :requested_by => @new_resource.name
        )
      end

      def action_cancel
        Chef::Log.warn "Reboot canceled: '#{@new_resource.name}'"
        node.run_context.cancel_reboot
      end
    end
  end
end
