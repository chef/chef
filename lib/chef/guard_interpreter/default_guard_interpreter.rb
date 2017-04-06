#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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

require "chef/mixin/shell_out"

class Chef
  class GuardInterpreter
    class DefaultGuardInterpreter
      include Chef::Mixin::ShellOut

      protected

      def initialize(command, opts)
        @command = command
        @command_opts = opts
      end

      public

      def evaluate
        shell_out_with_systems_locale(@command, @command_opts).status.success?
      # Timeout fails command rather than chef-client run, see:
      #   https://tickets.opscode.com/browse/CHEF-2690
      rescue Chef::Exceptions::CommandTimeout
        Chef::Log.warn "Command '#{@command}' timed out"
        false
      end
    end
  end
end
