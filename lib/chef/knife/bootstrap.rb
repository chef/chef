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
        require 'chef/knife/core/bootstrap_context'
        require 'chef/json_compat'
        require 'tempfile'
        require 'highline'
        require 'net/ssh'
        require 'net/ssh/multi'
        require 'chef/knife/ssh'
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
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :ssh_gateway,
        :short => "-G GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

      option :forward_agent,
        :short => "-A",
        :long => "--forward-agent",
        :description => "Enable SSH agent forwarding",
        :boolean => true

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => lambda { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :bootstrap_proxy,
        :long => "--bootstrap-proxy PROXY_URL",
        :description => "The proxy server for the node being bootstrapped",
        :proc => Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

      option :bootstrap_no_proxy,
        :long => "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
        :description => "Do not proxy locations for the node being bootstrapped; this option is used internally by Opscode",
        :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

      # DEPR: Remove this option in Chef 13
      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template. [DEPRECATED] Use -t / --template option instead.",
        :proc => Proc.new { |t|
          Chef::Log.warn("[DEPRECATED] -d / --distro option is deprecated. Use -t / --template option instead.")
          Chef::Config[:knife][:bootstrap_template] = t
        }

      option :template,
        :short => "-t TEMPLATE",
        :long => "--template TEMPLATE",
        :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates.",
        :proc => Proc.new { |t| Chef::Config[:knife][:bootstrap_template] = t }

      option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true

      option :use_sudo_password,
        :long => "--use-sudo-password",
        :description => "Execute the bootstrap via sudo with password",
        :boolean => false

      # DEPR: Remove this option in Chef 13
      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use. [DEPRECATED] Use -t / --template option instead.",
        :proc => Proc.new { |t|
          Chef::Log.warn("[DEPRECATED] --template-file option is deprecated. Use -t / --template option instead.")
          Chef::Config[:knife][:bootstrap_template] = t
        }

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :first_boot_attributes,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| Chef::JSONCompat.parse(o) },
        :default => {}

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
          Chef::Config[:knife][:hints] ||= Hash.new
          name, path = h.split("=")
          Chef::Config[:knife][:hints][name] = path ? Chef::JSONCompat.parse(::File.read(path)) : Hash.new
        }

      option :secret,
        :short => "-s SECRET",
        :long  => "--secret ",
        :description => "The secret key to use to encrypt data bag item values",
        :proc => Proc.new { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :bootstrap_url,
        :long        => "--bootstrap-url URL",
        :description => "URL to a custom installation script",
        :proc        => Proc.new { |u| Chef::Config[:knife][:bootstrap_url] = u }

      option :bootstrap_install_command,
        :long        => "--bootstrap-install-command COMMANDS",
        :description => "Custom command to install chef-client",
        :proc        => Proc.new { |ic| Chef::Config[:knife][:bootstrap_install_command] = ic }

      option :bootstrap_wget_options,
        :long        => "--bootstrap-wget-options OPTIONS",
        :description => "Add options to wget when installing chef-client",
        :proc        => Proc.new { |wo| Chef::Config[:knife][:bootstrap_wget_options] = wo }

      option :bootstrap_curl_options,
        :long        => "--bootstrap-curl-options OPTIONS",
        :description => "Add options to curl when install chef-client",
        :proc        => Proc.new { |co| Chef::Config[:knife][:bootstrap_curl_options] = co }

      def find_template
        template = Chef::Config[:knife][:bootstrap_template]

        # Use the template directly if it's a path to an actual file
        return template if File.exists?(template)

        # Otherwise search the template directories until we find the right one

        bootstrap_files = []
        bootstrap_files << File.join(File.dirname(__FILE__), 'bootstrap', "#{template}.erb")
        bootstrap_files << File.join(Knife.chef_config_dir, "bootstrap", "#{template}.erb") if Knife.chef_config_dir
        bootstrap_files << File.join(ENV['HOME'], '.chef', 'bootstrap', "#{template}.erb") if ENV['HOME']
        bootstrap_files << Gem.find_files(File.join("chef","knife","bootstrap","#{template}.erb"))
        bootstrap_files.flatten!

        template_file = Array(bootstrap_files).find do |bootstrap_template|
          Chef::Log.debug("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          File.exists?(bootstrap_template)
        end

        unless template_file
          ui.info("Can not find bootstrap definition for #{config[:template]}")
          raise Errno::ENOENT
        end

        Chef::Log.debug("Found bootstrap template in #{File.dirname(template)}")

        template_file
      end

      def render_template(template=nil)
        context = Knife::Core::BootstrapContext.new(config, config[:run_list], Chef::Config)
        Erubis::Eruby.new(template).evaluate(context)
      end

      def read_template
        IO.read(@template_file).chomp
      end

      def run
        validate_name_args!
        @template_file = find_template
        @node_name = Array(@name_args).first
        # back compat--templates may use this setting:
        config[:server_name] = @node_name

        $stdout.sync = true

        ui.info("Connecting to #{ui.color(@node_name, :bold)}")

        begin
          knife_ssh.run
        rescue Net::SSH::AuthenticationFailed
          if config[:ssh_password]
            raise
          else
            ui.info("Failed to authenticate #{config[:ssh_user]} - trying password auth")
            knife_ssh_with_password_auth.run
          end
        end
      end

      def validate_name_args!
        if Array(@name_args).first.nil?
          ui.error("Must pass an FQDN or ip to bootstrap")
          exit 1
        elsif Array(@name_args).first == "windows"
          ui.warn("Hostname containing 'windows' specified. Please install 'knife-windows' if you are attempting to bootstrap a Windows node via WinRM.")
        end
      end

      def server_name
        Array(@name_args).first
      end

      def knife_ssh
        ssh = Chef::Knife::Ssh.new
        ssh.ui = ui
        ssh.name_args = [ server_name, ssh_command ]
        ssh.config[:ssh_user] = Chef::Config[:knife][:ssh_user] || config[:ssh_user]
        ssh.config[:ssh_password] = config[:ssh_password]
        ssh.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
        ssh.config[:ssh_gateway] = Chef::Config[:knife][:ssh_gateway] || config[:ssh_gateway]
        ssh.config[:forward_agent] = Chef::Config[:knife][:forward_agent] || config[:forward_agent]
        ssh.config[:identity_file] = Chef::Config[:knife][:identity_file] || config[:identity_file]
        ssh.config[:manual] = true
        ssh.config[:host_key_verify] = Chef::Config[:knife][:host_key_verify] || config[:host_key_verify]
        ssh.config[:on_error] = :raise
        ssh
      end

      def knife_ssh_with_password_auth
        ssh = knife_ssh
        ssh.config[:identity_file] = nil
        ssh.config[:ssh_password] = ssh.get_password
        ssh
      end

      def ssh_command
        command = render_template(read_template)

        if config[:use_sudo]
          command = config[:use_sudo_password] ? "echo '#{config[:ssh_password]}' | sudo -S #{command}" : "sudo #{command}"
        end

        command
      end

    end
  end
end
