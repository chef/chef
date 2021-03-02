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
    class ClientReregister < Knife

      deps do
        require "chef/api_client_v1" unless defined?(Chef::ApiClientV1)
      end

      banner "knife client reregister CLIENT (options)"

      option :file,
        short: "-f FILE",
        long: "--file FILE",
        description: "Write the key to a file."

      def run
        @client_name = @name_args[0]

        if @client_name.nil?
          show_usage
          ui.fatal("You must specify a client name")
          exit 1
        end

        client = Chef::ApiClientV1.reregister(@client_name)
        Chef::Log.trace("Updated client data: #{client.inspect}")
        key = client.private_key
        if config[:file]
          File.open(config[:file], "w") do |f|
            f.print(key)
          end
        else
          ui.msg key
        end
      end
    end
  end
end
