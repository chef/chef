#
# Author:: Mike Fiedler (<miketheman@gmail.com>)
# Author:: William Albenzi (<walbenzi@gmail.com>)
# Copyright:: Copyright 2013-2016, Mike Fiedler
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
    class RoleRunListSet < Knife

      deps do
        require "chef/role" unless defined?(Chef::Role)
      end

      banner "knife role run_list set [ROLE] [ENTRIES] (options)"

      # Clears out any existing env_run_list_items and sets them to the
      # specified entries
      def set_env_run_list(role, environment, entries)
        nlist = []
        unless role.env_run_lists.key?(environment)
          role.env_run_lists_add(environment => nlist)
        end
        entries.each { |e| nlist << e }
        role.env_run_lists_add(environment => nlist)
      end

      def run
        role = Chef::Role.load(@name_args[0])
        role.name(@name_args[0])
        environment = "_default"
        if @name_args.size < 1
          ui.fatal "You must supply both a role name and an environment run list."
          show_usage
          exit 1
        elsif @name_args.size > 1
          # Check for nested lists and create a single plain one
          entries = @name_args[1..].map do |entry|
            entry.split(",").map(&:strip)
          end.flatten
        else
          # Convert to array and remove the extra spaces
          entries = @name_args[1].split(",").map(&:strip)
        end

        set_env_run_list(role, environment, entries )
        role.save
        config[:env_run_list] = true
        output(format_for_display(role))
      end

    end
  end
end
