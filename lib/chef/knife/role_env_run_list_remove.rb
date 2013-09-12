#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    class RoleEnvRunListRemove < Knife

      deps do
        require 'chef/role'
        require 'chef/json_compat'
      end

      banner "knife role env_run_list remove [ROLE] [ENVIRONMENT] [ENTRIES] (options)"

      def run
        node = Chef::Role.load(@name_args[0])
        entries = @name_args[1].split(',')

        entries.each { |e| role.env_run_list.remove(e) }

        node.save

        config[:env_run_list] = true

        output(format_for_display(role))
      end

    end
  end
end

