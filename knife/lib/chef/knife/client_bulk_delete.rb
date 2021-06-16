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
    class ClientBulkDelete < Knife

      deps do
        require "chef/api_client_v1" unless defined?(Chef::ApiClientV1)
      end

      option :delete_validators,
        short: "-D",
        long: "--delete-validators",
        description: "Force deletion of clients if they're validators."

      banner "knife client bulk delete REGEX (options)"

      def run
        if name_args.length < 1
          ui.fatal("You must supply a regular expression to match the results against")
          exit 42
        end
        all_clients = Chef::ApiClientV1.list(true)

        matcher = /#{name_args[0]}/
        clients_to_delete = {}
        validators_to_delete = {}
        all_clients.each do |name, client|
          next unless name&.match?(matcher)

          if client.validator
            validators_to_delete[client.name] = client
          else
            clients_to_delete[client.name] = client
          end
        end

        if clients_to_delete.empty? && validators_to_delete.empty?
          ui.info "No clients match the expression /#{name_args[0]}/"
          exit 0
        end

        check_and_delete_validators(validators_to_delete)
        check_and_delete_clients(clients_to_delete)
      end

      def check_and_delete_validators(validators)
        unless validators.empty?
          unless config[:delete_validators]
            ui.msg("The following clients are validators and will not be deleted:")
            print_clients(validators)
            ui.msg("You must specify --delete-validators to delete the validator clients")
          else
            ui.msg("The following validators will be deleted:")
            print_clients(validators)
            if ui.confirm_without_exit("Are you sure you want to delete these validators")
              destroy_clients(validators)
            end
          end
        end
      end

      def check_and_delete_clients(clients)
        unless clients.empty?
          ui.msg("The following clients will be deleted:")
          print_clients(clients)
          ui.confirm("Are you sure you want to delete these clients")
          destroy_clients(clients)
        end
      end

      def destroy_clients(clients)
        clients.sort.each do |name, client|
          client.destroy
          ui.msg("Deleted client #{name}")
        end
      end

      def print_clients(clients)
        ui.msg("")
        ui.msg(ui.list(clients.keys.sort, :columns_down))
        ui.msg("")
      end
    end
  end
end
