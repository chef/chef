#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: William Albenzi (<walbenzi@gmail.com>)
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
    class RoleEnvRunListAdd < Knife

      deps do
        require "chef/role" unless defined?(Chef::Role)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife role env_run_list add [ROLE] [ENVIRONMENT] [ENTRY [ENTRY]] (options)"

      option :after,
        short: "-a ITEM",
        long: "--after ITEM",
        description: "Place the ENTRY in the run list after ITEM."

      def add_to_env_run_list(role, environment, entries, after = nil)
        if after
          nlist = []
          unless role.env_run_lists.key?(environment)
            role.env_run_lists_add(environment => nlist)
          end
          role.run_list_for(environment).each do |entry|
            nlist << entry
            if entry == after
              entries.each { |e| nlist << e }
            end
          end
          role.env_run_lists_add(environment => nlist)
        else
          nlist = []
          unless role.env_run_lists.key?(environment)
            role.env_run_lists_add(environment => nlist)
          end
          role.run_list_for(environment).each do |entry|
            nlist << entry
          end
          entries.each { |e| nlist << e }
          role.env_run_lists_add(environment => nlist)
        end
      end

      def run
        role = Chef::Role.load(@name_args[0])
        role.name(@name_args[0])
        environment = @name_args[1]

        if @name_args.size > 2
          # Check for nested lists and create a single plain one
          entries = @name_args[2..].map do |entry|
            entry.split(",").map(&:strip)
          end.flatten
        else
          # Convert to array and remove the extra spaces
          entries = @name_args[2].split(",").map(&:strip)
        end

        add_to_env_run_list(role, environment, entries, config[:after])
        role.save
        config[:env_run_list] = true
        output(format_for_display(role))
      end

    end
  end
end
