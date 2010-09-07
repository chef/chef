#
# Author:: Jesse Proudman (<jesse.proudman@blueboxgrp.com>)
# Copyright:: Copyright (c) 2010 Blue Box Group
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
    class BlueboxServerDelete < Knife

      banner "knife bluebox server delete BLOCK-HOSTNAME"
      
	  def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'
        require 'readline'
        
        bluebox = Fog::Bluebox.new(
		  :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )
      
        # Build hash of hostname => id  
        servers = bluebox.servers.inject({}) { |h,f| h[f.hostname] = f.id; h }

        unless servers.has_key?(@name_args[0])
          Chef::Log.warn("I can't find a block named #{@name_args[0]}")
          return false
        end
 
        confirm(h.color("Do you really want to delete block UUID #{servers[@name_args[0]]} with hostname #{@name_args[0]}", :green))

        begin
          response = bluebox.destroy_block(servers[@name_args[0]])
          if response.status == 200
            Chef::Log.warn("Deleted server #{servers[@name_args[0]]} named #{@name_args[0]}")
          end
        rescue Excon::Errors::UnprocessableEntity
          Chef::Log.warn("There was a problem deleting #{@name_args[0]}.  Please check Box Panel.")
        end
      end
    end
  end
end



