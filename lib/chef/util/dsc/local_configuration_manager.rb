#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/util/powershell/cmdlet"
require "chef/util/dsc/lcm_output_parser"

class Chef::Util::DSC
  class LocalConfigurationManager
    def initialize(node, configuration_path)
      @node = node
      @configuration_path = configuration_path
      clear_execution_time
    end

    def test_configuration(configuration_document, shellout_flags)
      status = run_configuration_cmdlet(configuration_document, false, shellout_flags)
      log_what_if_exception(status.stderr) unless status.succeeded?
      configuration_update_required?(status.return_value)
    end

    def set_configuration(configuration_document, shellout_flags)
      run_configuration_cmdlet(configuration_document, true, shellout_flags)
    end

    def last_operation_execution_time_seconds
      if @operation_start_time && @operation_end_time
        @operation_end_time - @operation_start_time
      end
    end

    private

    def run_configuration_cmdlet(configuration_document, apply_configuration, shellout_flags)
      Chef::Log.debug("DSC: Calling DSC Local Config Manager to #{apply_configuration ? "set" : "test"} configuration document.")
      test_only_parameters = ! apply_configuration ? "-whatif; if (! $?) { exit 1 }" : ""

      start_operation_timing
      command_code = lcm_command_code(@configuration_path, test_only_parameters)
      status = nil

      begin
        save_configuration_document(configuration_document)
        cmdlet = ::Chef::Util::Powershell::Cmdlet.new(@node, "#{command_code}")
        if apply_configuration
          status = cmdlet.run!({}, shellout_flags)
        else
          status = cmdlet.run({}, shellout_flags)
        end
      ensure
        end_operation_timing
        remove_configuration_document
        if last_operation_execution_time_seconds
          Chef::Log.debug("DSC: DSC operation completed in #{last_operation_execution_time_seconds} seconds.")
        end
      end
      Chef::Log.debug("DSC: Completed call to DSC Local Config Manager")
      status
    end

    def lcm_command_code(configuration_path, test_only_parameters)
      <<-EOH
$ProgressPreference = 'SilentlyContinue';start-dscconfiguration -path #{@configuration_path} -wait -erroraction 'stop' -force #{test_only_parameters}
EOH
    end

    def log_what_if_exception(what_if_exception_output)
      if whatif_not_supported?(what_if_exception_output)
        # LCM returns an error if any of the resources do not support the opptional What-If
        Chef::Log.warn("Received error while testing configuration due to resource not supporting 'WhatIf'")
      elsif dsc_module_import_failure?(what_if_exception_output)
        Chef::Log.warn("Received error while testing configuration due to a module for an imported resource possibly not being fully installed:\n#{what_if_exception_output.gsub(/\s+/, ' ')}")
      else
        Chef::Log.warn("Received error while testing configuration:\n#{what_if_exception_output.gsub(/\s+/, ' ')}")
      end
    end

    def whatif_not_supported?(what_if_exception_output)
      !! (what_if_exception_output.gsub(/[\r\n]+/, "").gsub(/\s+/, " ") =~ /A parameter cannot be found that matches parameter name 'Whatif'/i)
    end

    def dsc_module_import_failure?(what_if_output)
      !! (what_if_output =~ /\sCimException/ &&
        what_if_output =~ /ProviderOperationExecutionFailure/ &&
        what_if_output =~ /\smodule\s+is\s+installed/)
    end

    def configuration_update_required?(what_if_output)
      Chef::Log.debug("DSC: DSC returned the following '-whatif' output from test operation:\n#{what_if_output}")
      begin
        Parser.parse(what_if_output)
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
