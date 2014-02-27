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
    class ClientDelete < Knife

      deps do
        require 'chef/api_client'
        require 'chef/json_compat'
      end

      option :force,
       :short => "-f",
       :long => "--force",
       :description => "Force deletion of client if it's a validator"

      banner "knife client delete CLIENT (options)"

      def run
        @client_name = @name_args[0]

        if @client_name.nil?
          show_usage
          ui.fatal("You must specify a client name")
          exit 1
        end

        delete_object(Chef::ApiClient, @client_name, 'client') {
          object = Chef::ApiClient.load(@client_name)
          if object.validator
            unless config[:force]
              ui.fatal("You must specify --force to delete the validator client #{@client_name}")
              exit 2
            end
          end
          object.destroy
        }
      end

    end
  end
end
