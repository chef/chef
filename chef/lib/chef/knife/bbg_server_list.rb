#
# Author:: Jim Van Fleet (<jim@itsbspoke.com>)
# Copyright:: Copyright (c) 2010 it's bspoke, LLC.
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
require 'tempfile'

class Chef
  class Knife
    class BbgServerList < Knife

      banner "knife bbg server list (options)"

      option :bluebox_customer_id,
        :short => "-I CUSTOMER_ID",
        :long => "--blue_box_customer_id CUSTOMER_ID",
        :description => "Your BlueBox Group customer id",
        :proc => Proc.new { |id| Chef::Config[:knife][:bluebox_customer_id] = id } 

      option :bluebox_api_key,
        :short => "-K API_KEY",
        :long => "--blue_box_api_key API_KEY",
        :description => "Your BlueBox API Key",
        :proc => Proc.new { |key| Chef::Config[:knife][:bluebox_api_key] = key } 

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'

        server_name = @name_args[0]

        bbg = Fog::Bluebox.new(
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key],
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id]
        )

        $stdout.sync = true

        server_list = [ h.color('ID', :bold), h.color('Name', :bold) ]
        bbg.servers.all.each do |server|
          server_list << server.id.to_s
          server_list << server.hostname
        end
        puts h.list(server_list, :columns_across, 2)

      end
    end
  end
end


