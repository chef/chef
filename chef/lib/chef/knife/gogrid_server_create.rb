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
    class GogridServerCreate < Knife

      banner "knife gogrid server create [RUN LIST...] (options)"

      option :address,
        :short => "-a IP_ADDRESS",
        :long => "--address IP_ADDRESS",
        :description => "The ip address of server"
#        :proc => Proc.new { |f| f.to_i },

      option :image,
        :short => "-i IMAGE",
        :long => "--image IMAGE",
        :description => "The image of the server"
#        :proc => Proc.new { |i| i.to_i },

      option :server_name,
        :short => "-N NAME",
        :long => "--server-name NAME",
        :description => "The server name"

      option :memory,
        :short => "-R RAM",
        :long => "--server-memory RAM",
        :description => "Server RAM amount",
        :default => "1GB"

      option :go_grid_api_key,
        :short => "-K KEY",
        :long => "--go-grid-api-key KEY",
        :description => "Your GoGrid API key",
        :proc => Proc.new { |key| Chef::Config[:knife][:go_grid_api_key] = key } 

      option :go_grid_shared_secret,
        :short => "-A USERNAME",
        :long => "--go-grid-shared-secret SHARED_SECRET",
        :description => "Your GoGrid API Shared Secret",
        :proc => Proc.new { |username| Chef::Config[:knife][:go_grid_shared_secret] = shared_secret} 

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "centos5-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :default => false

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

        connection = Fog::GoGrid::Compute.new(
          :go_grid_api_key => Chef::Config[:knife][:go_grid_api_key],
          :go_grid_shared_secret => Chef::Config[:knife][:go_grid_shared_secret] 
        )

	server = connection.grid_server_add( config[:image], config[:address], config[:server_name], config[:memory])

	server1_ip = config[:address]
	server1_image_id = config[:image]
	server1_name = config[:server_name]
	server1_memory = config[:memory]

	$stdout.sync = true

        puts "#{h.color("Hostname", :cyan)}: #{server1_name}"
        puts "#{h.color("IP Address", :cyan)}: #{server1_ip}"
        puts "#{h.color("Server Image", :cyan)}: #{server1_image_id}"
        puts "#{h.color("Amount of RAM", :cyan)}: #{server1_memory}"
        puts "#{h.color("Default Root Password", :cyan)}:  #{@root_passwd}"

        puts "\nBootstrapping #{h.color(server1_name, :bold)}..."

        print "\n#{h.color("Provisioning server at GoGrid", :magenta)}"

        # wait for it to be ready to do stuff
        #server.wait_for { print "."; ready? }

        puts("\n")
	sleep 30

        print "\n#{h.color("Waiting for sshd", :magenta)}"

        print(".") until tcp_test_ssh(server1_ip) { sleep @initial_sleep_delay ||= 10; puts("done") }

	connection.servers.each do |s|
	  if s.name == (config[:server_name])
		@server_id = s.id
	  end
	end

        connection.passwords.each do |p|
	  if p.server.nil?
		puts""
	  else
            if p.server['id'] == @server_id
                  @root_passwd = p.password
	    end
          end
        end

        bootstrap_for_node(server).run

        puts "#{h.color("Hostname", :cyan)}: #{server1_name}"
        puts "#{h.color("IP Address", :cyan)}: #{server1_ip}"
        puts "#{h.color("Server Image", :cyan)}: #{server1_image_id}"
        puts "#{h.color("Amount of RAM", :cyan)}: #{server1_memory}"
        puts "#{h.color("Default Root Password", :cyan)}:  #{@root_passwd}"

        puts "\nBootstrapping #{h.color(server1_name, :bold)}..."
      end

      def bootstrap_for_node(server)
	@public_ip = (config[:address])
	bootstrap = Chef::Knife::Bootstrap.new
	bootstrap.name_args = [ @public_ip ]
        bootstrap.config[:run_list] = @name_args
        bootstrap.config[:ssh_user] = "root"
        bootstrap.config[:ssh_password] = @root_passwd
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:server_name] || server.id
        bootstrap.config[:use_sudo] = false
        bootstrap.config[:distro] = config[:distro]
        bootstrap.config[:template_file] = config[:template_file]
        bootstrap.config[:environment] = config[:environment]
	bootstrap
      end
    end
  end
end
