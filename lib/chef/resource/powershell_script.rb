#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
require_relative "windows_script"

class Chef
  class Resource
    class PowershellScript < Chef::Resource::WindowsScript
      provides :powershell_script, os: "windows"

      property :flags, String,
        description: "A string that is passed to the Windows PowerShell command",
        default: lazy { default_flags },
        coerce: proc { |input|
          if input == default_flags
            # Means there was no input provided,
            # and should use defaults in this case
            input
          else
            # The last occurance of a flag would override its
            # previous one at the time of command execution.
            [default_flags, input].join(" ")
          end
        }

      description "Use the powershell_script resource to execute a script using the Windows PowerShell"\
                  " interpreter, much like how the script and script-based resources—bash, csh, perl, python,"\
                  " and ruby—are used. The powershell_script is specific to the Microsoft Windows platform"\
                  " and the Windows PowerShell interpreter.\n\n The powershell_script resource creates and"\
                  " executes a temporary file (similar to how the script resource behaves), rather than running"\
                  " the command inline. Commands that are executed with this resource are (by their nature) not"\
                  " idempotent, as they are typically unique to the environment in which they are run. Use not_if"\
                  " and only_if to guard this resource for idempotence."

      def initialize(name, run_context = nil)
        super(name, run_context, :powershell_script, "powershell.exe")
        @convert_boolean_return = false
      end

      def convert_boolean_return(arg = nil)
        set_or_return(
          :convert_boolean_return,
          arg,
          kind_of: [ FalseClass, TrueClass ]
        )
      end

      # Allow callers evaluating guards to request default
      # attribute values. This is needed to allow
      # convert_boolean_return to be true in guard context by default,
      # and false by default otherwise. When this mode becomes the
      # default for this resource, this method can be removed since
      # guard context and recipe resource context will have the
      # same behavior.
      def self.get_default_attributes(opts)
        { convert_boolean_return: true }
      end

      # Options that will be passed to Windows PowerShell command
      def default_flags
        return "" if Chef::Platform.windows_nano_server?

        # Execution policy 'Bypass' is preferable since it doesn't require
        # user input confirmation for files such as PowerShell modules
        # downloaded from the Internet. However, 'Bypass' is not supported
        # prior to PowerShell 3.0, so the fallback is 'Unrestricted'
        execution_policy = Chef::Platform.supports_powershell_execution_bypass?(run_context.node) ? "Bypass" : "Unrestricted"

        [
          "-NoLogo",
          "-NonInteractive",
          "-NoProfile",
          "-ExecutionPolicy #{execution_policy}",
          # PowerShell will hang if STDIN is redirected
          # http://connect.microsoft.com/PowerShell/feedback/details/572313/powershell-exe-can-hang-if-stdin-is-redirected
          "-InputFormat None",
        ].join(" ")
      end
    end
  end
end
