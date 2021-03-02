#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../knife"

class Chef
  class Knife
    class RoleRunListRemove < Knife

      deps do
        require "chef/role" unless defined?(Chef::Role)
      end

      banner "knife role run_list remove [ROLE] [ENTRY] (options)"

      def remove_from_env_run_list(role, environment, item_to_remove)
        nlist = []
        role.run_list_for(environment).each do |entry|
          nlist << entry unless entry == item_to_remove
          # unless entry == @name_args[2]
          #  nlist << entry
          # end
        end
        role.env_run_lists_add(environment => nlist)
      end

      def run
        role = Chef::Role.load(@name_args[0])
        role.name(@name_args[0])
        environment = "_default"
        item_to_remove = @name_args[1]

        remove_from_env_run_list(role, environment, item_to_remove)
        role.save
        config[:env_run_list] = true
        output(format_for_display(role))
      end

    end
  end
end
