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
require 'erubis'

class Chef
  class Knife
    class Bootstrap < Knife

      deps do
        require 'chef/json_compat'
        require 'tempfile'
        require 'highline'
        require 'net/ssh'
        require 'net/ssh/multi'
        Chef::Knife::Ssh.load_deps
      end

      banner "knife bootstrap FQDN (options)"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

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

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => lambda { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "ubuntu10.04-gems"

      option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

      def load_template(template=nil)
        # Are we bootstrapping using an already shipped template?
        if config[:template_file]
          bootstrap_files = config[:template_file]
        else
          bootstrap_files = []
          bootstrap_files << File.join(File.dirname(__FILE__), 'bootstrap', "#{config[:distro]}.erb")
          bootstrap_files << File.join(Dir.pwd, ".chef", "bootstrap", "#{config[:distro]}.erb")
          bootstrap_files << File.join(ENV['HOME'], '.chef', 'bootstrap', "#{config[:distro]}.erb")
        end

        template = Array(bootstrap_files).find do |bootstrap_template|
          Chef::Log.debug("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          File.exists?(bootstrap_template)
        end

        unless template
          ui.info("Can not find bootstrap definition for #{config[:distro]}")
          raise Errno::ENOENT
        end

        Chef::Log.debug("Found bootstrap template in #{File.dirname(template)}")

        IO.read(template).chomp
      end

      def render_template(template=nil)
        context = {}
        context[:run_list] = config[:run_list]
        context[:config] = config
        Erubis::Eruby.new(template).evaluate(context)
      end

      def run

        validate_name_args!
        @node_name = Array(@name_args).first
        # back compat--templates may use this setting:
        config[:server_name] = @node_name

        $stdout.sync = true

        ui.info("Bootstrapping Chef on #{ui.color(@node_name, :bold)}")

        begin
          knife_ssh.run
        rescue Net::SSH::AuthenticationFailed
          unless config[:ssh_password]
            puts "Failed to authenticate #{config[:ssh_user]} - trying password auth"
            knife_ssh_with_password_auth.run
          end
        end
      end

      def validate_name_args!
        if Array(@name_args).first.nil?
          ui.error("Must pass an FQDN or ip to bootstrap")
          exit 1
        end
      end

      def server_name
        Array(@name_args).first
      end

      def knife_ssh
        ssh = Chef::Knife::Ssh.new
        ssh.name_args = [ server_name, ssh_command ]
        ssh.config[:ssh_user] = config[:ssh_user]
        ssh.config[:ssh_password] = config[:ssh_password]
        ssh.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
        ssh.config[:identity_file] = config[:identity_file]
        ssh.config[:manual] = true
        ssh.config[:no_host_key_verify] = config[:no_host_key_verify]
        ssh
      end

      def knife_ssh_with_password_auth
        ssh = knife_ssh
        ssh.config[:identity_file] = nil
        ssh.config[:ssh_password] = ssh.get_password
        ssh
      end

      def ssh_command
        command = render_template(load_template(config[:bootstrap_template]))

        if config[:use_sudo]
          command = "sudo #{command}"
        end

        command
      end

      module TemplateHelper

        #
        # == Chef::Knife::Bootstrap::TemplateHelper
        #
        # The methods in the TemplateHelper module expect to have access to
        # the instance varialbles set above as part of the context in the
        # Chef::Knife::Bootstrap#render_context method. Those instance
        # variables are:
        #
        # * @config   - a hash of knife's config values
        # * @run_list - the run list for the node to boostrap
        #

        ::Erubis::Context.send(:include, Chef::Knife::Bootstrap::TemplateHelper)

        def bootstrap_version_string(type=nil)
          version = Chef::Config[:knife][:bootstrap_version] || Chef::VERSION
          case type
          when :gems
            if @config[:prerelease]
              "--prerelease"
            else
              "--version #{version}"
            end
          else
            version
          end
        end
      end
    end
  end
end
