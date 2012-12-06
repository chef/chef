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
    class ClientReregister < Knife

      deps do
        require 'chef/api_client'
        require 'chef/json_compat'
      end

      banner "knife client reregister CLIENT (options)"

      option :file,
        :short => "-f FILE",
        :long  => "--file FILE",
        :description => "Write the key to a file"

      def run
        @client_name = @name_args[0]

        if @client_name.nil?
          show_usage
          ui.fatal("You must specify a client name")
          exit 1
        end

        create_new_key=true
        client = Chef::ApiClient.load(@client_name)
        response = client.save(create_new_key)
        priv_key = if response.is_a? Hash
                     response['private_key']
                   elsif response.is_a? Chef::ApiClient
                     response.to_hash['private_key']
                   else
                     ui.fatal("Received an unknown response of class '#{response.class}' from server")
                     exit 1
                   end
        if config[:file]
          File.open(config[:file], "w") do |f|
            f.print(priv_key)
          end
        else
          ui.msg priv_key
        end
      end
    end
  end
end
