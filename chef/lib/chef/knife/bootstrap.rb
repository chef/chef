#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'erubis'

class Chef
  class Knife
    class Bootstrap < Knife

      banner "knife bootstrap FQDN [RUN LIST...] (options)"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root" 

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "ubuntu10.04-gems"

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      def h
        @highline ||= HighLine.new
      end

      def load_template(template)
        # Are we bootstrapping using an already shipped template?
        bootstrap_files = []
        bootstrap_files << File.join(File.dirname(__FILE__), 'bootstrap', "#{config[:distro]}.erb")
        bootstrap_files << File.join(Dir.pwd, ".chef", "bootstrap", "#{config[:distro]}.erb")
        bootstrap_files << File.join(ENV['HOME'], '.chef', 'bootstrap', "#{config[:distro]}.erb")

        config[:bootstrap_template] = bootstrap_files.find do |bootstrap_template|
          Chef::Log.debug("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          File.exists?(bootstrap_template)
        end

        unless config[:bootstrap_template]
          Chef::Log.info("Can not find bootstrap definition for #{config[:distro]}")
          raise
        end

        Chef::Log.debug("Found bootstrap template in #{File.dirname(config[:bootstrap_template])}")
        
        config[:bootstrap_template]
      end

      def run 
        require 'highline'

        server_name = @name_args[0]

        $stdout.sync = true

        

        context = {}
        context[:run_list] = @name_args[1..-1]
        context[:config] = config
        command = Erubis::Eruby.new(template).evaluate(context)

        Chef::Log.info("Bootstrapping Chef on #{h.color(server_name, :bold)}")

        ssh = Chef::Knife::Ssh.new
        ssh.name_args = [ server_name, "sudo #{command}" ]
        ssh.config[:ssh_user] = config[:ssh_user] 
        ssh.config[:password] = config[:ssh_password]
        ssh.config[:identity_file] = config[:identity_file]
        ssh.config[:manual] = true

        begin
          ssh.run
        rescue Net::SSH::AuthenticationFailed
          unless config[:ssh_password]
            puts "Failed to authenticate #{config[:ssh_user]} - trying password auth"
            ssh = Chef::Knife::Ssh.new
            ssh.name_args = [ server_name, "sudo #{command}" ]
            ssh.config[:ssh_user] = config[:ssh_user] 
            ssh.config[:manual] = true
            ssh.config[:password] = ssh.get_password
            ssh.run
          end
        end

      end
    end
  end
end

