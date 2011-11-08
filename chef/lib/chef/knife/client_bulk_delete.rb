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
    class ClientBulkDelete < Knife

      deps do
        require 'chef/api_client'
        require 'chef/json_compat'
      end

      banner "knife client bulk delete REGEX (options)"

      def run
        if name_args.length < 1
          ui.fatal("You must supply a regular expression to match the results against")
          exit 42
        end
        all_clients = Chef::ApiClient.list(true)

        matcher = /#{name_args[0]}/
        clients_to_delete = {}
        all_clients.each do |name, client|
          next unless name =~ matcher
          clients_to_delete[client.name] = client
        end

        if clients_to_delete.empty?
          ui.info "No clients match the expression /#{name_args[0]}/"
          exit 0
        end

        ui.msg("The following clients will be deleted:")
        ui.msg("")
        ui.msg(ui.list(clients_to_delete.keys.sort, :columns_down))
        ui.msg("")
        ui.confirm("Are you sure you want to delete these clients")

        clients_to_delete.sort.each do |name, client|
          client.destroy
          ui.msg("Deleted client #{name}")
        end
      end
    end
  end
end

