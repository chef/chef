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

      option :bootstrap_no_proxy,
        :long => "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
        :description => "Do not proxy locations for the node being bootstrapped; this option is used internally by Opscode",
        :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "chef-full"

      option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true

      option :use_sudo_password,
        :long => "--use-sudo-password",
        :description => "Execute the bootstrap via sudo with password",
        :boolean => false

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
          Chef::Config[:knife][:hints][name] = path ? Chef::JSONCompat.parse(::File.read(path)) : Hash.new  }

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

      option :vault_file,
        :short       => '-L VAULT_FILE',
        :long        => '--vault-file',
        :description => 'A JSON file with a list of vault',
        :proc        => lambda { |l| Chef::JSONCompat.from_json(::File.read(l)) }

      option :vault_list,
        :short       => '-l VAULT_LIST',
        :long        => '--vault-list VAULT_LIST',
        :description => 'A JSON string with the vault to be updated',
        :proc        => lambda { |v| Chef::JSONCompat.from_json(v) }

      option :preseed_attributes,
        :long        => "--preseed-attributes JSON",
        :description => "Attributes to pre-seed the node with",
        :proc        => lambda { |a| 
          Chef::Config[:knife][:preseed_attributes] = Chef::JSONCompat.from_json(a) }

      def register_client
        node = search_for("name:#{@fqdn}", :node)
        client = search_for("name:#{@fqdn}", :client)

        if node.empty? 
          if client.empty?
            Chef::ApiClient::Registration.new(@fqdn, config[:client_pem]).run
            new_node = Chef::Node.new
            new_node.name(@fqdn)
            new_node.normal_attrs = Chef::Config[:knife][:preseed_attributes]
            client_rest = Chef::REST.new(Chef::Config.chef_server_url, @fqdn, config[:client_pem])
            client_rest.post_rest("nodes/", new_node)
          else
            ui.fatal("Something went wrong! Unable to find the Node: Please delete the Client and retry.")
            exit 2
          end
        elsif client.empty?
          ui.fatal("Something went wrong! Unable to find the Client: Please delete the Node and retry.")
          exit 3
        else
          ui.info("Node already exist - skipping registration")
        end
      end

      def retrieve_hostname
        begin
          connection.exec!("hostname")
        rescue => e
            ui.fatal(e.message)
            raise
        end
      end

      def delete_client_pem
        File.delete(config[:client_pem]) if File.exist?(config[:client_pem])
      end

      def wait_node
        sleep 5
        search_for("name:#{@fqdn}").empty?
      end

      def ssh(hostname, username, options = {})
        rescue_exceptions = [
          Errno::EACCES, Errno::EADDRINUSE, Errno::ECONNREFUSED,
          Errno::ECONNRESET, Errno::ENETUNREACH, Errno::EHOSTUNREACH,
          Net::SSH::Disconnect
        ]

        options.merge!({ :port => config[:ssh_port] }) if config[:ssh_port]
        options.merge!({ :password => config[:ssh_password] }) if config[:ssh_password]
        options.merge!({ :keys_only => true }) if config[:identity_file]
        options.merge!({ :keys => config[:identity_file] }) if config[:identity_file]

        begin
          Net::SSH.start(hostname, username, options)
        rescue *rescue_exceptions => e
          ui.fatal("Failed to connect to #{username}@#{hostname}: #{e.message}")
          raise
        end
      end

      def search_for(query, type = :node)
        sc = Chef::Search::Query.new
        sc.search(type, query)[0]
      end

      def find_template(template=nil)
        # Are we bootstrapping using an already shipped template?
        if config[:template_file]
          bootstrap_files = config[:template_file]
        else
          bootstrap_files = []
          bootstrap_files << File.join(File.dirname(__FILE__), 'bootstrap', "#{config[:distro]}.erb")
          bootstrap_files << File.join(Knife.chef_config_dir, "bootstrap", "#{config[:distro]}.erb") if Knife.chef_config_dir
          bootstrap_files << File.join(ENV['HOME'], '.chef', 'bootstrap', "#{config[:distro]}.erb") if ENV['HOME']
          bootstrap_files << Gem.find_files(File.join("chef","knife","bootstrap","#{config[:distro]}.erb"))
          bootstrap_files.flatten!
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

        template
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
        warn_chef_config_secret_key
        @template_file = find_template(config[:bootstrap_template])
        @node_name = Array(@name_args).first
        @fqdn = config[:chef_node_name] || retrieve_hostname.strip
        # back compat--templates may use this setting:
        config[:server_name] = @node_name

        $stdout.sync = true

        if config[:vault_list] || config[:vault_file]
          ui.info("#{ui.color(@node_name, :bold)} Starting Pre-Bootstrap Process")
          config[:client_pem] = File.expand_path(File.join(File.dirname(__FILE__), 'keeper.pem'))

          ui.info("#{ui.color(@node_name, :bold)} Registering Node #{ui.color(@fqdn, :bold)}")
          register_client

          ui.info("#{ui.color(@node_name, :bold)} Waiting search node.. ") while wait_node

          ui.info("#{ui.color(@node_name, :bold)} Updating Chef Vault(s)")
          update_vault_list(config[:vault_list]) if config[:vault_list]
          update_vault_list(config[:vault_file]) if config[:vault_file]
        end

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
      ensure
        delete_client_pem if config[:client_pem]
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

      def warn_chef_config_secret_key
        unless Chef::Config[:encrypted_data_bag_secret].nil?
          ui.warn "* " * 40
          ui.warn(<<-WARNING)
Specifying the encrypted data bag secret key using an 'encrypted_data_bag_secret'
entry in 'knife.rb' is deprecated. Please see CHEF-4011 for more details. You
can supress this warning and still distribute the secret key to all bootstrapped
machines by adding the following to your 'knife.rb' file:

  knife[:secret_file] = "/path/to/your/secret"

If you would like to selectively distribute a secret key during bootstrap
please use the '--secret' or '--secret-file' options of this command instead.

#{ui.color('IMPORTANT:', :red, :bold)} In a future version of Chef, this
behavior will be removed and any 'encrypted_data_bag_secret' entries in
'knife.rb' will be ignored completely.
WARNING
          ui.warn "* " * 40
        end
      end

      def update_vault_list(vault_list)
        vault_list.each do |vault, item|
          if item.is_a?(Array)
            item.each do |i|
              update_vault(vault, i)
            end
          else
            update_vault(vault, item)
          end
        end
      end

      def connection
        @connection ||= ssh(@node_name, config[:ssh_user])
      end

      def update_vault(vault, item)
        begin
          vault_item = ChefVault::Item.load(vault, item)
          vault_item.clients("name:#{@fqdn}")
          vault_item.save
        rescue ChefVault::Exceptions::KeysNotFound,
          ChefVault::Exceptions::ItemNotFound

          raise ChefVault::Exceptions::ItemNotFound,
            "#{vault}/#{item} does not exist, "\
            "you might want to delete the node before retrying."
        end
      end

    end
  end
end
