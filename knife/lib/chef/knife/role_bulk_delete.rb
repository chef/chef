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
    class RoleBulkDelete < Knife

      deps do
        require "chef/role" unless defined?(Chef::Role)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife role bulk delete REGEX (options)"

      def run
        if @name_args.length < 1
          ui.error("You must supply a regular expression to match the results against")
          exit 1
        end

        all_roles = Chef::Role.list(true)

        matcher = /#{@name_args[0]}/
        roles_to_delete = {}
        all_roles.each do |name, role|
          next unless name&.match?(matcher)

          roles_to_delete[role.name] = role
        end

        if roles_to_delete.empty?
          ui.info "No roles match the expression /#{@name_args[0]}/"
          exit 0
        end

        ui.msg("The following roles will be deleted:")
        ui.msg("")
        ui.msg(ui.list(roles_to_delete.keys.sort, :columns_down))
        ui.msg("")
        ui.confirm("Are you sure you want to delete these roles")

        roles_to_delete.sort.each do |name, role|
          role.destroy
          ui.msg("Deleted role #{name}")
        end
      end
    end
  end
end
