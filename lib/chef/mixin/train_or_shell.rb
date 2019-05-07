#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2018, Chef Software Inc.
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

require "ostruct"
require "chef/mixin/shell_out"
require "chef/mixin/powershell_out"
require "chef/config"

class Chef
  module Mixin
    module TrainOrShell

      include Chef::Mixin::ShellOut
      include Chef::Mixin::PowershellOut

      def train_or_shell(*args, **opts)
        if Chef::Config.target_mode?
          result = run_context.transport_connection.run_command(args)
          train_to_shellout_result(result.stdout, result.stderr, result.exit_status)
        else
          shell_out(*args, opts)
        end
      end

      def train_or_shell!(*args, **opts)
        if Chef::Config.target_mode?
          result = run_context.transport_connection.run_command(*args)
          raise Mixlib::ShellOut::ShellCommandFailed, "Unexpected exit status of #{result.exit_status} running #{args}" if result.exit_status != 0
          train_to_shellout_result(result.stdout, result.stderr, result.exit_status)
        else
          shell_out!(*args, opts)
        end
      end

      def train_or_powershell(*args, **opts)
        if Chef::Config.target_mode?
          run_context.transport_connection.run_command(args)
          train_to_shellout_result(result.stdout, result.stderr, result.exit_status)
        else
          powershell_out(*args)
        end
      end

      def train_or_powershell!(*args, **opts)
        if Chef::Config.target_mode?
          result = run_context.transport_connection.run_command(args)
          raise Mixlib::ShellOut::ShellCommandFailed, "Unexpected exit status of #{result.exit_status} running #{args}" if result.exit_status != 0
          train_to_shellout_result(result.stdout, result.stderr, result.exit_status)
        else
          powershell_out!(*args)
        end
      end

      private

      #
      # Train #run_command returns a Train::Extras::CommandResult which
      # includes `exit_status` but Mixlib::Shellout returns exitstatus
      # This wrapper makes the result look like Mixlib::ShellOut to make it
      # easier to swap providers from #shell_out to #train_or_shell
      #
      def train_to_shellout_result(stdout, stderr, exit_status)
        status = OpenStruct.new(success?: ( exit_status == 0 ))
        OpenStruct.new(stdout: stdout, stderr: stderr, exitstatus: exit_status, status: status)
      end
    end
  end
end
