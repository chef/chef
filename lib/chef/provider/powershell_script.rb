#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/provider/windows_script'

class Chef
  class Provider
    class PowershellScript < Chef::Provider::WindowsScript

      protected
      EXIT_STATUS_EXCEPTION_HANDLER = "\ntrap [Exception] {write-error -exception ($_.Exception.Message);exit 1}".freeze
      EXIT_STATUS_NORMALIZATION_SCRIPT = "\nif ($? -ne $true) { if ( $LASTEXITCODE -ne 0) {exit $LASTEXITCODE} else { exit 1 }}".freeze
      EXIT_STATUS_RESET_SCRIPT = "\n$LASTEXITCODE=0".freeze

      # Process exit codes are strange with PowerShell. Unless you
      # explicitly call exit in Powershell, the powershell.exe
      # interpreter returns only 0 for success or 1 for failure. Since
      # we'd like to get specific exit codes from executable tools run
      # with Powershell, we do some work using the automatic variables
      # $? and $LASTEXITCODE to return the process exit code of the
      # last process run in the script if it is the last command
      # executed, otherwise 0 or 1 based on whether $? is set to true
      # (success, where we return 0) or false (where we return 1).
      def normalize_script_exit_status( code )
        target_code = ( EXIT_STATUS_EXCEPTION_HANDLER +
                        EXIT_STATUS_RESET_SCRIPT +
                        "\n" +
                        code.to_s +
                        EXIT_STATUS_NORMALIZATION_SCRIPT )
        convert_boolean_return = @new_resource.convert_boolean_return
        @code = <<EOH
new-variable -name interpolatedexitcode -visibility private -value $#{convert_boolean_return}
new-variable -name chefscriptresult -visibility private
$chefscriptresult = {
#{target_code}
}.invokereturnasis()
if ($interpolatedexitcode -and $chefscriptresult.gettype().name -eq 'boolean') { exit [int32](!$chefscriptresult) } else { exit 0 }
EOH
      end

      public

      def initialize (new_resource, run_context)
        super(new_resource, run_context, '.ps1')
        normalize_script_exit_status(new_resource.code)
      end

      def flags
        default_flags = [
          "-NoLogo",
          "-NonInteractive",
          "-NoProfile",
          "-ExecutionPolicy RemoteSigned",
          # Powershell will hang if STDIN is redirected
          # http://connect.microsoft.com/PowerShell/feedback/details/572313/powershell-exe-can-hang-if-stdin-is-redirected
          "-InputFormat None",
          # Must use -File rather than -Command to launch the script
          # file created by the base class that contains the script
          # code -- otherwise, powershell.exe does not propagate the
          # error status of a failed Windows process that ran at the
          # end of the script, it gets changed to '1'.
          "-File"
        ]

        interpreter_flags = default_flags.join(' ')

        if ! (@new_resource.flags.nil?)
          interpreter_flags = [@new_resource.flags, interpreter_flags].join(' ')
        end

        interpreter_flags
      end
    end
  end
end
