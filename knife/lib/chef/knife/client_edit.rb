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
    class ClientEdit < Knife

      deps do
        require "chef/api_client_v1" unless defined?(Chef::ApiClientV1)
      end

      banner "knife client edit CLIENT (options)"

      def run
        @client_name = @name_args[0]

        if @client_name.nil?
          show_usage
          ui.fatal("You must specify a client name")
          exit 1
        end

        original_data = Chef::ApiClientV1.load(@client_name).to_h
        edited_client = edit_hash(original_data)
        if original_data != edited_client
          client = Chef::ApiClientV1.from_hash(edited_client)
          client.save
          ui.msg("Saved #{client}.")
        else
          ui.msg("Client unchanged, not saving.")
        end
      end
    end
  end
end
