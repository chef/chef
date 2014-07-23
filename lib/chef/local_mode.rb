#
# Author:: John Keiser (<jkeiser@getchef.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'chef/config'

class Chef
  module LocalMode
    # Create a chef local server (if the configuration requires one) for the
    # duration of the given block.
    #
    #     # This ...
    #     with_server_connectivity { stuff }
    #
    #     # Is exactly equivalent to this ...
    #     Chef::LocalMode.setup_server_connectivity
    #     begin
    #       stuff
    #     ensure
    #       Chef::LocalMode.destroy_server_connectivity
    #     end
    #
    def self.with_server_connectivity
      setup_server_connectivity
      begin
        yield
      ensure
        destroy_server_connectivity
      end
    end

    # If Chef::Config.chef_zero.enabled is true, sets up a chef-zero server
    # according to the Chef::Config.chef_zero and path options, and sets
    # chef_server_url to point at it.
    def self.setup_server_connectivity
      if Chef::Config.chef_zero.enabled
        destroy_server_connectivity

        require 'chef_zero/server'
        require 'chef/chef_fs/chef_fs_data_store'
        require 'chef/chef_fs/config'

        chef_fs = Chef::ChefFS::Config.new.local_fs
        chef_fs.write_pretty_json = true
        data_store = Chef::ChefFS::ChefFSDataStore.new(chef_fs)
        server_options = {}
        server_options[:data_store] = data_store
        server_options[:log_level] = Chef::Log.level
        server_options[:host] = Chef::Config.chef_zero.host
        server_options[:port] = parse_port(Chef::Config.chef_zero.port)
        @chef_zero_server = ChefZero::Server.new(server_options)
        @chef_zero_server.start_background
        Chef::Log.info("Started chef-zero at #{@chef_zero_server.url} with #{chef_fs.fs_description}")
        Chef::Config.chef_server_url = @chef_zero_server.url
      end
    end

    # Return the current chef-zero server set up by setup_server_connectivity.
    def self.chef_zero_server
      @chef_zero_server
    end

    # If chef_zero_server is non-nil, stop it and remove references to it.
    def self.destroy_server_connectivity
      if @chef_zero_server
        @chef_zero_server.stop
        @chef_zero_server = nil
      end
    end

    def self.parse_port(port)
      if port.is_a?(String)
        parts = port.split(',')
        if parts.size == 1
          a,b = parts[0].split('-',2)
          if b
            a.to_i.upto(b.to_i)
          else
            [ a.to_i ]
          end
        else
          array = []
          parts.each do |part|
            array += parse_port(part).to_a
          end
          array
        end
      else
        port
      end
    end
  end
end
