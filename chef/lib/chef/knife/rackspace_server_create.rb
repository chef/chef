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
require 'json'

class Chef
  class Knife
    class RackspaceServerCreate < Knife

      banner "knife rackspace server create [RUN LIST...] (options)"

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server",
        :proc => Proc.new { |f| f.to_i },
        :default => 1

      option :image,
        :short => "-i IMAGE",
        :long => "--image IMAGE",
        :description => "The image of the server",
        :proc => Proc.new { |i| i.to_i },
        :default => 14362

      option :server_name,
        :short => "-N NAME",
        :long => "--server-name NAME",
        :description => "The server name",
        :default => "wtf"

      option :api_key,
        :short => "-K KEY",
        :long => "--rackspace-api-key KEY",
        :description => "Your rackspace API key",
        :proc => Proc.new { |key| Chef::Config[:knife][:rackspace_api_key] = key } 

      option :api_username,
        :short => "-A USERNAME",
        :long => "--rackspace-api-username USERNAME",
        :description => "Your rackspace API username",
        :proc => Proc.new { |username| Chef::Config[:knife][:rackspace_api_username] = username } 

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root" 

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "ubuntu10.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :default => false

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        connection = Fog::Rackspace::Servers.new(
          :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
          :rackspace_username => Chef::Config[:knife][:rackspace_api_username] 
        )

        server = connection.servers.new
       
        server.flavor_id = config[:flavor]
        server.image_id = config[:image]
        server.name = config[:server_name]

        server.save

        $stdout.sync = true

        puts "#{h.color("Name", :cyan)}: #{server.name}"
        puts "#{h.color("Flavor", :cyan)}: #{server.flavor_id}"
        puts "#{h.color("Image", :cyan)}: #{server.image_id}"
        puts "#{h.color("Public Address", :cyan)}: #{server.addresses["public"]}"
        puts "#{h.color("Private Address", :cyan)}: #{server.addresses["private"]}"
        puts "#{h.color("Password", :cyan)}: #{server.password}"
     
        print "\n#{h.color("Requesting server", :magenta)}"
        saved_password = server.password

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }

        puts "\nServer ready, waiting 15 seconds to bootstrap."
        sleep 15

        puts "\nBootstrapping #{h.color(server.name, :bold)}..."

	begin
          bootstrap = Chef::Knife::Bootstrap.new
          bootstrap.name_args = [server.addresses["public"][0]]
          bootstrap.config[:run_list] = @name_args
          bootstrap.config[:ssh_user] = config[:ssh_user]
          bootstrap.config[:ssh_password] = saved_password
          bootstrap.config[:chef_node_name] = server.name
          bootstrap.config[:prerelease] = config[:prerelease]
          bootstrap.config[:distro] = config[:distro]
          bootstrap.config[:use_sudo] = false
          bootstrap.config[:template_file] = config[:template_file]
          bootstrap.run
        rescue Errno::ECONNREFUSED
          puts h.color("Connection refused on SSH, retrying - CTRL-C to abort")
          sleep 1
          retry
        rescue Errno::ETIMEDOUT
          puts h.color("Connection timed out on SSH, retrying - CTRL-C to abort")
          sleep 1
          retry
        end

      end
    end
  end
end


