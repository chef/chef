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

require 'chef/dsl/reboot_pending'
require 'chef/log'
require 'chef/platform'

class Chef
  class Platform
    module Rebooter
      extend Chef::Mixin::ShellOut

      class << self

        def reboot!(node)
          reboot_info = node.run_context.reboot_info

          cmd = if Chef::Platform.windows?
            # should this do /f as well? do we then need a minimum delay to let apps quit?
            "shutdown /r /t #{reboot_info[:delay_mins]*60} /c \"#{reboot_info[:reason]}\""
          else
            # probably Linux-only.
            "shutdown -r +#{reboot_info[:delay_mins]} \"#{reboot_info[:reason]}\""
          end

          Chef::Log.warn "Rebooting server at a recipe's request. Details: #{reboot_info.inspect}"
          shell_out!(cmd)
        end

        # this is a wrapper function so Chef::Client only needs a single line of code.
        def reboot_if_needed!(node)
          if node.run_context.reboot_requested?
            reboot!(node)
          end
        end
      end
    end
  end
end
