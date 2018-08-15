#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

require "chef/knife"

class Chef
  class Knife
    class RoleShow < Knife

      include Knife::Core::MultiAttributeReturnOption

      deps do
        require "chef/role"
      end

      banner "knife role show ROLE (options)"

      def run
        @role_name = @name_args[0]

        if @role_name.nil?
          show_usage
          ui.fatal("You must specify a role name.")
          exit 1
        end

        role = Chef::Role.load(@role_name)
        output(format_for_display(config[:environment] ? role.environment(config[:environment]) : role))
      end

    end
  end
end
