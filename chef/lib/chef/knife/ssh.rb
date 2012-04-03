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
        require 'chef/search/query'
        require 'chef/mixin/command'
      end

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
        :description => "The attribute to use for opening the connection - default is fqdn",
        :default => "fqdn",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_attribute] = key }

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
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

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
                   i = format_for_display(item)[config[:attribute]]
                   r.push(i) unless i.nil?
                 end
                 r
               end
        (ui.fatal("No nodes returned from search!"); exit 10) if list.length == 0
        session_from_list(list)
      end

      def session_from_list(list)
        list.each do |item|
          Chef::Log.debug("Adding #{item}")

          hostspec = config[:ssh_user] ? "#{config[:ssh_user]}@#{item}" : item
          session_opts = {}
          session_opts[:keys] = File.expand_path(config[:identity_file]) if config[:identity_file]
          session_opts[:keys_only] = true if config[:identity_file]
          session_opts[:password] = config[:ssh_password] if config[:ssh_password]
          session_opts[:port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
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
        subsession ||= session
        command = fixup_sudo(command)
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
          end
        end
        session.loop
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
          Chef::Mixin::Command.run_command(:command => cmd)
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
        config[:attribute] = (Chef::Config[:knife][:ssh_attribute] ||
                              config[:attribute]).strip
      end

      def csshx
        csshx_cmd = "csshX"
        session.servers_for.each do |server|
          csshx_cmd << " #{server.user ? "#{server.user}@#{server.host}" : server.host}"
        end
        exec(csshx_cmd)
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

      def run
        extend Chef::Mixin::Command

        @longest = 0

        configure_attribute
        configure_user
        configure_identity_file
        configure_session

        case @name_args[1]
        when "interactive"
          interactive
        when "screen"
          screen
        when "tmux"
          tmux
        when "macterm"
          macterm
        when "csshx"
          csshx
        else
          ssh_command(@name_args[1..-1].join(" "))
        end

        session.close
      end

    end
  end
end

