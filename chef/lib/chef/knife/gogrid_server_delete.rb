#
# Author:: Steve Lum (<steve.lum@gmail.com>)
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
require 'json'

class Chef
  class Knife
    class GogridServerDelete < Knife

      banner "knife gogrid server delete SERVER (options)"

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        connection = Fog::GoGrid::Compute.new(
          :go_grid_api_key => Chef::Config[:knife][:go_grid_api_key],
          :go_grid_shared_secret => Chef::Config[:knife][:go_grid_shared_secret]
        )

        server = connection.servers.get(@name_args[0])

        confirm("Do you really want to delete server ID #{server.id} named #{server.name}")

        server.destroy

        Chef::Log.warn("Deleted server #{server.id} named #{server.name}")
      end
    end
  end
end




