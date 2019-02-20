#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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
require "chef/knife/bootstrap/options"

class Chef
  class Knife
    class Bootstrap < Knife
      include DataBagSecretOptions
      # Command line flags and options for bootstrap - there's a large number of them
      # so we'll keep this file a little smaller by splitting them out.
      include Bootstrap::Options

      SUPPORTED_CONNECTION_PROTOCOLS = %w{ssh winrm}

      attr_accessor :client_builder
      attr_accessor :chef_vault_handler
      attr_reader   :target_host

      deps do
        require "chef/json_compat"
        require "tempfile"
        require "chef_core/text" # i18n and standardized error structures
        require "chef_core/target_host"
        require "chef_core/target_resolver"
      end

      banner "knife bootstrap [PROTOCOL://][USER@]FQDN (options)"

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

      # The default bootstrap template to use to bootstrap a server.
      # This is a public API hook which knife plugins use or inherit and override.
      #
      # @return [String] Default bootstrap template
      def default_bootstrap_template
        if target_host.base_os == :windows
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
        if File.exists?(template)
          Chef::Log.trace("Using the specified bootstrap template: #{File.dirname(template)}")
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
          Chef::Log.trace("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          File.exists?(bootstrap_template)
        end

        unless template_file
          ui.info("Can not find bootstrap definition for #{template}")
          raise Errno::ENOENT
        end

        Chef::Log.trace("Found bootstrap template in #{File.dirname(template_file)}")

        template_file
      end

      def secret
        @secret ||= encryption_secret_provided_ignore_encrypt_flag? ? read_secret : nil
      end

      # Establish bootstrap context for template rendering.
      # Requires target_host to be a live connection in order to determine
      # the correct platform.
      def bootstrap_context
        @bootstrap_context ||=
          if target_host.base_os == :windows
            require "chef/knife/core/windows_bootstrap_context"
            Knife::Core::WindowsBootstrapContext.new(config, config[:run_list], Chef::Config, secret)
          else
            require "chef/knife/core/bootstrap_context"
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
        validate_name_args!
        validate_protocol!
        validate_first_boot_attributes!
        validate_winrm_transport_opts!
        validate_policy_options!

        winrm_warn_no_ssl_verification

        $stdout.sync = true
        register_client
        connect!
        unless client_builder.client_path.nil?
          bootstrap_context.client_pem = client_builder.client_path
        end
        content = render_template
        bootstrap_path = upload_bootstrap(content)
        perform_bootstrap(bootstrap_path)
      ensure
        target_host.del_file(bootstrap_path) if target_host && bootstrap_path
      end

      def register_client
        # chef-vault integration must use the new client-side hawtness, otherwise to use the
        # new client-side hawtness, just delete your validation key.
        # 2019-04-01 TODO
        # TODO -  should this raise if config says to use vault because json/file/item exists
        #         but we still have a validation key?  That means we can't use the new client hawtness,
        #         but we also don't tell the operator that their requested vault operations
        #         won't be performed
        if chef_vault_handler.doing_chef_vault? ||
            (Chef::Config[:validation_key] &&
             !File.exist?(File.expand_path(Chef::Config[:validation_key])))

          unless config[:chef_node_name]
            ui.error("You must pass a node name with -N when bootstrapping with user credentials")
            exit 1
          end
          client_builder.run
          chef_vault_handler.run(client_builder.client)
        else
          ui.info <<~EOM
              Doing old-style registration with the validation key at #{Chef::Config[:validation_key]}..."
              Delete your validation key in order to use your user credentials instead
            EOM

        end
      end


      def perform_bootstrap(remote_bootstrap_script_path)
        ui.info("Bootstrapping #{ui.color(server_name, :bold)}")
        cmd = bootstrap_command(remote_bootstrap_script_path)
        r = target_host.run_command(cmd) do |data|
          ui.msg("#{ui.color(" [#{target_host.hostname}]", :cyan)} #{data}")
        end
        if r.exit_status != 0
          ui.error("The following error occurred on #{server_name}:")
          ui.error(r.stderr)
          exit 1
        end
      end

      def connect!

        ui.info("Connecting to #{ui.color(server_name, :bold)}")
        opts = connection_opts.dup
        do_connect(opts)
      rescue => e
        # Ugh. TODO: Train raises a Train::Transports::SSHFailed for a number of different errors. chef_core makes that
        # a more general ConnectionFailed, with an error code based on the specific error text/reason provided from trainm.
        # This means we have to look three layers into the exception to find out what actually happened instead of just
        # looking at the exception type
        #
        # It doesn't help to provide our own error if it does't let the caller know what they need to identify the problem.
        # Let's update chef_core to be a bit smarter about resolving the errors to an appropriate exception type
        # (eg ChefCore::ConnectionFailed::AuthError or similar) that will work across protocols, instead of just a single
        # ConnectionFailure type
        #

        if e.cause && e.cause.cause && e.cause.cause.class == Net::SSH::AuthenticationFailed
          if opts[:password]
            raise
          else
            ui.warn("Failed to authenticate #{opts[:user]} to #{server_name} - trying password auth")
            password = ui.ask("Enter password for #{opts[:user]}@#{server_name} - trying password auth") do |q|
              q.echo = false
            end
          end
          opts.merge! force_ssh_password_opts(password)
          do_connect(opts)
        else
          raise
        end
      end

      def connection_protocol
        return @connection_protocol if @connection_protocol
        from_url = host_descriptor  =~ /^(.*):\/\// ? $1 : nil
        from_cli = config[:connection_protocol]
        from_knife = Chef::Config[:knife][:connection_protocol]
        @connection_protocol = from_url || from_cli || from_knife || "ssh"
      end

      def do_connect(conn_options)
        # Resolve the given host name to a TargetHost instance. We will limit
        # the number of hosts to 1 (effectivly eliminating wildcard support) since
        # we only support running bootstrap against one host at a time.
        resolver = ChefCore::TargetResolver.new(host_descriptor, connection_protocol,
                                                conn_options, max_expanded_targets: 1)
        @target_host = resolver.targets.first
        target_host.connect!
        target_host
      end

      # Fail if both first_boot_attributes and first_boot_attributes_from_file
      # are set.
      def validate_first_boot_attributes!
        if @config[:first_boot_attributes] && @config[:first_boot_attributes_from_file]
          raise Chef::Exceptions::BootstrapCommandInputError
        end
        true
      end

      # Fail if using plaintext auth without ssl because
      # this can expose keys in plaintext on the wire.
      # TODO test for this method
      # TODO check that the protoocol is valid.
      def validate_winrm_transport_opts!
        return true if connection_protocol != "winrm"


        if (Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key])))
          if (config_value(:winrm_auth_method) == "plaintext" &&
              config_value(:winrm_ssl) != true)
            ui.error <<~EOM
                      Validatorless bootstrap over unsecure winrm channels could expose your
                      key to network sniffing.

                      Please use a 'winrm_auth_method' other than 'plaintext',
                      or enable ssl on #{server_name} then use the --ssl flag
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
        if (from_cli && connection_protocol != from_cli)
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

      def winrm_warn_no_ssl_verification
        return if connection_protocol != "winrm"

        # REVIEWER NOTE
        # The original check from knife plugin did not include winrm_ssl_peer_fingerprint
        # Reference:
        # https://github.com/chef/knife-windows/blob/92d151298142be4a4750c5b54bb264f8d5b81b8a/lib/chef/knife/winrm_knife_base.rb#L271-L273
        # TODO Seems like we should also do a similar warning if ssh_verify_host == false
        if config_value(:ca_trust_file).nil? &&
            config_value(:winrm_no_verify_cert) &&
            config_value(:winrm_ssl_peer_fingerprint).nil?
          ui.warn <<~WARN
            * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
            SSL validation of HTTPS requests for the WinRM transport is disabled.
            HTTPS WinRM # connections are still encrypted, but knife is not able
            to detect forged replies # or spoofing attacks.

            To fix this issue add an entry like this to your knife configuration file:

               # Verify all WinRM HTTPS connections (default, recommended)
               knife[:winrm_no_verify_cert] = false

            You can also specify a ca_trust_file via --ca-trust-file,
            or the expected fingerprint of the target host via
            --winrm-ssl-peer-fingerprint.
          WARN
        end
      end

        #

      # Create a configuration hash for TargetHost to connect
      # to the remote host via Train.
      #
      # @return a configuration hash suitable for connecting to the remote
      # host via TargetHost.
      def connection_opts
        return @connection_opts unless @connection_opts.nil?
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

      # Common configuration for all protocols
      def base_opts
        #
        port = config_value(:connection_port,
                            knife_key_for_protocol(connection_protocol, :port))
        user = config_value(:connection_user,
                            knife_key_for_protocol(connection_protocol, :user))
        {}.tap do |opts|
          opts[:logger] = Chef::Log
          # We do not store password in Chef::Config, so only use CLI `config` here
          opts[:password] = config[:password] if config.key?(:password)
          opts[:user] = user if user
          opts[:max_wait_until_ready] = config_value(:max_wait) unless config_value(:max_wait).nil?
          # TODO - when would we need to provide rdp_port vs port?  Or are they not mutually exclusive?
          opts[:port] = port if port
        end
      end

      def host_verify_opts
        case connection_protocol
        when "winrm"
          { self_signed: config_value(:winrm_no_verify_cert) === true }
        when "ssh"
          # TODO is this a safe footgun to provide?  Seems a security risk
          #      if someone forgets to If someone forgets ssh_verify_host_key is
          #      is in knife config, s- setting ssh_verify_host_key to true
          # in knife.rb, and forgetting it's there?
          { verify_host_key: config_value(:ssh_verify_host_key,
                                          :host_key_verify, true) === true }
        else
          {}
        end
      end

      def ssh_opts
        opts = {}
        return opts if connection_protocol == "winrm"
        opts[:forward_agent] = (config_value(:ssh_forward_agent) === true)
        opts
      end

      def ssh_identity_opts
        opts = {}
        return opts if connection_protocol == "winrm"
        identity_file = config_value(:ssh_identity_file)
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
          opts[:keys_only] = config.key?(:password) == false
        else
          opts[:key_files] = []
          opts[:keys_only] = false
        end

        gateway_identity_file = config_value(:ssh_gateway) ? config_value(:ssh_gateway_identity) : nil
        unless gateway_identity_file.nil?
          opts[:key_files] << gateway_identity_file
        end

        opts
      end

      def gateway_opts
        opts = {}
        if config_value(:ssh_gateway)
          split = config_value(:ssh_gateway).split("@", 2)
          if split.length == 1
            gw_host = split[0]
          else
            gw_user = split[0]
            gw_host = split[1]
          end
          gw_host, gw_port = gw_host.split(":", 2)
          # TODO - validate convertable port in config validation?
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
        return {} if connection_protocol == "winrm"
        opts = { sudo: false }
        if config[:use_sudo]
          opts[:sudo] = true
          if config[:use_sudo_password]
            opts[:sudo_password] = config[:password]
          end
          if config[:preserve_home]
             opts[:sudo_options] = "-H"
          end
        end
        opts
      end

      def winrm_opts
        return {} unless connection_protocol == "winrm"
        auth_method = config_value(:winrm_auth_method, :winrm_auth_method, "negotiate")
        opts = {
          winrm_transport: auth_method, # winrm gem and train calls auth method 'transport'
          winrm_basic_auth_only: config_value(:winrm_basic_auth_only) || false,
          ssl: config_value(:winrm_ssl) === true,
          ssl_peer_fingerprint: config_value(:winrm_ssl_peer_fingerprint)
        }

        if auth_method == "kerberos"
          opts[:kerberos_service] = config_value(:kerberos_service) if config_value(:kerberos_service)
          opts[:kerberos_realm] = config_value(:kerberos_realm) if config_value(:kerberos_service)
        end

        if config_value(:ca_trust_file)
          opts[:ca_trust_file] = config_value(:ca_trust_file)
        end

        opts[:operation_timeout] = config_value(:winrm_session_timeout) || 60

        opts
      end


      # Config overrides to force password auth.
      def force_ssh_password_opts(password)
        {
          password: password,
          non_interactive: false,
          keys_only: false,
          key_files: [],
          auth_methods: [:password, :keyboard_interactive]
        }
      end

      # Looks up configuration entries, first in the class member
      # `config` which contains options populated from CLI flags.
      # If the entry is not found there, Chef::Config[:knife][KEY]
      # is checked.
      #
      # knife_config_key should be specified if the knife config lookup
      # key is different from the CLI flag lookup key.
      #
      def config_value(key, knife_config_key = nil, default = nil)
        if config.key? key
          config[key]
        else
          lookup_key = knife_config_key || key
          if Chef::Config[:knife].key?(lookup_key)
            Chef::Config[:knife][lookup_key]
          else
            default
          end
        end
      end

      # Tells us where a config value has come from ,
      # :cli_config, :knife_config, :not_found
      def config_source(key, knife_config_key = nil)
        return :cli_config if config.key? key
        return :knife_config if config.key?(key) || config.key?(knife_config_key)
        :not_found
      end


      def upload_bootstrap(content)
        script_name = target_host.base_os == :windows ? "bootstrap.bat" : "bootstrap.sh"
        remote_path = target_host.normalize_path(File.join(target_host.temp_dir, script_name))
        target_host.save_as_remote_file(content, remote_path)
        remote_path
      end


      # build the command string for bootrapping
      # @return String
      def bootstrap_command(remote_path)
        if target_host.base_os == :windows
          "cmd.exe /C #{remote_path}"
        else
          "sh #{remote_path}"
        end
      end


      # To avoid cluttering the CLI options, some flags (such as port and user)
      # are shared between protocols.  However, there is still a need to allow the operator
      # to specify defaults separately, since they may not be the same values for different protocols.
      #
      # These keys are available in Chef::Config, and are prefixed with the protocol name.
      # For example, :user CLI option will map to :winrm_user and :ssh_user Chef::Config keys,
      # based on the connection protocol in use.
      def knife_key_for_protocol(protocol, option)
        "#{connection_protocol}_#{option.to_s}".to_sym
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
