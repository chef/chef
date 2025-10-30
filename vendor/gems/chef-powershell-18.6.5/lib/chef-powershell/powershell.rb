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
autoload :FFI_Yajl, "ffi_yajl"
require_relative "exceptions"
require_relative "unicode"

class ChefPowerShell
  class PowerShell

    attr_reader :result
    attr_reader :errors
    attr_reader :verbose

    def self.resolve_wrapper_dll
      arch = ENV["PROCESSOR_ARCHITECTURE"] || "AMD64"
      searched = []

      # Gem path
      if Gem.loaded_specs["chef-powershell"]
        base = Gem.loaded_specs["chef-powershell"].full_gem_path
        gem_path = File.join(base, "bin", "ruby_bin_folder", arch, "Chef.PowerShell.Wrapper.dll")
        searched << gem_path
        return gem_path if File.exist?(gem_path)
      end

      # CHEF_POWERSHELL_BIN override
      if ENV["CHEF_POWERSHELL_BIN"]&.length.to_i > 0
        override = File.join(ENV["CHEF_POWERSHELL_BIN"], "Chef.PowerShell.Wrapper.dll")
        searched << override
        return override if File.exist?(override)
      end

      # Habitat package fallback (hab installed scenario)
      begin
        hab_path = `hab pkg path chef/chef-powershell-shim 2>NUL`.strip
        if hab_path != "" && File.directory?(hab_path)
          hab_dll = File.join(hab_path, "bin", "Chef.PowerShell.Wrapper.dll")
          searched << hab_dll
          return hab_dll if File.exist?(hab_dll)
        end
      rescue
        # ignore any hab errors, just proceed
      end

      raise LoadError, "Chef.PowerShell wrapper DLL not found. Searched: #{searched.join(", ")}. Populate binaries via 'rake update_chef_powershell_dlls' or set CHEF_POWERSHELL_BIN."
    end

    # Run a command under PowerShell via FFI
    # This implementation requires the managed dll and native wrapper to be in the library search
    # path on Windows (i.e. c:\windows\system32 or in the same location as ruby.exe).
    #
    # Requires: .NET Framework 4.0 or higher on the target machine.
    #
    # @param script [String] script to run
    # @param timeout [Integer, nil] timeout in seconds.
    # @return [Object] output
    def initialize(script, timeout: -1)
      # This Powershell DLL source lives here: https://github.com/chef/chef-powershell-shim
      # Every merge into that repo triggers a Habitat build and verification process.
      # There is no mechanism to build a Windows gem file. It has to be done manually running manual_gem_release.ps1
      # Bundle install ensures that the correct architecture binaries are installed into the path.
      # @powershell_dll = Gem.loaded_specs["chef-powershell"].full_gem_path + "/bin/ruby_bin_folder/#{ENV["PROCESSOR_ARCHITECTURE"]}/Chef.PowerShell.Wrapper.dll"
      @powershell_dll = self.class.resolve_wrapper_dll
      exec(script, timeout: timeout)
    end

    #
    # Was there an error running the command
    #
    # @return [Boolean]
    #
    def error?
      return true if errors.any?

      false
    end

    #
    # @raise [ChefPowerShell::PowerShellExceptions::PowerShellCommandFailed] raise if the command failed
    #
    def error!
      raise ChefPowerShell::PowerShellExceptions::PowerShellCommandFailed, "Unexpected exit in PowerShell command: #{@errors}" if error?
    end

    module PowerMod
      class << self
        attr_accessor :result_string, :retry_count, :exception, :result, :errors, :verbose, :hashed_outcome
      end

      extend FFI::Library
      # FFI requires attaching to modules, not classes, so we need to
      # have a module here. The module level variables *could* be refactored
      # out here, but still 100% of the work still goes through the module.
      # @@powershell_dll = Gem.loaded_specs["chef-powershell"].full_gem_path + "/bin/ruby_bin_folder/#{ENV["PROCESSOR_ARCHITECTURE"]}/Chef.PowerShell.Wrapper.dll"
      # NOTE: Previously this line called self.resolve_wrapper_dll at class definition time,
      # but no such method exists inside this module (it's defined on the outer PowerShell class),
      # leading to NoMethodError during require. We now lazy-resolve through a delegator.
      @@powershell_dll = nil
      @@ps_command = ""
      @@ps_timeout = -1

      StoreResultCallback = FFI::Function.new(:bool, %i{pointer size_t}) do |data, size|
        # try parsing the result *first* before returning from the function, and if it fails,
        # return false so that the function can be retried from the C++ side.
        @result_string = data.get_bytes(0, size).force_encoding("UTF-16LE").encode("UTF-8")
        @hashed_outcome = FFI_Yajl::Parser.parse(@result_string)
        @result = FFI_Yajl::Parser.parse(@hashed_outcome["result"])
        @errors = @hashed_outcome["errors"]
        @verbose = @hashed_outcome["verbose"]
        true
      rescue NoMethodError, FFI_Yajl::ParseError => e
        @retry_count += 1
        # capture exception so that it can be raised later, since otherwise
        # we will be raising back to C++.
        @exception = e
        return true if @retry_count > 3

        puts "Retrying PowerShell command execution #{@retry_count}"
        sleep 1
        false
      rescue => e
        # no retry for other exceptions
        @exception = e
        true
      end

      def self.set_ps_dll(value)
        @@powershell_dll = value
      end

      # Resolve DLL via outer class method; cache the result
      def self.ensure_ps_dll
        @@powershell_dll ||= ChefPowerShell::PowerShell.resolve_wrapper_dll
      end

      def self.set_ps_command(value)
        @@ps_command = value
      end

      def self.set_ps_timeout(value)
        @@ps_timeout = value
      end

      def self.do_work
        @exception = nil
        @retry_count = 0
        ensure_ps_dll unless @@powershell_dll
        ffi_lib @@powershell_dll
        attach_function :execute_powershell, :ExecuteScript, %i{string int pointer}, :pointer

        execute_powershell(@@ps_command, @@ps_timeout, StoreResultCallback)
      end
    end

    private

    def exec(script, timeout: -1)
      timeout = -1 if timeout == 0 || timeout.nil?

      # Set it every time because the test suite actually switches
      # the DLL pointed to.
      PowerMod.set_ps_dll(@powershell_dll)
      PowerMod.set_ps_timeout(timeout)

      PowerMod.set_ps_command(script)
      PowerMod.do_work
      # we returned "true" to escape retry, but we still need to check the
      # exception and raise it if it exists.
      raise PowerMod.exception if PowerMod.exception

      @result = PowerMod.result
      @errors = PowerMod.errors
      @verbose = PowerMod.verbose
    end
  end
end
