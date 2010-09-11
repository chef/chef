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
    class BlueboxServerCreate < Knife

      banner "knife bluebox server create [RUN LIST...] (options)"

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server",
        :default => "94fd37a7-2606-47f7-84d5-9000deda52ae"

      option :image,
        :short => "-i IMAGE",
        :long => "--image IMAGE",
        :description => "The image of the server",
        :default => "03807e08-a13d-44e4-b011-ebec7ef2c928"

      option :username,
        :short => "-U KEY",
        :long => "--username username",
        :description => "Username on new server",
		:default => "deploy"

      option :password,
        :short => "-P password",
        :long => "--password password",
        :description => "User password on new server",
		:default => ""

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        bluebox = Fog::Bluebox.new(
		  :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

 		flavors = bluebox.flavors.inject({}) { |h,f| h[f.id] = f.description; h }
  		images  = bluebox.images.inject({}) { |h,i| h[i.id] = i.description; h }

		puts "#{h.color("Deploying a new Blue Box Block...", :green)}\n\n"
		server_args = {
			:flavor_id => config[:flavor],
			:image_id => config[:image],
			:user => config[:username],
			:password => config[:password]
			}
		server_args[:ssh_key] = Chef::Config[:knife][:ssh_key] if Chef::Config[:knife][:ssh_key]
        server = bluebox.servers.new(server_args)
		response = server.save
        $stdout.sync = true
        
        # Wait for the server to start
		begin

			# Make sure we could properly queue the server for creation on BBG.
			raise Fog::Bluebox::BlockInstantiationError if server.status != "queued"
			puts "#{h.color("Hostname", :cyan)}: #{server.hostname}"
			puts "#{h.color("Server Status", :cyan)}: #{server.status.capitalize}"
        	puts "#{h.color("Flavor", :cyan)}: #{flavors[server.flavor_id]}"
        	puts "#{h.color("Image", :cyan)}: #{images[server.image_id]}"
			puts "#{h.color("IP Address", :cyan)}: #{server.ips[0]['address']}"
    
    		# The server was succesfully queued... Now wait for it to spin up...
        	print "\n#{h.color("Requesting status of #{server.hostname}\n", :magenta)}"

			# Allow for 5 minutes to time out...
			# ready? will raise Fog::Bluebox::BlockInstantiationError if block creation fails.
			unless server.wait_for( 5 * 60 ){ print "."; STDOUT.flush; ready? }

				# The server wasn't started in 5 minutes... Send a destroy call to make sure it doesn't spin up on us later...
				server.destroy
				raise Fog::Bluebox::BlockInstantiationError, "BBG server not available after 5 minutes" 

			else
				puts "\n\n#{h.color("BBG Server startup succesful.  Accessible at #{server.hostname}", :green)}"
			end 

		rescue Fog::Bluebox::BlockInstantiationError => e

			puts "\n\n#{h.color("Encountered error starting up BBG block. Auto destroy called.  Please try again.", :red)}"

		end
      
      end
    end
  end
end
