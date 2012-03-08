#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/log'
require 'chef/exceptions'
require 'tmpdir'
require 'fcntl'
require 'etc'

class Chef
  module Mixin
    module Command
      extend self

      # NOTE: run_command is deprecated in favor of using Chef::Shellout which now comes from the mixlib-shellout gem. NOTE #

      if RUBY_PLATFORM =~ /mswin|mingw32|windows/
        require 'chef/mixin/command/windows'
        include ::Chef::Mixin::Command::Windows
        extend  ::Chef::Mixin::Command::Windows
      else
        require 'chef/mixin/command/unix'
        include ::Chef::Mixin::Command::Unix
        extend  ::Chef::Mixin::Command::Unix
      end

      # === Parameters
      # args<Hash>: A number of required and optional arguments
      #   command<String>, <Array>: A complete command with options to execute or a command and options as an Array 
      #   creates<String>: The absolute path to a file that prevents the command from running if it exists
      #   cwd<String>: Working directory to execute command in, defaults to Dir.tmpdir
      #   timeout<String>: How many seconds to wait for the command to execute before timing out
      #   returns<String>: The single exit value command is expected to return, otherwise causes an exception
      #   ignore_failure<Boolean>: Whether to raise an exception on failure, or just return the status
      #   output_on_failure<Boolean>: Return output in raised exception regardless of Log.level
      # 
      #   user<String>: The UID or user name of the user to execute the command as
      #   group<String>: The GID or group name of the group to execute the command as
      #   environment<Hash>: Pairs of environment variable names and their values to set before execution
      #
      # === Returns
      # Returns the exit status of args[:command]
      def run_command(args={})         
        command_output = ""
        
        args[:ignore_failure] ||= false
        args[:output_on_failure] ||= false

        # TODO: This is the wrong place for this responsibility.
        if args.has_key?(:creates)
          if File.exists?(args[:creates])
            Chef::Log.debug("Skipping #{args[:command]} - creates #{args[:creates]} exists.")
            return false
          end
        end
        
        status, stdout, stderr = output_of_command(args[:command], args)
        command_output << "STDOUT: #{stdout}"
        command_output << "STDERR: #{stderr}"
        handle_command_failures(status, command_output, args)
        
        status
      end
      
      def output_of_command(command, args)
        Chef::Log.debug("Executing #{command}")
        stderr_string, stdout_string, status = "", "", nil
        
        exec_processing_block = lambda do |pid, stdin, stdout, stderr|
          stdout_string, stderr_string = stdout.string.chomp, stderr.string.chomp
        end
        
        args[:cwd] ||= Dir.tmpdir
        unless ::File.directory?(args[:cwd])
          raise Chef::Exceptions::Exec, "#{args[:cwd]} does not exist or is not a directory"
        end
        
        Dir.chdir(args[:cwd]) do
          if args[:timeout]
            begin
              Timeout.timeout(args[:timeout]) do
                status = popen4(command, args, &exec_processing_block)
              end
            rescue Timeout::Error => e
              Chef::Log.error("#{command} exceeded timeout #{args[:timeout]}")
              raise(e)
            end
          else
            status = popen4(command, args, &exec_processing_block)
          end
          
          Chef::Log.debug("---- Begin output of #{command} ----")
          Chef::Log.debug("STDOUT: #{stdout_string}")
          Chef::Log.debug("STDERR: #{stderr_string}")
          Chef::Log.debug("---- End output of #{command} ----")
          Chef::Log.debug("Ran #{command} returned #{status.exitstatus}")
        end
        
        return status, stdout_string, stderr_string
      end
      
      def handle_command_failures(status, command_output, opts={})
        unless opts[:ignore_failure]
          opts[:returns] ||= 0
          unless Array(opts[:returns]).include?(status.exitstatus)
            # if the log level is not debug, through output of command when we fail
            output = ""
            if Chef::Log.level == :debug || opts[:output_on_failure]
              output << "\n---- Begin output of #{opts[:command]} ----\n"
              output << command_output.to_s
              output << "\n---- End output of #{opts[:command]} ----\n"
            end
            raise Chef::Exceptions::Exec, "#{opts[:command]} returned #{status.exitstatus}, expected #{opts[:returns]}#{output}"
          end
        end
      end
      
      # Call #run_command but set LC_ALL to the system's current environment so it doesn't get changed to C.
      #
      # === Parameters
      # args<Hash>: A number of required and optional arguments that will be handed out to #run_command
      #
      # === Returns
      # Returns the result of #run_command
      def run_command_with_systems_locale(args={})
        args[:environment] ||= {}
        args[:environment]["LC_ALL"] = ENV["LC_ALL"]
        run_command args
      end

      # def popen4(cmd, args={}, &b)
      #   @@os_handler.popen4(cmd, args, &b)
      # end

      # module_function :popen4

      def chdir_or_tmpdir(dir, &block)
        dir ||= Dir.tmpdir
        unless File.directory?(dir)
          raise Chef::Exceptions::Exec, "#{dir} does not exist or is not a directory"
        end
        Dir.chdir(dir) do
          block.call
        end
      end

    end
  end
end
