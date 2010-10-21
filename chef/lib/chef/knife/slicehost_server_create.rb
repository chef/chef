#
# Author:: Ian Meyer (<ianmmeyer@gmail.com>)
# Author:: Sean OMeara (<someara@gmail.com>)
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
    class SlicehostServerCreate < Knife

      banner "knife slicehost server create [RUN LIST...] (options)"

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
        :default => 49

      option :server_name,
        :short => "-N NAME",
        :long => "--server-name NAME",
        :description => "The server name",
        :default => "wtf"

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "ubuntu10.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :default => false

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :slicehost_password,
        :short => "-K KEY",
        :long => "--slicehost_password",
        :description => "Your slicehost API password",
        :proc => Proc.new { |password| Chef::Config[:knife][:slicehost_password] = password } 

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        connection = Fog::Slicehost::Compute.new(
          :slicehost_password => Chef::Config[:knife][:slicehost_password]
        )

        server =  connection.servers.create(
            :image_id => config[:image],
            :flavor_id => config[:flavor],
            :name => config[:server_name]
        )

        $stdout.sync = true

        puts "#{h.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{h.color("Flavor", :cyan)}: #{server.flavor_id}"
        puts "#{h.color("Image", :cyan)}: #{server.image_id}"
        puts "#{h.color("Name", :cyan)}: #{server.name}"
        puts "#{h.color("Public Address", :cyan)}: #{server.addresses[0]}"
        puts "#{h.color("Private Address", :cyan)}: #{server.addresses[1]}"
        puts "#{h.color("Password", :cyan)}: #{server.password}"
     
        print "\n#{h.color("Waiting for server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }
        puts "#{h.color("\nWaiting 10 seconds for SSH Host Key generation on", :magenta)}: #{server.name}"
        sleep 10

        begin
          bootstrap = Chef::Knife::Bootstrap.new
          bootstrap.name_args = server.addresses[0]
          bootstrap.config[:run_list] = @name_args
          bootstrap.config[:ssh_user] = config[:ssh_user]
          bootstrap.config[:ssh_password] = "#{server.password}"
          bootstrap.config[:identity_file] = config[:identity_file]
          bootstrap.config[:chef_node_name] = "#{server.id}"
          bootstrap.config[:prerelease] = config[:prerelease]
          bootstrap.config[:distro] = config[:distro]
          bootstrap.config[:use_sudo] = true
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

        puts "\n"
        puts "\nServer ready!"

      end
    end
  end
end


