#
# Author:: Adam Edwards (<adamed@chef.io>)
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

require_relative "../mixin/shell_out"
require_relative "../exceptions"

class Chef
  class GuardInterpreter
    class DefaultGuardInterpreter
      include Chef::Mixin::ShellOut
      attr_reader :output

      def initialize(command, opts)
        @command = command
        @command_opts = opts
      end

      def evaluate
        result = shell_out(@command, default_env: false, **@command_opts)
        @output = "STDOUT: #{result.stdout}\nSTDERR: #{result.stderr}\n"
        Chef::Log.debug "Command failed: #{result.stderr}" unless result.status.success?
        result.status.success?
      # Timeout fails command rather than chef-client run, see:
      #   https://tickets.opscode.com/browse/CHEF-2690
      rescue Chef::Exceptions::CommandTimeout
        Chef::Log.warn "Command '#{@command}' timed out"
        false
      end
    end
  end
end
