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
    class GogridPasswordList < Knife

      banner "knife gogrid password list (options)"

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

        #passwords = connection.passwords.inject({}) { |h,i| h[i.id] = i.password_id; h }
	#servers  = connection.servers.inject({}) { |h,i| h[i.id] = i.description; h }

        password_list = [ h.color('id', :bold), h.color('password', :bold), h.color('server id', :bold), h.color('server name', :bold) ]

        connection.passwords.each do |p| 
          password_list << p.password_id.to_s
          password_list << p.password
          if p.server.nil?
            password_list << "unknown"
          else
            password_list << p.server['id'].to_s
            password_list << p.server['name'].to_s
          end
        end     

	#connection.servers.each do |server|
        #  server_list << server.id.to_s
        #  server_list << server.name
        #end

        puts h.list(password_list, :columns_across, 4)

        #puts password_list

      end
    end
  end
end
