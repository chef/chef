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

require 'chef/knife'

class Chef
  class Knife
    class Ssh < Knife

      deps do
        require 'net/ssh'
        require 'net/ssh/multi'
        require 'readline'
        require 'chef/exceptions'
        require 'chef/search/query'
        require 'chef/mixin/shell_out'
        require 'mixlib/shellout'
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

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      def session
        config[:on_error] ||= :skip
        ssh_error_handler = Proc.new do |server|
          if config[:manual]
            node_name = server.host
          else
            @action_nodes.each do |n|
              node_name = n if format_for_display(n)[config[:attribute]] == server.host
            end
          end
          case config[:on_error]
          when :skip
            ui.warn "Failed to connect to #{node_name} -- #{$!.class.name}: #{$!.message}"
            $!.backtrace.each { |l| Chef::Log.debug(l) }
          when :raise
            #Net::SSH::Multi magic to force exception to be re-raised.
            throw :go, :raise
          end
        end

        @session ||= Net::SSH::Multi.start(:concurrent_connections => config[:concurrency], :on_error => ssh_error_handler)
      end

      def configure_session
        list = case config[:manual]
               when true
                 @name_args[0].split(" ")
               when false
                 r = Array.new
                 q = Chef::Search::Query.new
                 @action_nodes = q.search(:node, @name_args[0])[0]
                 @action_nodes.each do |item|
                   # we should skip the loop to next iteration if the item returned by the search is nil
                   next if item.nil? 
                   # if a command line attribute was not passed, and we have a cloud public_hostname, use that.
                   # see #configure_attribute for the source of config[:attribute] and config[:override_attribute]
                   if !config[:override_attribute] && item[:cloud] and item[:cloud][:public_hostname]
                     i = item[:cloud][:public_hostname]
                   elsif config[:override_attribute]
                     i = extract_nested_value(item, config[:override_attribute])
                   else
                     i = extract_nested_value(item, config[:attribute])
                   end
                   # next if we couldn't find the specified attribute in the returned node object
                   next if i.nil?
                   r.push(i)
                 end
                 r
               end
        if list.length == 0
          if @action_nodes.length == 0
            ui.fatal("No nodes returned from search!")
          else
            ui.fatal("#{@action_nodes.length} #{@action_nodes.length > 1 ? "nodes":"node"} found, " +
                     "but does not have the required attribute to establish the connection. " +
                     "Try setting another attribute to open the connection using --attribute.")
          end
          exit 10
        end
        session_from_list(list)
      end

      def session_from_list(list)
        config[:ssh_gateway] ||= Chef::Config[:knife][:ssh_gateway]
        if config[:ssh_gateway]
          gw_host, gw_user = config[:ssh_gateway].split('@').reverse
          gw_host, gw_port = gw_host.split(':')
          gw_opts = gw_port ? { :port => gw_port } : {}

          session.via(gw_host, gw_user || config[:ssh_user], gw_opts)
        end

        list.each do |item|
          Chef::Log.debug("Adding #{item}")
          session_opts = {}

          ssh_config = Net::SSH.configuration_for(item)

          # Chef::Config[:knife][:ssh_user] is parsed in #configure_user and written to config[:ssh_user]
          user = config[:ssh_user] || ssh_config[:user]
          hostspec = user ? "#{user}@#{item}" : item
          session_opts[:keys] = File.expand_path(config[:identity_file]) if config[:identity_file]
          session_opts[:keys_only] = true if config[:identity_file]
          session_opts[:password] = config[:ssh_password] if config[:ssh_password]
          session_opts[:port] = config[:ssh_port] || Chef::Config[:knife][:ssh_port] || ssh_config[:port]
          session_opts[:logger] = Chef::Log.logger if Chef::Log.level == :debug

          if !config[:host_key_verify]
            session_opts[:paranoid] = false
            session_opts[:user_known_hosts_file] = "/dev/null"
          end

          session.use(hostspec, session_opts)

          @longest = item.length if item.length > @longest
        end

        session
      end

      def fixup_sudo(command)
        command.sub(/^sudo/, 'sudo -p \'knife sudo password: \'')
      end

      def print_data(host, data)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(host, d) }
        else
          padding = @longest - host.length
          str = ui.color(host, :cyan) + (" " * (padding + 1)) + data
          ui.msg(str)
        end
      end

      def ssh_command(command, subsession=nil)
        exit_status = 0
        subsession ||= session
        command = fixup_sudo(command)
        command.force_encoding('binary') if command.respond_to?(:force_encoding)
        subsession.open_channel do |ch|
          ch.request_pty
          ch.exec command do |ch, success|
            raise ArgumentError, "Cannot execute #{command}" unless success
            ch.on_data do |ichannel, data|
              print_data(ichannel[:host], data)
              if data =~ /^knife sudo password: /
                ichannel.send_data("#{get_password}\n")
              end
            end
            ch.on_request "exit-status" do |ichannel, data|
              exit_status = [exit_status, data.read_long].max
            end
          end
        end
        session.loop
        exit_status
      end

      def get_password
        @password ||= ui.ask("Enter your password: ") { |q| q.echo = false }
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
        while 1
          command = read_line
          case command
          when 'quit!'
            puts 'Bye!'
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
        if File.exist? "#{ENV["HOME"]}/.screenrc"
          tf.puts("source #{ENV["HOME"]}/.screenrc")
        end
        tf.puts("caption always '%-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<'")
        tf.puts("hardstatus alwayslastline 'knife ssh #{@name_args[0]}'")
        window = 0
        session.servers_for.each do |server|
          tf.print("screen -t \"#{server.host}\" #{window} ssh ")
          tf.print("-i #{config[:identity_file]} ") if config[:identity_file]
          server.user ? tf.puts("#{server.user}@#{server.host}") : tf.puts(server.host)
          window += 1
        end
        tf.close
        exec("screen -c #{tf.path}")
      end

      def tmux
        ssh_dest = lambda do |server|
          identity = "-i #{config[:identity_file]} " if config[:identity_file]
          prefix = server.user ? "#{server.user}@" : ""
          "'ssh #{identity}#{prefix}#{server.host}'"
        end

        new_window_cmds = lambda do
          if session.servers_for.size > 1
            [""] + session.servers_for[1..-1].map do |server|
              "new-window -a -n '#{server.host}' #{ssh_dest.call(server)}"
            end
          else
            []
          end.join(" \\; ")
        end

        tmux_name = "'knife ssh #{@name_args[0].gsub(/:/,'=')}'"
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
          require 'appscript'
        rescue LoadError
          STDERR.puts "you need the rb-appscript gem to use knife ssh macterm. `(sudo) gem install rb-appscript` to install"
          raise
        end

        Appscript.app("/Applications/Utilities/Terminal.app").windows.first.activate
        Appscript.app("System Events").application_processes["Terminal.app"].keystroke("n", :using=>:command_down)
        term = Appscript.app('Terminal')
        window = term.windows.first.get

        (session.servers_for.size - 1).times do |i|
          window.activate
          Appscript.app("System Events").application_processes["Terminal.app"].keystroke("t", :using=>:command_down)
        end

        session.servers_for.each_with_index do |server, tab_number|
          cmd = "unset PROMPT_COMMAND; echo -e \"\\033]0;#{server.host}\\007\"; ssh #{server.user ? "#{server.user}@#{server.host}" : server.host}"
          Appscript.app('Terminal').do_script(cmd, :in => window.tabs[tab_number + 1].get)
        end
      end

      def configure_attribute
        # Setting 'knife[:ssh_attribute] = "foo"' in knife.rb => Chef::Config[:knife][:ssh_attribute] == 'foo'
        # Running 'knife ssh -a foo' => both Chef::Config[:knife][:ssh_attribute] && config[:attribute] == foo
        # Thus we can differentiate between a config file value and a command line override at this point by checking config[:attribute]
        # We can tell here if fqdn was passed from the command line, rather than being the default, by checking config[:attribute]
        # However, after here, we cannot tell these things, so we must preserve config[:attribute]
        config[:override_attribute] = config[:attribute] || Chef::Config[:knife][:ssh_attribute] 
        config[:attribute] = (Chef::Config[:knife][:ssh_attribute] ||
                              config[:attribute] ||
                              "fqdn").strip
      end

      def cssh
        cssh_cmd = nil
        %w[csshX cssh].each do |cmd|
          begin
            # Unix and Mac only
            cssh_cmd = shell_out!("which #{cmd}").stdout.strip
            break
          rescue Mixlib::ShellOut::ShellCommandFailed
          end
        end
        raise Chef::Exceptions::Exec, "no command found for cssh" unless cssh_cmd

        session.servers_for.each do |server|
          cssh_cmd << " #{server.user ? "#{server.user}@#{server.host}" : server.host}"
        end
        Chef::Log.debug("starting cssh session with command: #{cssh_cmd}")
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

      def configure_identity_file
        config[:identity_file] = get_stripped_unfrozen_value(config[:identity_file] ||
                             Chef::Config[:knife][:ssh_identity_file])
      end

      def extract_nested_value(data_structure, path_spec)
        ui.presenter.extract_nested_value(data_structure, path_spec)
      end

      def run
        extend Chef::Mixin::Command

        @longest = 0

        configure_attribute
        configure_user
        configure_identity_file
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

    end
  end
end
