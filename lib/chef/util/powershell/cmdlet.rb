#
# Author:: Adam Edwards (<adamed@getchef.com>)
#
# Copyright:: 2014, Chef Software, Inc.
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

require 'mixlib/shellout'
require 'chef/mixin/windows_architecture_helper'
require 'chef/util/powershell/cmdlet_result'

class Chef::Util::Powershell
  class Cmdlet
    def initialize(cmdlet, output_format=nil, output_format_options={})
      @output_format = output_format
      
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
        raise ArgumentError, "Invalid output format #{output_format.to_s} specified"
      end

      @cmdlet = cmdlet
      @output_format_options = output_format_options
    end

    attr_reader :output_format

    def run(switches={}, execution_options={}, *arguments)
      switches_string = (switches.each_pair.map {|pair| ['-'+pair[0].to_s, pair[1].to_s].join(' ')}).join(' ')
      arguments_string = arguments.join(' ')

      json_depth = 5

      if @json_format && @output_format_options.has_key?(:depth)
        json_depth = @output_format_options[:depth]
      end
      
      json_command = @json_format ? " | convertto-json -compress -depth #{json_depth}" : ""
      command_string = "powershell.exe -executionpolicy bypass -noprofile -noninteractive -command \"trap [Exception] {write-error -exception ($_.Exception.Message);exit 1};($pwd | out-file c:/pain2.txt);#{@cmdlet} #{switches_string} #{arguments_string}#{json_command}\";if ( ! $? ) { exit 1 }"

      augmented_options = {:returns => [0], :live_stream => false}.merge(execution_options)
      command = Mixlib::ShellOut.new(command_string, augmented_options)

      os_architecture = "#{ENV['PROCESSOR_ARCHITEW6432']}" == 'AMD64' ? :x86_64 : :i386

      status = nil
      
      with_architecture(get_os_architecture) do
        status = command.run_command      
      end
      
      result = CmdletResult.new(status, @output_format)
      
      if ! result.succeeded?
        raise Chef::Exceptions::PowershellCmdletException, "Powershell Cmdlet failed: #{result.stderr}"
      end

      result
    end

    protected

    include Chef::Mixin::WindowsArchitectureHelper

    def get_os_architecture
      os_architecture_value = "#{ENV['PROCESSOR_ARCHITEW6432']}"
      os_architecture_value = "#{ENV['PROCESSOR_ARCHITECTURE']}" if os_architecture_value.nil?
      
      os_architecture = os_architecture_value == 'AMD64' ? :x86_64 : :i386
    end
    
    def with_architecture(architecture)
      node = Hash.new
      node[:kernel] = Hash.new
      node[:kernel][:machine] = get_os_architecture

      if wow64_architecture_override_required?(node, architecture)
        wow64_redirection_state = disable_wow64_file_redirection(node)
      else
        wow64_redirection_state = nil
      end

      begin
        yield
      ensure
        if wow64_redirection_state
          restore_wow64_file_redirection(node, wow64_redirection_state)
        end
      end
    end
  end  
end

