#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../knife"
require_relative "data_bag_secret_options"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "license_acceptance/cli_flags/mixlib_cli"
module LicenseAcceptance
  autoload :Acceptor, "license_acceptance/acceptor"
end

class Chef
  class Knife
    class Bootstrap < Knife
      include DataBagSecretOptions
      include LicenseAcceptance::CLIFlags::MixlibCLI

      SUPPORTED_CONNECTION_PROTOCOLS ||= %w{ssh winrm}.freeze
      WINRM_AUTH_PROTOCOL_LIST ||= %w{plaintext kerberos ssl negotiate}.freeze

      # Common connectivity options
      option :connection_user,
        short: "-U USERNAME",
        long: "--connection-user USERNAME",
        description: "Authenticate to the target host with this user account."

      option :connection_password,
        short: "-P PASSWORD",
        long: "--connection-password PASSWORD",
        description: "Authenticate to the target host with this password."

      option :connection_port,
        short: "-p PORT",
        long: "--connection-port PORT",
        description: "The port on the target node to connect to."

      option :connection_protocol,
        short: "-o PROTOCOL",
        long: "--connection-protocol PROTOCOL",
        description: "The protocol to use to connect to the target node.",
        in: SUPPORTED_CONNECTION_PROTOCOLS

      option :max_wait,
        short: "-W SECONDS",
        long: "--max-wait SECONDS",
        description: "The maximum time to wait for the initial connection to be established."

      option :session_timeout,
        long: "--session-timeout SECONDS",
        description: "The number of seconds to wait for each connection operation to be acknowledged while running bootstrap.",
        default: 60

      # WinRM Authentication
      option :winrm_ssl_peer_fingerprint,
        long: "--winrm-ssl-peer-fingerprint FINGERPRINT",
        description: "SSL certificate fingerprint expected from the target."

      option :ca_trust_file,
        short: "-f CA_TRUST_PATH",
        long: "--ca-trust-file CA_TRUST_PATH",
        description: "The Certificate Authority (CA) trust file used for SSL transport."

      option :winrm_no_verify_cert,
        long: "--winrm-no-verify-cert",
        description: "Do not verify the SSL certificate of the target node for WinRM.",
        boolean: true

      option :winrm_ssl,
        long: "--winrm-ssl",
        description: "Use SSL in the WinRM connection."

      option :winrm_auth_method,
        short: "-w AUTH-METHOD",
        long: "--winrm-auth-method AUTH-METHOD",
        description: "The WinRM authentication method to use.",
        in: WINRM_AUTH_PROTOCOL_LIST

      option :winrm_basic_auth_only,
        long: "--winrm-basic-auth-only",
        description: "For WinRM basic authentication when using the 'ssl' auth method.",
        boolean: true

      # This option was provided in knife bootstrap windows winrm,
      # but it is ignored  in knife-windows/WinrmSession, and so remains unimplemented here.
      # option :kerberos_keytab_file,
      #   :short => "-T KEYTAB_FILE",
      #   :long => "--keytab-file KEYTAB_FILE",
      #   :description => "The Kerberos keytab file used for authentication"

      option :kerberos_realm,
        short: "-R KERBEROS_REALM",
        long: "--kerberos-realm KERBEROS_REALM",
        description: "The Kerberos realm used for authentication."

      option :kerberos_service,
        short: "-S KERBEROS_SERVICE",
        long: "--kerberos-service KERBEROS_SERVICE",
        description: "The Kerberos service used for authentication."

      ## SSH Authentication
      option :ssh_gateway,
        short: "-G GATEWAY",
        long: "--ssh-gateway GATEWAY",
        description: "The SSH gateway."

      option :ssh_gateway_identity,
        long: "--ssh-gateway-identity SSH_GATEWAY_IDENTITY",
        description: "The SSH identity file used for gateway authentication."

      option :ssh_forward_agent,
        short: "-A",
        long: "--ssh-forward-agent",
        description: "Enable SSH agent forwarding.",
        boolean: true

      option :ssh_identity_file,
        short: "-i IDENTITY_FILE",
        long: "--ssh-identity-file IDENTITY_FILE",
        description: "The SSH identity file used for authentication."

      option :ssh_verify_host_key,
        long: "--ssh-verify-host-key VALUE",
        description: "Verify host key. Default is 'always'.",
        in: %w{always accept_new accept_new_or_local_tunnel never},
        default: "always"

      #
      # bootstrap options
      #

      # client.rb content via chef-full/bootstrap_context
      option :bootstrap_version,
        long: "--bootstrap-version VERSION",
        description: "The version of #{ChefUtils::Dist::Infra::PRODUCT} to install."

      option :channel,
        long: "--channel CHANNEL",
        description: "Install from the given channel. Default is 'stable'.",
        default: "stable",
        in: %w{stable current unstable}

      # client.rb content via chef-full/bootstrap_context
      option :bootstrap_proxy,
        long: "--bootstrap-proxy PROXY_URL",
        description: "The proxy server for the node being bootstrapped."

      # client.rb content via bootstrap_context
      option :bootstrap_proxy_user,
        long: "--bootstrap-proxy-user PROXY_USER",
        description: "The proxy authentication username for the node being bootstrapped."

      # client.rb content via bootstrap_context
      option :bootstrap_proxy_pass,
        long: "--bootstrap-proxy-pass PROXY_PASS",
        description: "The proxy authentication password for the node being bootstrapped."

      # client.rb content via bootstrap_context
      option :bootstrap_no_proxy,
        long: "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
        description: "Do not proxy locations for the node being bootstrapped"

      # client.rb content via bootstrap_context
      option :bootstrap_template,
        short: "-t TEMPLATE",
        long: "--bootstrap-template TEMPLATE",
        description: "Bootstrap #{ChefUtils::Dist::Infra::PRODUCT} using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

      # client.rb content via bootstrap_context
      option :node_ssl_verify_mode,
        long: "--node-ssl-verify-mode [peer|none]",
        description: "Whether or not to verify the SSL cert for all HTTPS requests.",
        proc: Proc.new { |v|
          valid_values = %w{none peer}
          unless valid_values.include?(v)
            raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
          end

          v
        }

      # bootstrap_context - client.rb
      option :node_verify_api_cert,
        long: "--[no-]node-verify-api-cert",
        description: "Verify the SSL cert for HTTPS requests to the #{ChefUtils::Dist::Server::PRODUCT} API.",
        boolean: true

      # runtime - sudo settings (train handles sudo)
      option :use_sudo,
        long: "--sudo",
        description: "Execute the bootstrap via sudo.",
        boolean: true

      # runtime - sudo settings (train handles sudo)
      option :preserve_home,
        long: "--sudo-preserve-home",
        description: "Preserve non-root user HOME environment variable with sudo.",
        boolean: true

      # runtime - sudo settings (train handles sudo)
      option :use_sudo_password,
        long: "--use-sudo-password",
        description: "Execute the bootstrap via sudo with password.",
        boolean: false

      # runtime - su user
      option :su_user,
        long: "--su-user NAME",
        description: "The su - USER name to perform bootstrap command using a non-root user."

      # runtime - su user password
      option :su_password,
        long: "--su-password PASSWORD",
        description: "The su USER password for authentication."

      # runtime - client_builder
      option :chef_node_name,
        short: "-N NAME",
        long: "--node-name NAME",
        description: "The node name for your new node."

      # runtime - client_builder - set runlist when creating node
      option :run_list,
        short: "-r RUN_LIST",
        long: "--run-list RUN_LIST",
        description: "Comma separated list of roles/recipes to apply.",
        proc: lambda { |o| o.split(/[\s,]+/) },
        default: []

      # runtime - client_builder - set policy name when creating node
      option :policy_name,
        long: "--policy-name POLICY_NAME",
        description: "Policyfile name to use (--policy-group must also be given).",
        default: nil

      # runtime - client_builder - set policy group when creating node
      option :policy_group,
        long: "--policy-group POLICY_GROUP",
        description: "Policy group name to use (--policy-name must also be given).",
        default: nil

      # runtime - client_builder -  node tags
      option :tags,
        long: "--tags TAGS",
        description: "Comma separated list of tags to apply to the node.",
        proc: lambda { |o| o.split(/[\s,]+/) },
        default: []

      # bootstrap template
      option :first_boot_attributes,
        short: "-j JSON_ATTRIBS",
        long: "--json-attributes",
        description: "A JSON string to be added to the first run of #{ChefUtils::Dist::Infra::CLIENT}.",
        proc: lambda { |o| Chef::JSONCompat.parse(o) },
        default: nil

      # bootstrap template
      option :first_boot_attributes_from_file,
        long: "--json-attribute-file FILE",
        description: "A JSON file to be used to the first run of #{ChefUtils::Dist::Infra::CLIENT}.",
        proc: lambda { |o| Chef::JSONCompat.parse(File.read(o)) },
        default: nil

      # bootstrap template
      # Create ohai hints in /etc/chef/ohai/hints, fname=hintname, content=value
      option :hints,
        long: "--hint HINT_NAME[=HINT_FILE]",
        description: "Specify an Ohai hint to be set on the bootstrap target. Use multiple --hint options to specify multiple hints.",
        proc: Proc.new { |hint, accumulator|
          accumulator ||= {}
          name, path = hint.split("=", 2)
          accumulator[name] = path ? Chef::JSONCompat.parse(::File.read(path)) : {}
          accumulator
        }

      # bootstrap override: url of a an installer shell script to use in place of omnitruck
      # Note that the bootstrap template _only_ references this out of Chef::Config, and not from
      # the provided options to knife bootstrap, so we set the Chef::Config option here.
      option :bootstrap_url,
        long: "--bootstrap-url URL",
        description: "URL to a custom installation script."

      option :bootstrap_product,
        long: "--bootstrap-product PRODUCT",
        description: "Product to install.",
        default: "chef"

      option :msi_url, # Windows target only
        short: "-m URL",
        long: "--msi-url URL",
        description: "Location of the #{ChefUtils::Dist::Infra::PRODUCT} MSI. The default templates will prefer to download from this location. The MSI will be downloaded from #{ChefUtils::Dist::Org::WEBSITE} if not provided (Windows).",
        default: ""

      # bootstrap override: Do this instead of our own setup.sh from omnitruck. Causes bootstrap_url to be ignored.
      option :bootstrap_install_command,
        long: "--bootstrap-install-command COMMANDS",
        description: "Custom command to install #{ChefUtils::Dist::Infra::PRODUCT}."

      # bootstrap template: Run this command first in the bootstrap script
      option :bootstrap_preinstall_command,
        long: "--bootstrap-preinstall-command COMMANDS",
        description: "Custom commands to run before installing #{ChefUtils::Dist::Infra::PRODUCT}."

      # bootstrap template
      option :bootstrap_wget_options,
        long: "--bootstrap-wget-options OPTIONS",
        description: "Add options to wget when installing #{ChefUtils::Dist::Infra::PRODUCT}."

      # bootstrap template
      option :bootstrap_curl_options,
        long: "--bootstrap-curl-options OPTIONS",
        description: "Add options to curl when install #{ChefUtils::Dist::Infra::PRODUCT}."

      # chef_vault_handler
      option :bootstrap_vault_file,
        long: "--bootstrap-vault-file VAULT_FILE",
        description: "A JSON file with a list of vault(s) and item(s) to be updated."

      # chef_vault_handler
      option :bootstrap_vault_json,
        long: "--bootstrap-vault-json VAULT_JSON",
        description: "A JSON string with the vault(s) and item(s) to be updated."

      # chef_vault_handler
      option :bootstrap_vault_item,
        long: "--bootstrap-vault-item VAULT_ITEM",
        description: 'A single vault and item to update as "vault:item".',
        proc: Proc.new { |i, accumulator|
          (vault, item) = i.split(":")
          accumulator ||= {}
          accumulator[vault] ||= []
          accumulator[vault].push(item)
          accumulator
        }

      # Deprecated options. These must be declared after
      # regular options because they refer to the replacement
      # option definitions implicitly.
      deprecated_option :auth_timeout,
        replacement: :max_wait,
        long: "--max-wait SECONDS"

      deprecated_option :forward_agent,
        replacement: :ssh_forward_agent,
        boolean: true, long: "--forward-agent"

      deprecated_option :host_key_verify,
        replacement: :ssh_verify_host_key,
        boolean: true, long: "--[no-]host-key-verify",
        value_mapper: Proc.new { |verify| verify ? "always" : "never" }

      deprecated_option :prerelease,
        replacement: :channel,
        long: "--prerelease",
        boolean: true, value_mapper: Proc.new { "current" }

      deprecated_option :ssh_user,
        replacement: :connection_user,
        long: "--ssh-user USERNAME"

      deprecated_option :ssh_password,
        replacement: :connection_password,
        long: "--ssh-password PASSWORD"

      deprecated_option :ssh_port,
        replacement: :connection_port,
        long: "--ssh-port PASSWORD"

      deprecated_option :ssl_peer_fingerprint,
        replacement: :winrm_ssl_peer_fingerprint,
        long: "--ssl-peer-fingerprint FINGERPRINT"

      deprecated_option :winrm_user,
        replacement: :connection_user,
        long: "--winrm-user USERNAME", short: "-x USERNAME"

      deprecated_option :winrm_password,
        replacement: :connection_password,
        long: "--winrm-password PASSWORD"

      deprecated_option :winrm_port,
        replacement: :connection_port,
        long: "--winrm-port PORT"

      deprecated_option :winrm_authentication_protocol,
        replacement: :winrm_auth_method,
        long: "--winrm-authentication-protocol PROTOCOL"

      deprecated_option :winrm_session_timeout,
        replacement: :session_timeout,
        long: "--winrm-session-timeout MINUTES"

      deprecated_option :winrm_ssl_verify_mode,
        replacement: :winrm_no_verify_cert,
        long: "--winrm-ssl-verify-mode MODE"

      deprecated_option :winrm_transport, replacement: :winrm_ssl,
        long: "--winrm-transport TRANSPORT",
        value_mapper: Proc.new { |value| value == "ssl" }

      attr_reader :connection

      deps do
        require "erubis" unless defined?(Erubis)
        require "net/ssh" unless defined?(Net::SSH)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
        require "chef-config/path_helper" unless defined?(ChefConfig::PathHelper)
        require_relative "bootstrap/chef_vault_handler"
        require_relative "bootstrap/client_builder"
        require_relative "bootstrap/train_connector"
      end

      banner "knife bootstrap [PROTOCOL://][USER@]FQDN (options)"

      def client_builder
        @client_builder ||= Chef::Knife::Bootstrap::ClientBuilder.new(
          chef_config: Chef::Config,
          config: config,
          ui: ui
        )
      end

      def chef_vault_handler
        @chef_vault_handler ||= Chef::Knife::Bootstrap::ChefVaultHandler.new(
          config: config,
          ui: ui
        )
      end

      # Determine if we need to accept the Chef Infra license locally in order to successfully bootstrap
      # the remote node. Remote 'chef-client' run will fail if it is >= 15 and the license is not accepted locally.
      def check_license
        Chef::Log.debug("Checking if we need to accept Chef license to bootstrap node")
        version = config[:bootstrap_version] || Chef::VERSION.split(".").first
        acceptor = LicenseAcceptance::Acceptor.new(logger: Chef::Log, provided: Chef::Config[:chef_license])
        if acceptor.license_required?("chef", version)
          Chef::Log.debug("License acceptance required for chef version: #{version}")
          license_id = acceptor.id_from_mixlib("chef")
          acceptor.check_and_persist(license_id, version)
          Chef::Config[:chef_license] ||= acceptor.acceptance_value
        end
      end

      # The default bootstrap template to use to bootstrap a server.
      # This is a public API hook which knife plugins use or inherit and override.
      #
      # @return [String] Default bootstrap template
      def default_bootstrap_template
        if connection.windows?
          "windows-chef-client-msi"
        else
          "chef-full"
        end
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

      # @return [String] The CLI specific bootstrap template or the default
      def bootstrap_template
        # Allow passing a bootstrap template or use the default
        config[:bootstrap_template] || default_bootstrap_template
      end

      def find_template
        template = bootstrap_template

        # Use the template directly if it's a path to an actual file
        if File.exist?(template)
          Chef::Log.trace("Using the specified bootstrap template: #{File.dirname(template)}")
          return template
        end

        # Otherwise search the template directories until we find the right one
        bootstrap_files = []
        bootstrap_files << File.join(__dir__, "bootstrap/templates", "#{template}.erb")
        bootstrap_files << File.join(Knife.chef_config_dir, "bootstrap", "#{template}.erb") if Chef::Knife.chef_config_dir
        ChefConfig::PathHelper.home(".chef", "bootstrap", "#{template}.erb") { |p| bootstrap_files << p }
        bootstrap_files << Gem.find_files(File.join("chef", "knife", "bootstrap", "#{template}.erb"))
        bootstrap_files.flatten!

        template_file = Array(bootstrap_files).find do |bootstrap_template|
          Chef::Log.trace("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          File.exist?(bootstrap_template)
        end

        unless template_file
          ui.info("Can not find bootstrap definition for #{template}")
          raise Errno::ENOENT
        end

        Chef::Log.trace("Found bootstrap template: #{template_file}")

        template_file
      end

      def secret
        @secret ||= encryption_secret_provided_ignore_encrypt_flag? ? read_secret : nil
      end

      # Establish bootstrap context for template rendering.
      # Requires connection to be a live connection in order to determine
      # the correct platform.
      def bootstrap_context
        @bootstrap_context ||=
          if connection.windows?
            require_relative "core/windows_bootstrap_context"
            Knife::Core::WindowsBootstrapContext.new(config, config[:run_list], Chef::Config, secret)
          else
            require_relative "core/bootstrap_context"
            Knife::Core::BootstrapContext.new(config, config[:run_list], Chef::Config, secret)
          end
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
        check_license if ChefUtils::Dist::Org::ENFORCE_LICENSE

        plugin_setup!
        validate_name_args!
        validate_protocol!
        validate_first_boot_attributes!
        validate_winrm_transport_opts!
        validate_policy_options!
        plugin_validate_options!

        winrm_warn_no_ssl_verification
        warn_on_short_session_timeout

        plugin_create_instance!
        $stdout.sync = true
        connect!
        register_client

        content = render_template
        bootstrap_path = upload_bootstrap(content)
        perform_bootstrap(bootstrap_path)
        plugin_finalize
      ensure
        connection.del_file!(bootstrap_path) if connection && bootstrap_path
      end

      def register_client
        # chef-vault integration must use the new client-side hawtness, otherwise to use the
        # new client-side hawtness, just delete your validation key.
        if chef_vault_handler.doing_chef_vault? ||
            (Chef::Config[:validation_key] &&
             !File.exist?(File.expand_path(Chef::Config[:validation_key])))

          unless config[:chef_node_name]
            ui.error("You must pass a node name with -N when bootstrapping with user credentials")
            exit 1
          end
          client_builder.run
          chef_vault_handler.run(client_builder.client)

          bootstrap_context.client_pem = client_builder.client_path
        else
          ui.warn "Performing legacy client registration with the validation key at #{Chef::Config[:validation_key]}..."
          ui.warn "Remove the key file or remove the 'validation_key' configuration option from your config.rb (knife.rb) to use more secure user credentials for client registration."
        end
      end

      def perform_bootstrap(remote_bootstrap_script_path)
        ui.info("Bootstrapping #{ui.color(server_name, :bold)}")
        cmd = bootstrap_command(remote_bootstrap_script_path)
        bootstrap_run_command(cmd)
      end

      # Actual bootstrap command to be run on the node.
      # Handles recursive calls if su USER failed to authenticate.
      def bootstrap_run_command(cmd)
        r = connection.run_command(cmd) do |data, channel|
          ui.msg("#{ui.color(" [#{connection.hostname}]", :cyan)} #{data}")
          channel.send_data("#{config[:su_password] || config[:connection_password]}\n") if data.match?("Password:")
        end

        if r.exit_status != 0
          ui.error("The following error occurred on #{server_name}:")
          ui.error("#{r.stdout} #{r.stderr}".strip)
          exit(r.exit_status)
        end
      rescue Train::UserError => e
        limit ||= 0
        if e.reason == :bad_su_user_password && limit < 3
          limit += 1
          ui.warn("Failed to authenticate su - #{config[:su_user]} to #{server_name}")
          config[:su_password] = ui.ask("Enter password for su - #{config[:su_user]}@#{server_name}:", echo: false)
          retry
        else
          raise
        end
      end

      def connect!
        ui.info("Connecting to #{ui.color(server_name, :bold)} using #{connection_protocol}")
        opts ||= connection_opts.dup
        do_connect(opts)
      rescue Train::Error => e
        # We handle these by message text only because train only loads the
        # transports and protocols that it needs - so the exceptions may not be defined,
        # and we don't want to require files internal to train.
        if e.message =~ /fingerprint (\S+) is unknown for "(.+)"/ # Train::Transports::SSHFailed
          fingerprint = $1
          hostname, ip = $2.split(",")
          # TODO: convert the SHA256 base64 value to hex with colons
          # 'ssh' example output:
          # RSA key fingerprint is e5:cb:c0:e2:21:3b:12:52:f8:ce:cb:00:24:e2:0c:92.
          # ECDSA key fingerprint is 5d:67:61:08:a9:d7:01:fd:5e:ae:7e:09:40:ef:c0:3c.
          # will exit 3 on N
          ui.confirm <<~EOM
            The authenticity of host '#{hostname} (#{ip})' can't be established.
            fingerprint is #{fingerprint}.

            Are you sure you want to continue connecting
          EOM
          # FIXME: this should save the key to known_hosts but doesn't appear to be
          config[:ssh_verify_host_key] = :accept_new
          conn_opts = connection_opts(reset: true)
          opts.merge! conn_opts
          retry
        elsif (ssh? && e.cause && e.cause.class == Net::SSH::AuthenticationFailed) || (ssh? && e.class == Train::ClientError && e.reason == :no_ssh_password_or_key_available)
          if connection.password_auth?
            raise
          else
            ui.warn("Failed to authenticate #{opts[:user]} to #{server_name} - trying password auth")
            password = ui.ask("Enter password for #{opts[:user]}@#{server_name}:", echo: false)
          end

          opts.merge! force_ssh_password_opts(password)
          retry
        else
          raise
        end
      rescue RuntimeError => e
        if winrm? && e.message == "password is a required option"
          if connection.password_auth?
            raise
          else
            ui.warn("Failed to authenticate #{opts[:user]} to #{server_name} - trying password auth")
            password = ui.ask("Enter password for #{opts[:user]}@#{server_name}:", echo: false)
          end

          opts.merge! force_winrm_password_opts(password)
          retry
        else
          raise
        end
      end

      def handle_ssh_error(e); end

      # url values override CLI flags, if you provide both
      # we'll use the one that you gave in the URL.
      def connection_protocol
        return @connection_protocol if @connection_protocol

        from_url = host_descriptor =~ %r{^(.*)://} ? $1 : nil
        from_knife = config[:connection_protocol]
        @connection_protocol = from_url || from_knife || "ssh"
      end

      def do_connect(conn_options)
        @connection = TrainConnector.new(host_descriptor, connection_protocol, conn_options)
        connection.connect!
      rescue Train::UserError => e
        limit ||= 1
        if !conn_options.key?(:pty) && e.reason == :sudo_no_tty
          ui.warn("#{e.message} - trying with pty request")
          conn_options[:pty] = true # ensure we can talk to systems with requiretty set true in sshd config
          retry
        elsif config[:use_sudo_password] && (e.reason == :sudo_password_required || e.reason == :bad_sudo_password) && limit < 3
          ui.warn("Failed to authenticate #{conn_options[:user]} to #{server_name} - #{e.message} \n sudo: #{limit} incorrect password attempt")
          sudo_password = ui.ask("Enter sudo password for #{conn_options[:user]}@#{server_name}:", echo: false)
          limit += 1
          conn_options[:sudo_password] = sudo_password

          retry
        else
          raise
        end
      end

      # Fail if both first_boot_attributes and first_boot_attributes_from_file
      # are set.
      def validate_first_boot_attributes!
        if @config[:first_boot_attributes] && @config[:first_boot_attributes_from_file]
          raise Chef::Exceptions::BootstrapCommandInputError
        end

        true
      end

      # FIXME: someone needs to clean this up properly:  https://github.com/chef/chef/issues/9645
      # This code is deliberately left without an abstraction around deprecating the config options to avoid knife plugins from
      # using those methods (which will need to be deprecated and break them) via inheritance (ruby does not have a true `private`
      # so the lack of any inheritable implementation is because of that).
      #
      def winrm_auth_method
        config.key?(:winrm_auth_method) ? config[:winrm_auth_method] : config.key?(:winrm_authentications_protocol) ? config[:winrm_authentication_protocol] : "negotiate" # rubocop:disable Style/NestedTernaryOperator
      end

      def ssh_verify_host_key
        config.key?(:ssh_verify_host_key) ? config[:ssh_verify_host_key] : config.key?(:host_key_verify) ? config[:host_key_verify] : "always" # rubocop:disable Style/NestedTernaryOperator
      end

      # Fail if using plaintext auth without ssl because
      # this can expose keys in plaintext on the wire.
      # TODO test for this method
      # TODO check that the protocol is valid.
      def validate_winrm_transport_opts!
        return true unless winrm?

        if Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key]))
          if winrm_auth_method == "plaintext" &&
              config[:winrm_ssl] != true
            ui.error <<~EOM
              Validatorless bootstrap over unsecure winrm channels could expose your
              key to network sniffing.
               Please use a 'winrm_auth_method' other than 'plaintext',
              or enable ssl on #{server_name} then use the ---winrm-ssl flag
              to connect.
            EOM

            exit 1
          end
        end
        true
      end

      # fail if the server_name is nil
      def validate_name_args!
        if server_name.nil?
          ui.error("Must pass an FQDN or ip to bootstrap")
          exit 1
        end
      end

      # Ensure options are valid by checking policyfile values.
      #
      # The method call will cause the program to exit(1) if:
      #   * Only one of --policy-name and --policy-group is specified
      #   * Policyfile options are set and --run-list is set as well
      #
      # @return [TrueClass] If options are valid.
      def validate_policy_options!
        if incomplete_policyfile_options?
          ui.error("--policy-name and --policy-group must be specified together")
          exit 1
        elsif policyfile_and_run_list_given?
          ui.error("Policyfile options and --run-list are exclusive")
          exit 1
        end
      end

      # Ensure a valid protocol is provided for target host connection
      #
      # The method call will cause the program to exit(1) if:
      #   * Conflicting protocols are given via the target URI and the --protocol option
      #   * The protocol is not a supported protocol
      #
      # @return [TrueClass] If options are valid.
      def validate_protocol!
        from_cli = config[:connection_protocol]
        if from_cli && connection_protocol != from_cli
          # Hanging indent to align with the ERROR: prefix
          ui.error <<~EOM
            The URL '#{host_descriptor}' indicates protocol is '#{connection_protocol}'
            while the --protocol flag specifies '#{from_cli}'.  Please include
            only one or the other.
          EOM
          exit 1
        end

        unless SUPPORTED_CONNECTION_PROTOCOLS.include?(connection_protocol)
          ui.error <<~EOM
            Unsupported protocol '#{connection_protocol}'.

            Supported protocols are: #{SUPPORTED_CONNECTION_PROTOCOLS.join(" ")}
          EOM
          exit 1
        end
        true
      end

      # Validate any additional options
      #
      # Plugins that subclass bootstrap, e.g. knife-ec2, can use this method to validate any additional options before any other actions are executed
      #
      # @return [TrueClass] If options are valid or exits
      def plugin_validate_options!
        true
      end

      # Create the server that we will bootstrap, if necessary
      #
      # Plugins that subclass bootstrap, e.g. knife-ec2, can use this method to call out to an API to build an instance of the server we wish to bootstrap
      #
      # @return [TrueClass] If instance successfully created, or exits
      def plugin_create_instance!
        true
      end

      # Perform any setup necessary by the plugin
      #
      # Plugins that subclass bootstrap, e.g. knife-ec2, can use this method to create connection objects
      #
      # @return [TrueClass] If instance successfully created, or exits
      def plugin_setup!; end

      # Perform any teardown or cleanup necessary by the plugin
      #
      # Plugins that subclass bootstrap, e.g. knife-ec2, can use this method to display a message or perform any cleanup
      #
      # @return [void]
      def plugin_finalize; end

      # If session_timeout is too short, it is likely
      # a holdover from "--winrm-session-timeout" which used
      # minutes as its unit, instead of seconds.
      # Warn the human so that they are not surprised.
      #
      def warn_on_short_session_timeout
        if session_timeout && session_timeout <= 15
          ui.warn <<~EOM
            You provided '--session-timeout #{session_timeout}' second(s).
            Did you mean '--session-timeout #{session_timeout * 60}' seconds?
          EOM
        end
      end

      def winrm_warn_no_ssl_verification
        return unless winrm?

        # REVIEWER NOTE
        # The original check from knife plugin did not include winrm_ssl_peer_fingerprint
        # Reference:
        # https://github.com/chef/knife-windows/blob/92d151298142be4a4750c5b54bb264f8d5b81b8a/lib/chef/knife/winrm_knife_base.rb#L271-L273
        # TODO Seems like we should also do a similar warning if ssh_verify_host == false
        if config[:ca_trust_file].nil? &&
            config[:winrm_no_verify_cert] &&
            config[:winrm_ssl_peer_fingerprint].nil?
          ui.warn <<~WARN
            * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
            SSL validation of HTTPS requests for the WinRM transport is disabled.
            HTTPS WinRM connections are still encrypted, but knife is not able
            to detect forged replies or spoofing attacks.

            To work around this issue you can use the flag `--winrm-no-verify-cert`
            or add an entry like this to your knife configuration file:

               # Verify all WinRM HTTPS connections
               knife[:winrm_no_verify_cert] = true

            You can also specify a ca_trust_file via --ca-trust-file,
            or the expected fingerprint of the target host's certificate
            via --winrm-ssl-peer-fingerprint.
          WARN
        end
      end

      # @return a configuration hash suitable for connecting to the remote
      # host via train
      def connection_opts(reset: false)
        return @connection_opts unless @connection_opts.nil? || reset == true

        @connection_opts = {}
        @connection_opts.merge! base_opts
        @connection_opts.merge! host_verify_opts
        @connection_opts.merge! gateway_opts
        @connection_opts.merge! sudo_opts
        @connection_opts.merge! winrm_opts
        @connection_opts.merge! ssh_opts
        @connection_opts.merge! ssh_identity_opts
        @connection_opts
      end

      def winrm?
        connection_protocol == "winrm"
      end

      def ssh?
        connection_protocol == "ssh"
      end

      # Common configuration for all protocols
      def base_opts
        port = config_for_protocol(:port)
        user = config_for_protocol(:user)
        {}.tap do |opts|
          opts[:logger] = Chef::Log
          opts[:password] = config[:connection_password] if config.key?(:connection_password)
          opts[:user] = user if user
          opts[:max_wait_until_ready] = config[:max_wait].to_f unless config[:max_wait].nil?
          # TODO - when would we need to provide rdp_port vs port?  Or are they not mutually exclusive?
          opts[:port] = port if port
        end
      end

      def host_verify_opts
        if winrm?
          { self_signed: config[:winrm_no_verify_cert] === true }
        elsif ssh?
          # Fall back to the old knife config key name for back compat.
          { verify_host_key: ssh_verify_host_key }
        else
          {}
        end
      end

      def ssh_opts
        opts = {}
        return opts if winrm?

        opts[:non_interactive] = true # Prevent password prompts from underlying net/ssh
        opts[:forward_agent] = (config[:ssh_forward_agent] === true)
        opts[:connection_timeout] = session_timeout
        opts
      end

      def ssh_identity_opts
        opts = {}
        return opts if winrm?

        identity_file = config[:ssh_identity_file]
        if identity_file
          opts[:key_files] = [identity_file]
          # We only set keys_only based on the explicit ssh_identity_file;
          # someone may use a gateway key and still expect password auth
          # on the target.  Similarly, someone may have a default key specified
          # in knife config, but have provided a password on the CLI.

          # REVIEW NOTE: this is a new behavior. Originally, ssh_identity_file
          # could only be populated from CLI options, so there was no need to check
          # for this. We will also set keys_only to false only if there are keys
          # and no password.
          # If both are present, train(via net/ssh)  will prefer keys, falling back to password.
          # Reference: https://github.com/chef/chef/blob/master/lib/chef/knife/ssh.rb#L272
          opts[:keys_only] = config.key?(:connection_password) == false
        else
          opts[:key_files] = []
          opts[:keys_only] = false
        end

        gateway_identity_file = config[:ssh_gateway] ? config[:ssh_gateway_identity] : nil
        unless gateway_identity_file.nil?
          opts[:key_files] << gateway_identity_file
        end

        opts
      end

      def gateway_opts
        opts = {}
        if config[:ssh_gateway]
          split = config[:ssh_gateway].split("@", 2)
          if split.length == 1
            gw_host = split[0]
          else
            gw_user = split[0]
            gw_host = split[1]
          end
          gw_host, gw_port = gw_host.split(":", 2)
          # TODO - validate convertible port in config validation?
          gw_port = Integer(gw_port) rescue nil
          opts[:bastion_host] = gw_host
          opts[:bastion_user] = gw_user
          opts[:bastion_port] = gw_port
        end
        opts
      end

      # use_sudo - tells bootstrap to use the sudo command to run bootstrap
      # use_sudo_password - tells bootstrap to use the sudo command to run bootstrap
      #                     and to use the password specified with --password
      # TODO: I'd like to make our sudo options sane:
      # --sudo (bool) - use sudo
      # --sudo-password PASSWORD (default:  :password) - use this password for sudo
      # --sudo-options "opt,opt,opt" to pass into sudo
      # --sudo-command COMMAND sudo command other than sudo
      # REVIEW NOTE: knife bootstrap did not pull sudo values from Chef::Config,
      #              should we change that for consistency?
      def sudo_opts
        return {} if winrm?

        opts = { sudo: false }
        if config[:use_sudo]
          opts[:sudo] = true
          if config[:use_sudo_password]
            opts[:sudo_password] = config[:connection_password]
          end
          if config[:preserve_home]
            opts[:sudo_options] = "-H"
          end
        end
        opts
      end

      def winrm_opts
        return {} unless winrm?

        opts = {
          winrm_transport: winrm_auth_method, # winrm gem and train calls auth method 'transport'
          winrm_basic_auth_only: config[:winrm_basic_auth_only] || false,
          ssl: config[:winrm_ssl] === true,
          ssl_peer_fingerprint: config[:winrm_ssl_peer_fingerprint],
        }

        if winrm_auth_method == "kerberos"
          opts[:kerberos_service] = config[:kerberos_service] if config[:kerberos_service]
          opts[:kerberos_realm] = config[:kerberos_realm] if config[:kerberos_service]
        end

        if config[:ca_trust_file]
          opts[:ca_trust_path] = config[:ca_trust_file]
        end

        opts[:operation_timeout] = session_timeout

        opts
      end

      # Config overrides to force password auth.
      def force_ssh_password_opts(password)
        {
          password: password,
          non_interactive: false,
          keys_only: false,
          key_files: [],
          auth_methods: %i{password keyboard_interactive},
        }
      end

      def force_winrm_password_opts(password)
        {
          password: password,
        }
      end

      # This is for deprecating config options. The fallback_key can be used
      # to pull an old knife config option out of the config file when the
      # cli value has been renamed.  This is different from the deprecated
      # cli values, since these are for config options that have no corresponding
      # cli value.
      #
      # DO NOT USE - this whole API is considered deprecated
      #
      # @api deprecated
      #
      def config_value(key, fallback_key = nil, default = nil)
        Chef.deprecated(:knife_bootstrap_apis, "Use of config_value is deprecated.  Knife plugin authors should access the config hash directly, which does correct merging of cli and config options.")
        if config.key?(key)
          # the first key is the primary key so we check the merged hash first
          config[key]
        elsif config.key?(fallback_key)
          # we get the old config option here (the deprecated cli option shouldn't exist)
          config[fallback_key]
        else
          default
        end
      end

      def upload_bootstrap(content)
        script_name = connection.windows? ? "bootstrap.bat" : "bootstrap.sh"
        remote_path = connection.normalize_path(File.join(connection.temp_dir, script_name))
        connection.upload_file_content!(content, remote_path)
        remote_path
      end

      # build the command string for bootstrapping
      # @return String
      def bootstrap_command(remote_path)
        if connection.windows?
          "cmd.exe /C #{remote_path}"
        else
          cmd = "sh #{remote_path}"

          if config[:su_user]
            # su - USER is subject to required an interactive console
            # Otherwise, it will raise: su: must be run from a terminal
            set_transport_options(pty: true)
            cmd = "su - #{config[:su_user]} -c '#{cmd}'"
            cmd = "sudo " << cmd if config[:use_sudo]
          end

          cmd
        end
      end

      private

      # To avoid cluttering the CLI options, some flags (such as port and user)
      # are shared between protocols.  However, there is still a need to allow the operator
      # to specify defaults separately, since they may not be the same values for different
      # protocols.

      # These keys are available in Chef::Config, and are prefixed with the protocol name.
      # For example, :user CLI option will map to :winrm_user and :ssh_user Chef::Config keys,
      # based on the connection protocol in use.

      # @api private
      def config_for_protocol(option)
        if option == :port
          config[:connection_port] || config[knife_key_for_protocol(option)]
        else
          config[:connection_user] || config[knife_key_for_protocol(option)]
        end
      end

      # @api private
      def knife_key_for_protocol(option)
        "#{connection_protocol}_#{option}".to_sym
      end

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

      # session_timeout option has a default that may not arrive, particularly if
      # we're being invoked from a plugin that doesn't merge_config.
      def session_timeout
        timeout = config[:session_timeout]
        return options[:session_timeout][:default] if timeout.nil?

        timeout.to_i
      end

      # Train::Transports::SSH::Connection#transport_options
      # Append the options to connection transport_options
      #
      # @param opts [Hash] the opts to be added to connection transport_options.
      # @return [Hash] transport_options if the opts contains any option to be set.
      #
      def set_transport_options(opts)
        return unless opts.is_a?(Hash) || !opts.empty?

        connection&.connection&.transport_options&.merge! opts
      end
    end
  end
end
