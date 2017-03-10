#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "mixlib/shellout"
require "chef/mixin/windows_architecture_helper"
require "chef/util/powershell/cmdlet_result"

class Chef
  class Util
    class Powershell
      class Cmdlet
        def initialize(node, cmdlet, output_format = nil, output_format_options = {})
          @output_format = output_format
          @node = node

          case output_format
          when nil
            @json_format = false
          when :json
            @json_format = true
          when :text
            @json_format = false
          when :object
            @json_format = true
          else
            raise ArgumentError, "Invalid output format #{output_format} specified"
          end

          @cmdlet = cmdlet
          @output_format_options = output_format_options
        end

        attr_reader :output_format

        def run(switches = {}, execution_options = {}, *arguments)
          streams = { :json => CmdletStream.new("json"),
                      :verbose => CmdletStream.new("verbose"),
                    }

          arguments_string = arguments.join(" ")

          switches_string = command_switches_string(switches)

          json_depth = 5

          if @json_format && @output_format_options.has_key?(:depth)
            json_depth = @output_format_options[:depth]
          end

          json_command = if @json_format
                           " | convertto-json -compress -depth #{json_depth} > #{streams[:json].path}"
                         else
                           ""
                         end
          redirections = "4> '#{streams[:verbose].path}'"
          command_string = "powershell.exe -executionpolicy bypass -noprofile -noninteractive "\
                           "-command \"trap [Exception] {write-error -exception "\
                           "($_.Exception.Message);exit 1};#{@cmdlet} #{switches_string} "\
                           "#{arguments_string} #{redirections}"\
                           "#{json_command}\";if ( ! $? ) { exit 1 }"

          augmented_options = { :returns => [0], :live_stream => false }.merge(execution_options)
          command = Mixlib::ShellOut.new(command_string, augmented_options)

          status = nil

          with_os_architecture(@node) do
            status = command.run_command
          end

          CmdletResult.new(status, streams, @output_format)
        end

        def run!(switches = {}, execution_options = {}, *arguments)
          result = run(switches, execution_options, arguments)

          if ! result.succeeded?
            raise Chef::Exceptions::PowershellCmdletException, "Powershell Cmdlet failed: #{result.stderr}"
          end

          result
        end

        protected

        include Chef::Mixin::WindowsArchitectureHelper

        def validate_switch_name!(switch_parameter_name)
          if !!(switch_parameter_name =~ /\A[A-Za-z]+[_a-zA-Z0-9]*\Z/) == false
            raise ArgumentError, "`#{switch_parameter_name}` is not a valid PowerShell cmdlet switch parameter name"
          end
        end

        def escape_parameter_value(parameter_value)
          parameter_value.gsub(/(`|'|"|#)/, '`\1')
        end

        def escape_string_parameter_value(parameter_value)
          "'#{escape_parameter_value(parameter_value)}'"
        end

        def command_switches_string(switches)
          command_switches = switches.map do |switch_name, switch_value|
            if switch_name.class != Symbol
              raise ArgumentError, "Invalid type `#{switch_name} `for PowerShell switch '#{switch_name}'. The switch must be specified as a Symbol'"
            end

            validate_switch_name!(switch_name)

            switch_argument = ""
            switch_present = true

            case switch_value
            when Numeric
              switch_argument = switch_value.to_s
            when Float
              switch_argument = switch_value.to_s
            when FalseClass
              switch_present = false
            when TrueClass
            when String
              switch_argument = escape_string_parameter_value(switch_value)
            else
              raise ArgumentError, "Invalid argument type `#{switch_value.class}` specified for PowerShell switch `:#{switch_name}`. Arguments to PowerShell must be of type `String`, `Numeric`, `Float`, `FalseClass`, or `TrueClass`"
            end

            switch_present ? ["-#{switch_name.to_s.downcase}", switch_argument].join(" ").strip : ""
          end

          command_switches.join(" ")
        end

        class CmdletStream
          def initialize(name)
            @filename = Dir::Tmpname.create(name) {}
            ObjectSpace.define_finalizer(self, self.class.destroy(@filename))
          end

          def path
            @filename
          end

          def read
            if File.exist? @filename
              File.open(@filename, "rb:bom|UTF-16LE") do |f|
                f.read.encode("UTF-8")
              end
            end
          end

          def self.destroy(name)
            proc { File.delete(name) if File.exists? name }
          end
        end
      end
    end
  end
end
