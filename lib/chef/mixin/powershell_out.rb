#--
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "shell_out"
require_relative "windows_architecture_helper"

class Chef
  module Mixin
    module PowershellOut
      include Chef::Mixin::ShellOut
      include Chef::Mixin::WindowsArchitectureHelper

      # Run a command under powershell with the same API as shell_out.  The
      # options hash is extended to take an "architecture" flag which
      # can be set to :i386 or :x86_64 to force the windows architecture.
      #
      # @param script [String] script to run
      # @param interpreter [Symbol] the interpreter type, `:powershell` or `:pwsh`
      # @param options [Hash] options hash
      # @return [Mixlib::Shellout] mixlib-shellout object
      def powershell_out(*command_args)
        script = command_args.first
        options = command_args.last.is_a?(Hash) ? command_args.last : nil
        interpreter = command_args[1].is_a?(Symbol) ? command_args[1] : :powershell

        raise ArgumentError, "Expected interpreter of :powershell or :pwsh" unless %i{powershell pwsh}.include?(interpreter)

        run_command_with_os_architecture(script, interpreter, options)
      end

      # Run a command under powershell with the same API as shell_out!
      # (raises exceptions on errors)
      #
      # @param script [String] script to run
      # @param interpreter [Symbol] the interpreter type, `:powershell` or `:pwsh`
      # @param options [Hash] options hash
      # @return [Mixlib::Shellout] mixlib-shellout object
      def powershell_out!(*command_args)
        cmd = powershell_out(*command_args)
        cmd.error!
        cmd
      end

      private

      # Helper function to run shell_out and wrap it with the correct
      # flags to possibly disable WOW64 redirection (which we often need
      # because chef-client runs as a 32-bit app on 64-bit windows).
      #
      # @param script [String] script to run
      # @param interpreter [Symbol] the interpreter type, `:powershell` or `:pwsh`
      # @param options [Hash] options hash
      # @return [Mixlib::Shellout] mixlib-shellout object
      def run_command_with_os_architecture(script, interpreter, options)
        options ||= {}
        options = options.dup
        arch = options.delete(:architecture)

        with_os_architecture(nil, architecture: arch) do
          shell_out(
            build_powershell_command(script, interpreter),
            **options
          )
        end
      end

      # Helper to build a powershell command around the script to run.
      #
      # @param script [String] script to run
      # @param interpreter [Symbol] the interpreter type, `:powershell` or `:pwsh`
      # @return [String] powershell command to execute
      def build_powershell_command(script, interpreter)
        flags = [
          # Hides the copyright banner at startup.
          "-NoLogo",
          # Does not present an interactive prompt to the user.
          "-NonInteractive",
          # Does not load the Windows PowerShell profile.
          "-NoProfile",
          # always set the ExecutionPolicy flag
          # see http://technet.microsoft.com/en-us/library/ee176961.aspx
          "-ExecutionPolicy Unrestricted",
          # PowerShell will hang if STDIN is redirected
          # http://connect.microsoft.com/PowerShell/feedback/details/572313/powershell-exe-can-hang-if-stdin-is-redirected
          "-InputFormat None",
        ]

        "#{interpreter}.exe #{flags.join(" ")} -Command \"#{script.gsub('"', '\"')}\""
      end
    end
  end
end
