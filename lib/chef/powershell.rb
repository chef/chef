#
# Author:: Stuart Preston (<stuart@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "ffi" unless defined?(FFI)
require_relative "json_compat"

class Chef
  class PowerShell
    extend FFI::Library

    attr_reader :result
    attr_reader :errors

    # Run a command under PowerShell via FFI
    # This implementation requires the managed dll and native wrapper to be in the library search
    # path on Windows (i.e. c:\windows\system32 or in the same location as ruby.exe).
    #
    # Requires: .NET Framework 4.0 or higher on the target machine.
    #
    # @param script [String] script to run
    # @return [Object] output
    def initialize(script)
      @dll ||= "Chef.PowerShell.Wrapper.dll"
      exec(script)
    end

    #
    # Was there an error running the command
    #
    # @return [Boolean]
    #
    def error?
      return true if errors.count > 0

      false
    end

    class CommandFailed < RuntimeError; end

    #
    # @raise [Chef::PowerShell::CommandFailed] raise if the command failed
    #
    def error!
      raise Chef::PowerShell::CommandFailed, "Unexpected exit in PowerShell command: #{@errors}" if error?
    end

    protected

    def exec(script)
      FFI.ffi_lib @dll
      FFI.attach_function :execute_powershell, :ExecuteScript, [:string], :pointer
      execution = FFI.execute_powershell(script).read_utf16string
      hashed_outcome = Chef::JSONCompat.parse(execution)
      @result = Chef::JSONCompat.parse(hashed_outcome["result"])
      @errors = hashed_outcome["errors"]
    end
  end
end
