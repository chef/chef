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
    class RoleRunListClear < Knife

      deps do
        require "chef/role" unless defined?(Chef::Role)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife role run_list clear [ROLE] (options)"
      def clear_env_run_list(role, environment)
        nlist = []
        role.env_run_lists_add(environment => nlist)
      end

      def run
        if @name_args.size > 2
          ui.fatal "You must not supply an environment run list."
          show_usage
          exit 1
        end
        role = Chef::Role.load(@name_args[0])
        role.name(@name_args[0])
        environment = "_default"

        clear_env_run_list(role, environment)
        role.save
        config[:env_run_list] = true
        output(format_for_display(role))
      end

    end
  end
end
