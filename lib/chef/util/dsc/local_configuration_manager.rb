#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../../mixin/powershell_exec"
require_relative "lcm_output_parser"

class Chef::Util::DSC
  class LocalConfigurationManager
    include Chef::Mixin::PowershellExec

    def initialize(node, configuration_path)
      @node = node
      @configuration_path = configuration_path
      clear_execution_time
    end

    def test_configuration(configuration_document)
      status = run_configuration_cmdlet(configuration_document, false)
      log_dsc_exception(status.errors.join("\n")) if status.error?
      configuration_update_required?(status.result)
    end

    def set_configuration(configuration_document)
      run_configuration_cmdlet(configuration_document, true)
    end

    def last_operation_execution_time_seconds
      if @operation_start_time && @operation_end_time
        @operation_end_time - @operation_start_time
      end
    end

    private

    def run_configuration_cmdlet(configuration_document, apply_configuration)
      Chef::Log.trace("DSC: Calling DSC Local Config Manager to #{apply_configuration ? "set" : "test"} configuration document.")

      start_operation_timing
      status = nil

      begin
        save_configuration_document(configuration_document)
        cmd = lcm_command(apply_configuration)
        Chef::Log.trace("DSC: Calling DSC Local Config Manager with:\n#{cmd}")

        status = powershell_exec(cmd)
        if apply_configuration
          status.error!
        end
      ensure
        end_operation_timing
        remove_configuration_document
        if last_operation_execution_time_seconds
          Chef::Log.trace("DSC: DSC operation completed in #{last_operation_execution_time_seconds} seconds.")
        end
      end
      Chef::Log.trace("DSC: Completed call to DSC Local Config Manager")
      status
    end

    def lcm_command(apply_configuration)
      common_command_prefix = "$ProgressPreference = 'SilentlyContinue';"
      ps4_base_command = "#{common_command_prefix} Start-DscConfiguration -path #{@configuration_path} -wait -erroraction 'stop' -force"
      if apply_configuration
        ps4_base_command
      else
        if ps_version_gte_5?
          "#{common_command_prefix} Test-DscConfiguration -path #{@configuration_path} | format-list | Out-String"
        else
          ps4_base_command + " -whatif; if (! $?) { exit 1 }"
        end
      end
    end

    def ps_version_gte_5?
      Chef::Platform.supported_powershell_version?(@node, 5)
    end

    def log_dsc_exception(dsc_exception_output)
      if whatif_not_supported?(dsc_exception_output)
        # LCM returns an error if any of the resources do not support the optional What-If
        Chef::Log.warn("Received error while testing configuration due to resource not supporting 'WhatIf'")
      elsif dsc_module_import_failure?(dsc_exception_output)
        Chef::Log.warn("Received error while testing configuration due to a module for an imported resource possibly not being fully installed:\n#{dsc_exception_output.gsub(/\s+/, " ")}")
      else
        Chef::Log.warn("Received error while testing configuration:\n#{dsc_exception_output.gsub(/\s+/, " ")}")
      end
    end

    def whatif_not_supported?(dsc_exception_output)
      !! (dsc_exception_output.gsub(/\n+/, "").gsub(/\s+/, " ") =~ /A parameter cannot be found that matches parameter name 'Whatif'/i)
    end

    def dsc_module_import_failure?(command_output)
      !! (command_output =~ /\sCimException/ &&
        command_output.include?("ProviderOperationExecutionFailure") &&
        command_output =~ /\smodule\s+is\s+installed/)
    end

    def configuration_update_required?(command_output)
      Chef::Log.trace("DSC: DSC returned the following '-whatif' output from test operation:\n#{command_output}")
      begin
        Parser.parse(command_output, ps_version_gte_5?)
      rescue Chef::Exceptions::LCMParser => e
        Chef::Log.warn("Could not parse LCM output: #{e}")
        [Chef::Util::DSC::ResourceInfo.new("Unknown DSC Resources", true, ["Unknown changes because LCM output was not parsable."])]
      end
    end

    def save_configuration_document(configuration_document)
      ::FileUtils.mkdir_p(@configuration_path)
      ::File.open(configuration_document_path, "wb") do |file|
        file.write(configuration_document)
      end
    end

    def remove_configuration_document
      ::FileUtils.rm(configuration_document_path)
    end

    def configuration_document_path
      File.join(@configuration_path, "..mof")
    end

    def clear_execution_time
      @operation_start_time = nil
      @operation_end_time = nil
    end

    def start_operation_timing
      clear_execution_time
      @operation_start_time = Time.now
    end

    def end_operation_timing
      @operation_end_time = Time.now
    end
  end
end
