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
    class ClientDelete < Knife

      deps do
        require "chef/api_client_v1" unless defined?(Chef::ApiClientV1)
      end

      option :delete_validators,
        short: "-D",
        long: "--delete-validators",
        description: "Force deletion of client if it's a validator."

      banner "knife client delete [CLIENT [CLIENT]] (options)"

      def run
        if @name_args.length == 0
          show_usage
          ui.fatal("You must specify at least one client name")
          exit 1
        end

        @name_args.each do |client_name|
          delete_client(client_name)
        end
      end

      def delete_client(client_name)
        delete_object(Chef::ApiClientV1, client_name, "client") do
          object = Chef::ApiClientV1.load(client_name)
          if object.validator
            unless config[:delete_validators]
              ui.fatal("You must specify --delete-validators to delete the validator client #{client_name}")
              exit 2
            end
          end
          object.destroy
        end
      end
    end
  end
end
