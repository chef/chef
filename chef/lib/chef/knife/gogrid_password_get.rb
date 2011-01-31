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
    class GogridPasswordGet < Knife

      banner "knife gogrid password get (options)"

      option :id,
        :short => "-i password_id",
        :long => "--id password_id",
        :description => "ID of password",
	:proc => Proc.new { |f| f.to_s }


      option :address,
        :short => "-a IP_ADDRESS",
        :long => "--address IP_ADDRESS",
        :description => "The ip address of server"

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

        password_list = [ h.color('id', :bold), h.color('password', :bold), h.color('server id', :bold), h.color('server name', :bold) ]

	@test = (config[:id])
	
	connection.passwords.each do |p|
	  if p.server.nil?
		puts ""
	  else
	    if p.server['id'].to_s == @test
          	  password_list << p.password_id.to_s
          	  password_list << p.password
		  @root_passwd = p.password
		  puts @root_passwd
          	if p.server.nil?
            	  password_list << "unknown"
          	else
            	  password_list << p.server['id'].to_s
            	  password_list << p.server['name'].to_s
          	end
	    end
	  end
        end

	puts config[:id]
	puts @root_passwd

	@public_ip = (config[:address])
	puts @public_ip

        puts password_list

      end
    end
  end
end
