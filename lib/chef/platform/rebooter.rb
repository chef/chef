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

require "chef/dsl/reboot_pending"
require "chef/log"
require "chef/platform"
require "chef/application/exit_code"

class Chef
  class Platform
    module Rebooter
      extend Chef::Mixin::ShellOut

      class << self

        include Chef::DSL::RebootPending

        def reboot!(node)
          reboot_info = node.run_context.reboot_info

          cmd = if Chef::Platform.windows?
                  # should this do /f as well? do we then need a minimum delay to let apps quit?
                  # Use explicit path to shutdown.exe, to protect against https://github.com/chef/chef/issues/5594
                  windows_shutdown_path = "#{ENV['SYSTEMROOT']}/System32/shutdown.exe"
                  "#{windows_shutdown_path} /r /t #{reboot_info[:delay_mins] * 60} /c \"#{reboot_info[:reason]}\""
                else
                  # probably Linux-only.
                  "shutdown -r +#{reboot_info[:delay_mins]} \"#{reboot_info[:reason]}\""
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
