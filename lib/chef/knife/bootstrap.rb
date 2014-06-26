#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

require "chef/knife"
require "chef/knife/data_bag_secret_options"
require "erubis"
require "chef/knife/bootstrap/chef_vault_handler"
require "chef/knife/bootstrap/client_builder"
require "chef/util/path_helper"

class Chef
  class Knife
    class Bootstrap < Knife
      include DataBagSecretOptions

      attr_accessor :client_builder
      attr_accessor :chef_vault_handler

      deps do
        require "chef/knife/core/bootstrap_context"
        require "chef/json_compat"
        require "tempfile"
        require "highline"
        require "net/ssh"
        require "net/ssh/multi"
        require "chef/knife/ssh"
        Chef::Knife::Ssh.load_deps
      end

      banner "knife bootstrap [SSH_USER@]FQDN (options)"

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

      option :ssh_gateway_identity,
        :long => "--ssh-gateway-identity SSH_GATEWAY_IDENTITY",
        :description => "The SSH identity file used for gateway authentication",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway_identity] = key }

      option :forward_agent,
        :short => "-A",
        :long => "--forward-agent",
        :description => "Enable SSH agent forwarding",
        :boolean => true

      option :identity_file,
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication. [DEPRECATED] Use --ssh-identity-file instead."

      option :ssh_identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--ssh-identity-file IDENTITY_FILE",
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

      option :bootstrap_proxy,
        :long => "--bootstrap-proxy PROXY_URL",
        :description => "The proxy server for the node being bootstrapped",
        :proc => Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

      option :bootstrap_proxy_user,
        :long => "--bootstrap-proxy-user PROXY_USER",
        :description => "The proxy authentication username for the node being bootstrapped"

      option :bootstrap_proxy_pass,
        :long => "--bootstrap-proxy-pass PROXY_PASS",
        :description => "The proxy authentication password for the node being bootstrapped"

      option :bootstrap_no_proxy,
        :long => "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
        :description => "Do not proxy locations for the node being bootstrapped; this option is used internally by Opscode",
        :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

      # DEPR: Remove this option in Chef 13
      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template. [DEPRECATED] Use -t / --bootstrap-template option instead.",
        :proc        => Proc.new { |v|
          Chef::Log.warn("[DEPRECATED] -d / --distro option is deprecated. Use -t / --bootstrap-template option instead.")
          v
        }

      option :bootstrap_template,
        :short => "-t TEMPLATE",
        :long => "--bootstrap-template TEMPLATE",
        :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

      option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true

      option :preserve_home,
        :long => "--sudo-preserve-home",
        :description => "Preserve non-root user HOME environment variable with sudo",
        :boolean => true

      option :use_sudo_password,
        :long => "--use-sudo-password",
        :description => "Execute the bootstrap via sudo with password",
        :boolean => false

      # DEPR: Remove this option in Chef 13
      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use. [DEPRECATED] Use -t / --bootstrap-template option instead.",
        :proc        => Proc.new { |v|
          Chef::Log.warn("[DEPRECATED] --template-file option is deprecated. Use -t / --bootstrap-template option instead.")
          v
        }

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :policy_name,
        :long         => "--policy-name POLICY_NAME",
        :description  => "Policyfile name to use (--policy-group must also be given)",
        :default      => nil

      option :policy_group,
        :long         => "--policy-group POLICY_GROUP",
        :description  => "Policy group name to use (--policy-name must also be given)",
        :default      => nil

      option :tags,
        :long => "--tags TAGS",
        :description => "Comma separated list of tags to apply to the node",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :first_boot_attributes,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| Chef::JSONCompat.parse(o) },
        :default => nil

      option :first_boot_attributes_from_file,
        :long => "--json-attribute-file FILE",
        :description => "A JSON file to be used to the first run of chef-client",
        :proc => lambda { |o| Chef::JSONCompat.parse(File.read(o)) },
        :default => nil

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target. Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
          Chef::Config[:knife][:hints] ||= Hash.new
          name, path = h.split("=")
          Chef::Config[:knife][:hints][name] = path ? Chef::JSONCompat.parse(::File.read(path)) : Hash.new
        }

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

      option :node_ssl_verify_mode,
        :long        => "--node-ssl-verify-mode [peer|none]",
        :description => "Whether or not to verify the SSL cert for all HTTPS requests.",
        :proc        => Proc.new { |v|
          valid_values = %w{none peer}
          unless valid_values.include?(v)
            raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
          end
          v
        }

      option :node_verify_api_cert,
        :long        => "--[no-]node-verify-api-cert",
        :description => "Verify the SSL cert for HTTPS requests to the Chef server API.",
        :boolean     => true

      option :bootstrap_vault_file,
        :long        => "--bootstrap-vault-file VAULT_FILE",
        :description => "A JSON file with a list of vault(s) and item(s) to be updated"

      option :bootstrap_vault_json,
        :long        => "--bootstrap-vault-json VAULT_JSON",
        :description => "A JSON string with the vault(s) and item(s) to be updated"

      option :bootstrap_vault_item,
        :long        => "--bootstrap-vault-item VAULT_ITEM",
        :description => 'A single vault and item to update as "vault:item"',
        :proc        => Proc.new { |i|
          (vault, item) = i.split(/:/)
          Chef::Config[:knife][:bootstrap_vault_item] ||= {}
          Chef::Config[:knife][:bootstrap_vault_item][vault] ||= []
          Chef::Config[:knife][:bootstrap_vault_item][vault].push(item)
          Chef::Config[:knife][:bootstrap_vault_item]
        }

      def initialize(argv = [])
        super
        @client_builder = Chef::Knife::Bootstrap::ClientBuilder.new(
          chef_config: Chef::Config,
          knife_config: config,
          ui: ui
        )
        @chef_vault_handler = Chef::Knife::Bootstrap::ChefVaultHandler.new(
          knife_config: config,
          ui: ui
        )
      end

      # The default bootstrap template to use to bootstrap a server This is a public API hook
      # which knife plugins use or inherit and override.
      #
      # @return [String] Default bootstrap template
      def default_bootstrap_template
        "chef-full"
      end

      def host_descriptor
        Array(@name_args).first
      end

      # The server_name is the DNS or IP we are going to connect to, it is not necessarily
      # the node name, the fqdn, or the hostname of the server.  This is a public API hook
      # which knife plugins use or inherit and override.
      #
      # @return [String] The DNS or IP that bootstrap will connect to
      def server_name
        if host_descriptor
          @server_name ||= host_descriptor.split("@").reverse[0]
        end
      end

      def user_name
        if host_descriptor
          @user_name ||= host_descriptor.split("@").reverse[1]
        end
      end

      def bootstrap_template
        # The order here is important. We want to check if we have the new Chef 12 option is set first.
        # Knife cloud plugins unfortunately all set a default option for the :distro so it should be at
        # the end.
        config[:bootstrap_template] || config[:template_file] || config[:distro] || default_bootstrap_template
      end

      def find_template
        template = bootstrap_template

        # Use the template directly if it's a path to an actual file
        if File.exists?(template)
          Chef::Log.debug("Using the specified bootstrap template: #{File.dirname(template)}")
          return template
        end

        # Otherwise search the template directories until we find the right one
        bootstrap_files = []
        bootstrap_files << File.join(File.dirname(__FILE__), "bootstrap/templates", "#{template}.erb")
        bootstrap_files << File.join(Knife.chef_config_dir, "bootstrap", "#{template}.erb") if Chef::Knife.chef_config_dir
        Chef::Util::PathHelper.home(".chef", "bootstrap", "#{template}.erb") { |p| bootstrap_files << p }
        bootstrap_files << Gem.find_files(File.join("chef", "knife", "bootstrap", "#{template}.erb"))
        bootstrap_files.flatten!

        template_file = Array(bootstrap_files).find do |bootstrap_template|
          Chef::Log.debug("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          File.exists?(bootstrap_template)
        end

        unless template_file
          ui.info("Can not find bootstrap definition for #{template}")
          raise Errno::ENOENT
        end

        Chef::Log.debug("Found bootstrap template in #{File.dirname(template_file)}")

        template_file
      end

      def secret
        @secret ||= encryption_secret_provided_ignore_encrypt_flag? ? read_secret : nil
      end

      def bootstrap_context
        @bootstrap_context ||= Knife::Core::BootstrapContext.new(
          config,
          config[:run_list],
          Chef::Config,
          secret
        )
      end

      def first_boot_attributes
        @config[:first_boot_attributes] || @config[:first_boot_attributes_from_file] || {}
      end

      def render_template
        @config[:first_boot_attributes] = first_boot_attributes
        template_file = find_template
        template = IO.read(template_file).chomp
        Erubis::Eruby.new(template).evaluate(bootstrap_context)
      end

      def run
        if @config[:first_boot_attributes] && @config[:first_boot_attributes_from_file]
          raise Chef::Exceptions::BootstrapCommandInputError
        end

        validate_name_args!
        validate_options!

        $stdout.sync = true

        # chef-vault integration must use the new client-side hawtness, otherwise to use the
        # new client-side hawtness, just delete your validation key.
        if chef_vault_handler.doing_chef_vault? ||
            (Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key])))

          unless config[:chef_node_name]
            ui.error("You must pass a node name with -N when bootstrapping with user credentials")
            exit 1
          end

          client_builder.run

          chef_vault_handler.run(client_builder.client)

          bootstrap_context.client_pem = client_builder.client_path
        else
          ui.info("Doing old-style registration with the validation key at #{Chef::Config[:validation_key]}...")
          ui.info("Delete your validation key in order to use your user credentials instead")
          ui.info("")
        end

        ui.info("Connecting to #{ui.color(server_name, :bold)}")

        begin
          knife_ssh.run
        rescue Net::SSH::AuthenticationFailed
          if config[:ssh_password]
            raise
          else
            ui.info("Failed to authenticate #{knife_ssh.config[:ssh_user]} - trying password auth")
            knife_ssh_with_password_auth.run
          end
        end
      end

      def validate_name_args!
        if server_name.nil?
          ui.error("Must pass an FQDN or ip to bootstrap")
          exit 1
        elsif server_name == "windows"
          # catches "knife bootstrap windows" when that command is not installed
          ui.warn("Hostname containing 'windows' specified. Please install 'knife-windows' if you are attempting to bootstrap a Windows node via WinRM.")
        end
      end

      def validate_options!
        if incomplete_policyfile_options?
          ui.error("--policy-name and --policy-group must be specified together")
          exit 1
        elsif policyfile_and_run_list_given?
          ui.error("Policyfile options and --run-list are exclusive")
          exit 1
        end
        true
      end

      def knife_ssh
        ssh = Chef::Knife::Ssh.new
        ssh.ui = ui
        ssh.name_args = [ server_name, ssh_command ]
        ssh.config[:ssh_user] = user_name || config[:ssh_user]
        ssh.config[:ssh_password] = config[:ssh_password]
        ssh.config[:ssh_port] = config[:ssh_port]
        ssh.config[:ssh_gateway] = config[:ssh_gateway]
        ssh.config[:ssh_gateway_identity] = config[:ssh_gateway_identity]
        ssh.config[:forward_agent] = config[:forward_agent]
        ssh.config[:ssh_identity_file] = config[:ssh_identity_file] || config[:identity_file]
        ssh.config[:manual] = true
        ssh.config[:host_key_verify] = config[:host_key_verify]
        ssh.config[:on_error] = :raise
        ssh
      end

      def knife_ssh_with_password_auth
        ssh = knife_ssh
        ssh.config[:ssh_identity_file] = nil
        ssh.config[:ssh_password] = ssh.get_password
        ssh
      end

      def ssh_command
        command = render_template

        if config[:use_sudo]
          sudo_prefix = config[:use_sudo_password] ? "echo '#{config[:ssh_password]}' | sudo -S " : "sudo "
          command = config[:preserve_home] ? "#{sudo_prefix} #{command}" : "#{sudo_prefix} -H #{command}"
        end

        command
      end

      private

      # True if policy_name and run_list are both given
      def policyfile_and_run_list_given?
        run_list_given? && policyfile_options_given?
      end

      def run_list_given?
        !config[:run_list].nil? && !config[:run_list].empty?
      end

      def policyfile_options_given?
        !!config[:policy_name]
      end

      # True if one of policy_name or policy_group was given, but not both
      def incomplete_policyfile_options?
        (!!config[:policy_name] ^ config[:policy_group])
      end

    end
  end
end
