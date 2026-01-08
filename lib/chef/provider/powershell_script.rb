#
# Author:: Adam Edwards (<adamed@chef.io>)
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
#

require_relative "../platform/query_helpers"
require_relative "windows_script"

class Chef
  class Provider
    class PowershellScript < Chef::Provider::WindowsScript
      # FIXME: use composition not inheritance

      provides :powershell_script

      action :run do
        Chef::Log.debug("using inline impl: #{new_resource.use_inline_powershell}")
        if new_resource.use_inline_powershell
          run_using_powershell_exec
        else
          validate_script_syntax!
          super()
        end
      end

      # Set InputFormat to None as PowerShell will hang if STDIN is redirected
      # http://connect.microsoft.com/PowerShell/feedback/details/572313/powershell-exe-can-hang-if-stdin-is-redirected
      DEFAULT_FLAGS = "-NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -InputFormat None".freeze

      def command
        # Must use -File rather than -Command to launch the script
        # file created by the base class that contains the script

        # code -- otherwise, powershell.exe does not propagate the
        # error status of a failed Windows process that ran at the
        # end of the script, it gets changed to '1'.
        #
        [
          %Q{"#{interpreter_path}"},
          DEFAULT_FLAGS,
          new_resource.flags,
          %Q{-File "#{script_file_path}"},
        ].join(" ")
      end

      protected

      # Run the inline version of powershell, using powershell_exec rather than powershell_out - this should
      # hopefully
      def run_using_powershell_exec
        # Because of the nature of powershell_exec, we can't easily stream data to the shell, so we just flat out
        # disallow this combination
        if new_resource.live_stream
          raise "powershell_script does not support live_stream when inline powershell is enabled - please choose one or the other"
        end

        # This comes from the execute super resource - since we want to limit the scope of this to powershell,
        # we use this here
        if creates && sentinel_file.exist?
          logger.debug("#{new_resource} sentinel file #{sentinel_file} exists - nothing to do")
          return false
        end

        converge_by("execute direct powershell #{new_resource.name}") do
          # For scoping - otherwise, we lose return_code/stdout/stderr when the timeout block is over
          return_code = nil
          stdout = nil
          stderr = nil

          r = powershell_exec!(powershell_wrapper_script, new_resource.interpreter.to_sym, timeout: new_resource.timeout)
          # Split out the stdout/return code format if needed
          return_code = r.result

          # The script returns an array if there is stdout, or just a plain return value if
          # there is not - we need to handle both of these cases for full coverage
          if return_code.is_a?(Array)
            # Why to_s?  Because if the only powershell output is an object,
            # it'll be returned here
            stdout = return_code[0].to_s
            stderr = r.errors.join("\n")
            return_code = return_code[-1]
          else
            stdout = ""
            stderr = r.errors.join("\n")
          end

          Chef::Log.info("Powershell output: #{stdout}") unless stdout.empty?
          Chef::Log.info("Powershell error: #{stderr}") unless stderr.empty?

          # Check the return code, and validate.  This code is cribbed from execute.rb, and does exactly the same
          # thing as it does there
          valid_returns = new_resource.returns
          valid_returns = [valid_returns] if valid_returns.is_a?(Integer)
          unless valid_returns.include?(return_code)
            # Handle sensitive results
            if sensitive?
              ex = ChefPowerShell::PowerShellExceptions::PowerShellCommandFailed.new("Command execution failed. STDOUT/STDERR suppressed for sensitive resource")
              # Forcibly hide the exception cause chain here so we don't log the unredacted version
              def ex.cause
                nil
              end
              raise ex
            else
              raise ChefPowerShell::PowerShellExceptions::PowerShellCommandFailed.new("Powershell command returned #{return_code} - output was \"#{stdout}\", error output  was \"#{stderr}\"")
            end
          end
          true
        end
      end

      def interpreter_path
        # Powershell.exe is always in "v1.0" folder (for backwards compatibility)
        # pwsh is the other interpreter and we will assume that it is on the path.
        # It will exist in different folders depending on the installed version.
        # There can also be multiple versions installed. Depending on how it was installed,
        # there might be a registry entry pointing to the installation path. The key will
        # differ depending on version and architecture. It seems best to let the PATH
        # determine the file path to use since that will provide the same pwsh.exe one
        # would invoke from any shell.
        if interpreter == "powershell"
          Chef::Util::PathHelper.join(basepath, "WindowsPowerShell", "v1.0", "#{interpreter}.exe")
        else
          interpreter
        end
      end

      def code
        code = powershell_wrapper_script
        logger.trace("powershell_script provider called with script code:\n\n#{new_resource.code}\n")
        logger.trace("powershell_script provider will execute transformed code:\n\n#{code}\n")
        code
      end

      def validate_script_syntax!
        Tempfile.open(["chef_powershell_script-user-code", ".ps1"]) do |user_script_file|
          # Wrap the user's code in a PowerShell script block so that
          # it isn't executed. However, syntactically invalid script
          # in that block will still trigger a syntax error which is
          # exactly what we want here -- verify the syntax without
          # actually running the script.
          user_code_wrapped_in_powershell_script_block = <<~EOH
            {
              #{new_resource.code}
            }
          EOH
          user_script_file.puts user_code_wrapped_in_powershell_script_block

          # A .close or explicit .flush required to ensure the file is
          # written to the file system at this point, which is required since
          # the intent is to execute the code just written to it.
          user_script_file.close
          validation_command = [
            %Q{"#{interpreter_path}"},
            DEFAULT_FLAGS,
            new_resource.flags,
            %Q{-Command ". '#{user_script_file.path}'"},
          ].join(" ")

          # Note that other script providers like bash allow syntax errors
          # to be suppressed by setting 'returns' to a value that the
          # interpreter would return as a status code in the syntax
          # error case. We explicitly don't do this here -- syntax
          # errors will not be suppressed, since doing so could make
          # it harder for users to detect / debug invalid scripts.

          # Therefore, the only return value for a syntactically valid
          # script is 0. If an exception is raised by shellout, this
          # means a non-zero return and thus a syntactically invalid script.

          with_os_architecture(node, architecture: new_resource.architecture) do
            shell_out!(validation_command, returns: [0])
          end
        end
      end

      # Process exit codes are strange with PowerShell and require
      # special handling to cover common use cases.
      # A wrapper script is used to launch user-supplied script while
      # still obtaining useful process exit codes. Unless you
      # explicitly call exit in PowerShell, the powershell.exe
      # interpreter returns only 0 for success or 1 for failure. Since
      # we'd like to get specific exit codes from executable tools run
      # with PowerShell, we do some work using the automatic variables
      # $? and $LASTEXITCODE to return the process exit code of the
      # last process run in the script if it is the last command
      # executed, otherwise 0 or 1 based on whether $? is set to true
      # (success, where we return 0) or false (where we return 1).
      #
      # This is the regular powershell version of the above script - the difference
      # is that regular powershell allows for hidden visibility variables, due to the
      # very slightly different semantics.
      def powershell_wrapper_script
        <<~EOH
          # Chef Client wrapper for powershell_script resources

          # In rare cases, such as when PowerShell is executed
          # as an alternate user, the new-variable cmdlet is not
          # available, so import it just in case
          if ( get-module -ListAvailable Microsoft.PowerShell.Utility )
          {
              Import-Module Microsoft.PowerShell.Utility
          }

          # LASTEXITCODE can be uninitialized -- make it explicitly 0
          # to avoid incorrect detection of failure (non-zero) codes
          $global:LASTEXITCODE = 0

          # Catch any exceptions -- without this, exceptions will result
          # In a zero return code instead of the desired non-zero code
          # that indicates a failure

#{if new_resource.use_inline_powershell
    # Inline powershell doesn't allow for private visibility variables,
    # and uses return instead of exit
    <<-EOI
          trap [Exception] {write-error ($_.Exception.Message);return 1}
          $interpolatedexitcode = $#{new_resource.convert_boolean_return}
    EOI
  else
    <<-EOI
          trap [Exception] {write-error ($_.Exception.Message);exit 1}

          # Variable state that should not be accessible to the user code
          new-variable -name interpolatedexitcode -visibility private -value $#{new_resource.convert_boolean_return}
          new-variable -name chefscriptresult -visibility private
    EOI
  end}
          # Initialize a variable we use to capture $? inside a block
          $global:lastcmdlet = $null

          # Execute the user's code in a script block --
          $chefscriptresult =
          {
           #{new_resource.code}

           # This assignment doesn't affect the block's return value
           $global:lastcmdlet = $?
          }.invokereturnasis()

          # Assume failure status of 1 -- success cases
          # will have to override this
          $exitstatus = 1

          # If convert_boolean_return is enabled, the block's return value
          # gets precedence in determining our exit status
          if ($interpolatedexitcode -and $chefscriptresult -ne $null -and $chefscriptresult.gettype().name -eq 'boolean')
          {
            $exitstatus = [int32](!$chefscriptresult)
          }
          elseif ($lastcmdlet)
          {
            # Otherwise, a successful cmdlet execution defines the status
            $exitstatus = 0
          }
          elseif ( $LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0 )
          {
            # If the cmdlet status is failed, allow the Win32 status
            # in $LASTEXITCODE to define exit status. This handles the case
            # where no cmdlets, only Win32 processes have run since $?
            # will be set to $false whenever a Win32 process returns a non-zero
            # status.
            $exitstatus = $LASTEXITCODE
          }

          # Print STDOUT for the script execution
          Write-Output $chefscriptresult

          # If this script is launched with -File, the process exit
          # status of PowerShell.exe will be $exitstatus. If it was
          # launched with -Command, it will be 0 if $exitstatus was 0,
          # 1 (i.e. failed) otherwise.
#{if new_resource.use_inline_powershell
    # Inline powershell needs return, not exit
    "return $exitstatus\n"
  else
    "exit $exitstatus\n"
  end
}
        EOH
      end

      def script_extension
        ".ps1"
      end
    end
  end
end
