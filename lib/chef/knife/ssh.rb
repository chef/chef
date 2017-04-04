#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2009-2017, Chef Software Inc.
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

require "chef/mixin/shell_out"
require "chef/knife"

class Chef
  class Knife
    class Ssh < Knife

      deps do
        require "net/ssh"
        require "net/ssh/multi"
        require "readline"
        require "chef/exceptions"
        require "chef/search/query"
        require "chef/util/path_helper"
        require "mixlib/shellout"
      end

      include Chef::Mixin::ShellOut

      attr_writer :password

      banner "knife ssh QUERY COMMAND (options)"

      option :concurrency,
        :short => "-C NUM",
        :long => "--concurrency NUM",
        :description => "The number of concurrent connections",
        :default => nil,
        :proc => lambda { |o| o.to_i }

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "The attribute to use for opening the connection - default depends on the context",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_attribute] = key.strip }

      option :manual,
        :short => "-m",
        :long => "--manual-list",
        :boolean => true,
        :description => "QUERY is a space separated list of servers",
        :default => false

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username"

      option :ssh_password_ng,
        :short => "-P [PASSWORD]",
        :long => "--ssh-password [PASSWORD]",
        :description => "The ssh password - will prompt if flag is specified but no password is given",
        # default to a value that can not be a password (boolean)
        # so we can effectively test if this parameter was specified
        # without a value
        :default => false

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key.strip }

      option :ssh_timeout,
        :short => "-t SECONDS",
        :long => "--ssh-timeout SECONDS",
        :description => "The ssh connection timeout",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_timeout] = key.strip.to_i },
        :default => 120

      option :ssh_gateway,
        :short => "-G GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key.strip }

      option :ssh_gateway_identity,
        :long => "--ssh-gateway-identity SSH_GATEWAY_IDENTITY",
        :description => "The SSH identity file used for gateway authentication"

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

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :on_error,
        :short => "-e",
        :long => "--exit-on-error",
        :description => "Immediately exit if an error is encountered",
        :boolean => true,
        :proc => Proc.new { :raise }

      option :tmux_split,
        :long => "--tmux-split",
        :description => "Split tmux window.",
        :boolean => true,
        :default => false

      def session
        config[:on_error] ||= :skip
        ssh_error_handler = Proc.new do |server|
          case config[:on_error]
          when :skip
            ui.warn "Failed to connect to #{server.host} -- #{$!.class.name}: #{$!.message}"
            $!.backtrace.each { |l| Chef::Log.debug(l) }
          when :raise
            #Net::SSH::Multi magic to force exception to be re-raised.
            throw :go, :raise
          end
        end

        @session ||= Net::SSH::Multi.start(:concurrent_connections => config[:concurrency], :on_error => ssh_error_handler)
      end

      def configure_gateway
        config[:ssh_gateway] ||= Chef::Config[:knife][:ssh_gateway]
        if config[:ssh_gateway]
          gw_host, gw_user = config[:ssh_gateway].split("@").reverse
          gw_host, gw_port = gw_host.split(":")
          gw_opts = session_options(gw_host, gw_port, gw_user)
          user = gw_opts.delete(:user)

          begin
            # Try to connect with a key.
            session.via(gw_host, user, gw_opts)
          rescue Net::SSH::AuthenticationFailed
            prompt = "Enter the password for #{user}@#{gw_host}: "
            gw_opts[:password] = prompt_for_password(prompt)
            # Try again with a password.
            session.via(gw_host, user, gw_opts)
          end
        end
      end

      def configure_session
        list = config[:manual] ? @name_args[0].split(" ") : search_nodes
        if list.length == 0
          if @search_count == 0
            ui.fatal("No nodes returned from search")
          else
            ui.fatal("#{@search_count} #{@search_count > 1 ? "nodes" : "node"} found, " +
                     "but does not have the required attribute to establish the connection. " +
                     "Try setting another attribute to open the connection using --attribute.")
          end
          exit 10
        end
        session_from_list(list)
      end

      def get_ssh_attribute(node)
        # Order of precedence for ssh target
        # 1) command line attribute
        # 2) configuration file
        # 3) cloud attribute
        # 4) fqdn
        if node["config"]
          Chef::Log.debug("Using node attribute '#{config[:attribute]}' as the ssh target: #{node["config"]}")
          node["config"]
        elsif Chef::Config[:knife][:ssh_attribute]
          Chef::Log.debug("Using node attribute #{Chef::Config[:knife][:ssh_attribute]}: #{node["knife_config"]}")
          node["knife_config"]
        elsif node["cloud"] &&
            node["cloud"]["public_hostname"] &&
            !node["cloud"]["public_hostname"].empty?
          Chef::Log.debug("Using node attribute 'cloud[:public_hostname]' automatically as the ssh target: #{node["cloud"]["public_hostname"]}")
          node["cloud"]["public_hostname"]
        else
          # falling back to default of fqdn
          Chef::Log.debug("Using node attribute 'fqdn' as the ssh target: #{node["fqdn"]}")
          node["fqdn"]
        end
      end

      def search_nodes
        list = Array.new
        query = Chef::Search::Query.new
        required_attributes = { fqdn: ["fqdn"], cloud: ["cloud"] }

        separator = ui.presenter.attribute_field_separator

        # if we've set an attribute to use on the command line
        if config[:attribute]
          required_attributes[:config] = config[:attribute].split(separator)
        end

        # if we've configured an attribute in our config
        if Chef::Config[:knife][:ssh_attribute]
          required_attributes[:knife_config] = Chef::Config[:knife][:ssh_attribute].split(separator)
        end

        @search_count = 0
        query.search(:node, @name_args[0], filter_result: required_attributes, fuzz: true) do |item|
          @search_count += 1
          # we should skip the loop to next iteration if the item
          # returned by the search is nil
          next if item.nil?
          # next if we couldn't find the specified attribute in the
          # returned node object
          host = get_ssh_attribute(item)
          next if host.nil?
          ssh_port = item[:cloud].nil? ? nil : item[:cloud][:public_ssh_port]
          srv = [host, ssh_port]
          list.push(srv)
        end

        list
      end

      # Net::SSH session options hash for global options. These should be
      # options that will apply to the gateway connection in addition to the
      # main one.
      #
      # @since 12.5.0
      # @param host [String] Hostname for this session.
      # @param port [String] SSH port for this session.
      # @param user [String] Optional username for this session.
      # @return [Hash<Symbol, Object>]
      def session_options(host, port, user = nil)
        ssh_config = Net::SSH.configuration_for(host, true)
        {}.tap do |opts|
          # Chef::Config[:knife][:ssh_user] is parsed in #configure_user and written to config[:ssh_user]
          opts[:user] = user || config[:ssh_user] || ssh_config[:user]
          if config[:ssh_gateway_identity]
            opts[:keys] = File.expand_path(config[:ssh_gateway_identity])
            opts[:keys_only] = true
          elsif config[:ssh_identity_file]
            opts[:keys] = File.expand_path(config[:ssh_identity_file])
            opts[:keys_only] = true
          elsif config[:ssh_password]
            opts[:password] = config[:ssh_password]
          end
          # Don't set the keys to nil if we don't have them.
          forward_agent = config[:forward_agent] || ssh_config[:forward_agent]
          opts[:forward_agent] = forward_agent unless forward_agent.nil?
          port ||= ssh_config[:port]
          opts[:port] = port unless port.nil?
          opts[:logger] = Chef::Log.logger if Chef::Log.level == :debug
          if !config[:host_key_verify]
            opts[:paranoid] = false
            opts[:user_known_hosts_file] = "/dev/null"
          end
        end
      end

      def session_from_list(list)
        list.each do |item|
          host, ssh_port = item
          Chef::Log.debug("Adding #{host}")
          session_opts = session_options(host, ssh_port)
          # Handle port overrides for the main connection.
          session_opts[:port] = Chef::Config[:knife][:ssh_port] if Chef::Config[:knife][:ssh_port]
          session_opts[:port] = config[:ssh_port] if config[:ssh_port]
          # Handle connection timeout
          session_opts[:timeout] = Chef::Config[:knife][:ssh_timeout] if Chef::Config[:knife][:ssh_timeout]
          session_opts[:timeout] = config[:ssh_timeout] if config[:ssh_timeout]
          # Create the hostspec.
          hostspec = session_opts[:user] ? "#{session_opts.delete(:user)}@#{host}" : host
          # Connect a new session on the multi.
          session.use(hostspec, session_opts)

          @longest = host.length if host.length > @longest
        end

        session
      end

      def fixup_sudo(command)
        command.sub(/^sudo/, 'sudo -p \'knife sudo password: \'')
      end

      def print_data(host, data)
        @buffers ||= {}
        if leftover = @buffers[host]
          @buffers[host] = nil
          print_data(host, leftover + data)
        else
          if newline_index = data.index("\n")
            line = data.slice!(0...newline_index)
            data.slice!(0)
            print_line(host, line)
            print_data(host, data)
          else
            @buffers[host] = data
          end
        end
      end

      def print_line(host, data)
        padding = @longest - host.length
        str = ui.color(host, :cyan) + (" " * (padding + 1)) + data
        ui.msg(str)
      end

      def ssh_command(command, subsession = nil)
        exit_status = 0
        subsession ||= session
        command = fixup_sudo(command)
        command.force_encoding("binary") if command.respond_to?(:force_encoding)
        subsession.open_channel do |chan|
          if config[:on_error] && exit_status != 0
            chan.close()
          else
            chan.request_pty
            chan.exec command do |ch, success|
              raise ArgumentError, "Cannot execute #{command}" unless success
              ch.on_data do |ichannel, data|
                print_data(ichannel[:host], data)
                if data =~ /^knife sudo password: /
                  print_data(ichannel[:host], "\n")
                  ichannel.send_data("#{get_password}\n")
                end
              end
              ch.on_request "exit-status" do |ichannel, data|
                exit_status = [exit_status, data.read_long].max
              end
            end
          end
        end
        session.loop
        exit_status
      end

      def get_password
        @password ||= prompt_for_password
      end

      def prompt_for_password(prompt = "Enter your password: ")
        ui.ask(prompt) { |q| q.echo = false }
      end

      # Present the prompt and read a single line from the console. It also
      # detects ^D and returns "exit" in that case. Adds the input to the
      # history, unless the input is empty. Loops repeatedly until a non-empty
      # line is input.
      def read_line
        loop do
          command = reader.readline("#{ui.color('knife-ssh>', :bold)} ", true)

          if command.nil?
            command = "exit"
            puts(command)
          else
            command.strip!
          end

          unless command.empty?
            return command
          end
        end
      end

      def reader
        Readline
      end

      def interactive
        puts "Connected to #{ui.list(session.servers_for.collect { |s| ui.color(s.host, :cyan) }, :inline, " and ")}"
        puts
        puts "To run a command on a list of servers, do:"
        puts "  on SERVER1 SERVER2 SERVER3; COMMAND"
        puts "  Example: on latte foamy; echo foobar"
        puts
        puts "To exit interactive mode, use 'quit!'"
        puts
        loop do
          command = read_line
          case command
          when "quit!"
            puts "Bye!"
            break
          when /^on (.+?); (.+)$/
            raw_list = $1.split(" ")
            server_list = Array.new
            session.servers.each do |session_server|
              server_list << session_server if raw_list.include?(session_server.host)
            end
            command = $2
            ssh_command(command, session.on(*server_list))
          else
            ssh_command(command)
          end
        end
      end

      def screen
        tf = Tempfile.new("knife-ssh-screen")
        Chef::Util::PathHelper.home(".screenrc") do |screenrc_path|
          if File.exist? screenrc_path
            tf.puts("source #{screenrc_path}")
          end
        end
        tf.puts("caption always '%-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<'")
        tf.puts("hardstatus alwayslastline 'knife ssh #{@name_args[0]}'")
        window = 0
        session.servers_for.each do |server|
          tf.print("screen -t \"#{server.host}\" #{window} ssh ")
          tf.print("-i #{config[:ssh_identity_file]} ") if config[:ssh_identity_file]
          server.user ? tf.puts("#{server.user}@#{server.host}") : tf.puts(server.host)
          window += 1
        end
        tf.close
        exec("screen -c #{tf.path}")
      end

      def tmux
        ssh_dest = lambda do |server|
          identity = "-i #{config[:ssh_identity_file]} " if config[:ssh_identity_file]
          prefix = server.user ? "#{server.user}@" : ""
          "'ssh #{identity}#{prefix}#{server.host}'"
        end

        new_window_cmds = lambda do
          if session.servers_for.size > 1
            [""] + session.servers_for[1..-1].map do |server|
              if config[:tmux_split]
                "split-window #{ssh_dest.call(server)}; tmux select-layout tiled"
              else
                "new-window -a -n '#{server.host}' #{ssh_dest.call(server)}"
              end
            end
          else
            []
          end.join(" \\; ")
        end

        tmux_name = "'knife ssh #{@name_args[0].tr(':', '=')}'"
        begin
          server = session.servers_for.first
          cmd = ["tmux new-session -d -s #{tmux_name}",
                 "-n '#{server.host}'", ssh_dest.call(server),
                 new_window_cmds.call].join(" ")
          shell_out!(cmd)
          exec("tmux attach-session -t #{tmux_name}")
        rescue Chef::Exceptions::Exec
        end
      end

      def macterm
        begin
          require "appscript"
        rescue LoadError
          STDERR.puts "You need the rb-appscript gem to use knife ssh macterm. `(sudo) gem install rb-appscript` to install"
          raise
        end

        Appscript.app("/Applications/Utilities/Terminal.app").windows.first.activate
        Appscript.app("System Events").application_processes["Terminal.app"].keystroke("n", :using => :command_down)
        term = Appscript.app("Terminal")
        window = term.windows.first.get

        (session.servers_for.size - 1).times do |i|
          window.activate
          Appscript.app("System Events").application_processes["Terminal.app"].keystroke("t", :using => :command_down)
        end

        session.servers_for.each_with_index do |server, tab_number|
          cmd = "unset PROMPT_COMMAND; echo -e \"\\033]0;#{server.host}\\007\"; ssh #{server.user ? "#{server.user}@#{server.host}" : server.host}"
          Appscript.app("Terminal").do_script(cmd, :in => window.tabs[tab_number + 1].get)
        end
      end

      def cssh
        cssh_cmd = nil
        %w{csshX cssh}.each do |cmd|
          begin
            # Unix and Mac only
            cssh_cmd = shell_out!("which #{cmd}").stdout.strip
            break
          rescue Mixlib::ShellOut::ShellCommandFailed
          end
        end
        raise Chef::Exceptions::Exec, "no command found for cssh" unless cssh_cmd

        # pass in the consolidated identity file option to cssh(X)
        if config[:ssh_identity_file]
          cssh_cmd << " --ssh_args '-i #{File.expand_path(config[:ssh_identity_file])}'"
        end

        session.servers_for.each do |server|
          cssh_cmd << " #{server.user ? "#{server.user}@#{server.host}" : server.host}"
        end
        Chef::Log.debug("Starting cssh session with command: #{cssh_cmd}")
        exec(cssh_cmd)
      end

      def get_stripped_unfrozen_value(value)
        return nil if value.nil?
        value.strip
      end

      def configure_user
        config[:ssh_user] = get_stripped_unfrozen_value(config[:ssh_user] ||
                             Chef::Config[:knife][:ssh_user])
      end

      # This is a bit overly complicated because of the way we want knife ssh to work with -P causing a password prompt for
      # the user, but we have to be conscious that this code gets included in knife bootstrap and knife * server create as
      # well.  We want to change the semantics so that the default is false and 'nil' means -P without an argument on the
      # command line.  But the other utilities expect nil to be the default and we can't prompt in that case. So we effectively
      # use ssh_password_ng to determine if we're coming from knife ssh or from the other utilities.  The other utilties can
      # also be patched to use ssh_password_ng easily as long they follow the convention that the default is false.
      def configure_password
        if config.has_key?(:ssh_password_ng) && config[:ssh_password_ng].nil?
          # If the parameter is called on the command line with no value
          # it will set :ssh_password_ng = nil
          # This is where we want to trigger a prompt for password
          config[:ssh_password] = get_password
        else
          # if ssh_password_ng is false then it has not been set at all, and we may be in knife ec2 and still
          # using an old config[:ssh_password].  this is backwards compatibility.  all knife cloud plugins should
          # be updated to use ssh_password_ng with a default of false and ssh_password should be retired, (but
          # we'll still need to use the ssh_password out of knife.rb if we find that).
          ssh_password = config.has_key?(:ssh_password_ng) ? config[:ssh_password_ng] : config[:ssh_password]
          # Otherwise, the password has either been specified on the command line,
          # in knife.rb, or key based auth will be attempted
          config[:ssh_password] = get_stripped_unfrozen_value(ssh_password ||
                             Chef::Config[:knife][:ssh_password])
        end
      end

      def configure_ssh_identity_file
        # config[:identity_file] is DEPRECATED in favor of :ssh_identity_file
        config[:ssh_identity_file] = get_stripped_unfrozen_value(config[:ssh_identity_file] || config[:identity_file] || Chef::Config[:knife][:ssh_identity_file])
      end

      def configure_ssh_gateway_identity
        config[:ssh_gateway_identity] = get_stripped_unfrozen_value(config[:ssh_gateway_identity] || Chef::Config[:knife][:ssh_gateway_identity])
      end

      def run
        @longest = 0

        configure_user
        configure_password
        @password = config[:ssh_password] if config[:ssh_password]
        configure_ssh_identity_file
        configure_ssh_gateway_identity
        configure_gateway
        configure_session

        exit_status =
          case @name_args[1]
          when "interactive"
            interactive
          when "screen"
            screen
          when "tmux"
            tmux
          when "macterm"
            macterm
          when "cssh"
            cssh
          when "csshx"
            Chef::Log.warn("knife ssh csshx will be deprecated in a future release")
            Chef::Log.warn("please use knife ssh cssh instead")
            cssh
          else
            ssh_command(@name_args[1..-1].join(" "))
          end

        session.close
        if exit_status != 0
          exit exit_status
        else
          exit_status
        end
      end

      private :search_nodes

    end
  end
end
