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

require 'socket'
require 'chef/knife'
require 'json'

class Chef
  class Knife
    class RackspaceServerCreate < Knife

      banner "knife rackspace server create [RUN LIST...] (options)"

      attr_accessor :initial_sleep_delay

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server",
        :proc => Proc.new { |f| f.to_i },
        :default => 51

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

      def h
        @highline ||= HighLine.new
      end

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run 
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        $stdout.sync = true

        connection = Fog::Rackspace::Compute.new(
          :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
          :rackspace_username => Chef::Config[:knife][:rackspace_username] 
        )

        server = connection.servers.create(
          :image_id => config[:image],
          :flavor_id => config[:flavor],
          :name => config[:server_name]
        )

        puts "#{h.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{h.color("Flavor", :cyan)}: #{server.flavor_id}"
        puts "#{h.color("Image", :cyan)}: #{server.image_id}"
        puts "#{h.color("Name", :cyan)}: #{server.name}"
        puts "#{h.color("Public Address", :cyan)}: #{server.addresses["public"]}"
        puts "#{h.color("Private Address", :cyan)}: #{server.addresses["private"]}"
        puts "#{h.color("Password", :cyan)}: #{server.password}"

        print "\n#{h.color("Waiting for server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }

        puts("\n")

        print "\n#{h.color("Waiting for sshd", :magenta)}"

        print(".") until tcp_test_ssh(server.addresses["public"][0]) { sleep @initial_sleep_delay ||= 10; puts("done") }


        bootstrap_for_node(server).run

        puts "\n"
        puts "#{h.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{h.color("Flavor", :cyan)}: #{server.flavor_id}"
        puts "#{h.color("Image", :cyan)}: #{server.image_id}"
        puts "#{h.color("Name", :cyan)}: #{server.name}"
        puts "#{h.color("Public Address", :cyan)}: #{server.addresses["public"]}"
        puts "#{h.color("Private Address", :cyan)}: #{server.addresses["private"]}"
        puts "#{h.color("Password", :cyan)}: #{server.password}"
      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = server.addresses["public"]
        bootstrap.config[:run_list] = @name_args
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_password] = "#{server.password}"
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = "#{server.id}"
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:distro] = config[:distro]
        bootstrap.config[:use_sudo] = true
        bootstrap.config[:template_file] = config[:template_file]
        bootstrap
      end
    end
  end
end

