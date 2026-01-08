#
# Author:: Chris Doherty <cdoherty@chef.io>)
# Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../dsl/reboot_pending"
require_relative "../log"
require_relative "../platform"
require_relative "../application/exit_code"
require_relative "../mixin/shell_out"

class Chef
  class Platform
    module Rebooter
      extend Chef::Mixin::ShellOut

      class << self

        include Chef::DSL::RebootPending

        def reboot!(node)
          reboot_info = node.run_context.reboot_info

          cmd = case
                when ChefUtils.windows?
                  # should this do /f as well? do we then need a minimum delay to let apps quit?
                  # Use explicit path to shutdown.exe, to protect against https://github.com/chef/chef/issues/5594
                  windows_shutdown_path = "#{ENV["SYSTEMROOT"]}/System32/shutdown.exe"
                  "#{windows_shutdown_path} /r /t #{reboot_info[:delay_mins] * 60} /c \"#{reboot_info[:reason]}\""
                when node["os"] == "solaris2"
                  # SysV-flavored shutdown
                  "shutdown -i6 -g#{reboot_info[:delay_mins]} -y \"#{reboot_info[:reason]}\" &"
                else
                  # Linux/BSD/Mac/AIX and other systems with BSD-ish shutdown
                  "shutdown -r +#{reboot_info[:delay_mins]} \"#{reboot_info[:reason]}\" &"
                end

          msg = "Rebooting server at a recipe's request. Details: #{reboot_info.inspect}"
          begin
            Chef::Log.warn msg
            shell_out!(cmd)
          rescue Mixlib::ShellOut::ShellCommandFailed => e
            raise Chef::Exceptions::RebootFailed.new(e.message)
          end

          raise Chef::Exceptions::Reboot.new(msg)
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
