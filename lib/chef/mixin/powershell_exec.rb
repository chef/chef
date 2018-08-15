#
# Author:: Stuart Preston (<stuart@chef.io>)
# Copyright:: Copyright 2018, Chef Software, Inc.
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

require "chef/powershell"

# The powershell_exec mixin provides in-process access to PowerShell engine via
# a COM interop (installed by the Chef Client installer).
#
# powershell_exec returns a Chef::PowerShell object that provides 3 methods:
#
# .result - returns a hash representing the results returned by executing the
#           PowerShell script block
# .errors - this is an array of string containing any messages written to the
#           PowerShell error stream during execution
# .error? - returns true if there were error messages written to the PowerShell
#           error stream during execution
#
# Some examples of usage:
#
# > powershell_exec("(Get-Item c:\\windows\\system32\\w32time.dll).VersionInfo"
#   ).result["FileVersion"]
#  => "10.0.14393.0 (rs1_release.160715-1616)"
#
# > powershell_exec("(get-process ruby).Mainmodule").result["FileName"]
#  => C:\\opscode\\chef\\embedded\\bin\\ruby.exe"
#
# > powershell_exec("$a = $true; $a").result
#  => true
#
# > powershell_exec("not-found").errors
#  => ["ObjectNotFound: (not-found:String) [], CommandNotFoundException: The
#  term 'not-found' is not recognized as the name of a cmdlet, function, script
#  file, or operable program. Check the spelling of the name, or if a path was
#  included, verify that the path is correct and try again. (at <ScriptBlock>,
#   <No file>: line 1)"]
#
# > powershell_exec("not-found").error?
#  => true
#
# > powershell_exec("get-item c:\\notfound -erroraction stop")
# WIN32OLERuntimeError: (in OLE method `ExecuteScript': )
#     OLE error code:80131501 in System.Management.Automation
#       The running command stopped because the preference variable
#       "ErrorActionPreference" or common parameter is set to Stop: Cannot find
#       path 'C:\notfound' because it does not exist.
#
# *Why use this and not powershell_out?* Startup time to invoke the PowerShell
# engine is much faster (over 7X faster in tests) than writing the PowerShell
# to disk, shelling out to powershell.exe and retrieving the .stdout or .stderr
# methods afterwards.  Additionally we are able to have a higher fidelity
# conversation with PowerShell because we are now working with the objects that
# are returned by the script, rather than having to parse the stdout of
# powershell.exe to get a result.
#
# *How does this work?*  In .NET terms, when you run a PowerShell script block
# through the engine, behind the scenes you get a Collection<PSObject> returned
# and simply we are serializing this, adding any errors that were generated to
# a custom JSON string transferred in memory to Ruby.  The easiest way to
# develop for this approach is to imagine that the last thing that happens in
# your PowerShell script block is "ConvertTo-Json".  That's exactly what we are
# doing here behind the scenes.
#
# There are a handful of current limitations with this approach:
# - Windows UAC elevation is controlled by the token assigned to the account
#   that Ruby.exe is running under.
# - Terminating errors will result in a WIN32OLERuntimeError and typically are
#   handled as an exception.
# - There are no return/error codes, as we are not shelling out to
#   powershell.exe but calling a method inline, no errors codes are returned.
# - There is no settable timeout on powershell_exec method execution.
# - It is not possible to impersonate another user running powershell, the
#   credentials of the user running Chef Client are used.
#

class Chef
  module Mixin
    module PowershellExec
      # Run a command under PowerShell via a managed (.NET) COM interop API.
      # This implementation requires the managed dll to be registered on the
      # target machine.
      #
      # Requires: .NET Framework 4.0 or higher on the target machine.
      #
      # @param script [String] script to run
      # @return [Chef::PowerShell] output
      def powershell_exec(script)
        Chef::PowerShell.new(script)
      end
    end
  end
end
