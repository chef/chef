#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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
require_relative "winrm_knife_base" # WinrmCommandSharedFunctions
require_relative "winrm_session"
require_relative "knife_windows_base"

class Chef
  class Knife
    class Winrm < Knife

      include Chef::Knife::WinrmCommandSharedFunctions
      include Chef::Knife::KnifeWindowsBase

      deps do
        require_relative "windows_cert_generate"
        require_relative "windows_cert_install"
        require_relative "windows_listener_create"
        require "readline"
        require_relative "../search/query"
      end

      attr_writer :password

      banner "knife winrm QUERY COMMAND (options)"

      option :returns,
        long: "--returns CODES",
        description: "A comma delimited list of return codes which indicate success",
        default: "0"

      def run
        STDOUT.sync = STDERR.sync = true

        configure_session
        exit_status = execute_remote_command
        if exit_status != 0
          exit exit_status
        else
          exit_status
        end
      end

      def execute_remote_command
        case @name_args[1]
        when "interactive"
          interactive
        else
          run_command(@name_args[1..-1].join(" "))
        end
      end

      private

      def interactive
        puts "WARN: Deprecated functionality. This will not be supported in future knife-windows releases."
        puts "Connected to #{ui.list(session.servers.collect { |s| ui.color(s.host, :cyan) }, :inline, " and ")}"
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
            server_list = []
            @winrm_sessions.each do |session_server|
              server_list << session_server if raw_list.include?(session_server.host)
            end
            command = $2
            relay_winrm_command(command, server_list)
          else
            relay_winrm_command(command)
          end
        end
      end

      # Present the prompt and read a single line from the console. It also
      # detects ^D and returns "exit" in that case. Adds the input to the
      # history, unless the input is empty. Loops repeatedly until a non-empty
      # line is input.
      def read_line
        loop do
          command = reader.readline("#{ui.color("knife-winrm>", :bold)} ", true)

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
    end
  end
end
