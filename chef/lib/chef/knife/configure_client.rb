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
    class ConfigureClient < Knife
      banner "Sub-Command: configure client DIRECTORY"

      def run
        raise ArgumentError, "You must provide the directory to put the files in" unless @name_args[0]
        Chef::Log.info("Creating client configuration")
        system("mkdir -p #{@name_args[0]}")
        Chef::Log.info("Writing client.rb")
        File.open(File.join(@name_args[0], "client.rb"), "w") do |file|
          file.puts('log_level        :info')
          file.puts('log_location     STDOUT')
          file.puts("chef_server_url  '#{Chef::Config[:chef_server_url]}'")
          file.puts("validation_client_name '#{Chef::Config[:validation_client_name]}'")
        end
        Chef::Log.info("Writing validation.pem")
        system("cp #{Chef::Config[:validation_key]} #{File.join(@name_args[0], 'validation.pem')}")
      end

    end
  end
end


