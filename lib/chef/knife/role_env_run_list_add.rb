#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: William Albenzi (<walbenzi@gmail.com>)
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
    class RoleEnvRunListAdd < Knife

      deps do
        require 'chef/role'
        require 'chef/json_compat'
      end

      banner "knife role env_run_list add [ROLE] [ENVIRONMENT] [ENTRY[,ENTRY]] (options)"

      option :after,
        :short => "-a ITEM",
        :long  => "--after ITEM",
        :description => "Place the ENTRY in the run list after ITEM"

      def add_to_env_run_list(role, entries, after=nil)
        if after
          nlist = []
          role.env_run_list.each do |entry| 
            nlist << entry
            if entry == after
              entries.each { |e| nlist << e }
            end
          end
          role.env_run_list.reset!(nlist)
        else
          entries.each { |e| role.env_run_list << e }
        end
      end

      def run
        role = Chef::Role.load(@name_args[0])
        if @name_args.size > 2
          # Check for nested lists and create a single plain one
          entries = @name_args[1..-1].map do |entry|
            entry.split(',').map { |e| e.strip }
          end.flatten
        else
          # Convert to array and remove the extra spaces
          entries = @name_args[1].split(',').map { |e| e.strip }
        end

        add_to_env_run_list(role, entries, config[:after])
        role.save
        config[:env_run_list] = true
        output(format_for_display(role))
      end

    end
  end
end
