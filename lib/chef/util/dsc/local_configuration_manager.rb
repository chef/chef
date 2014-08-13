#
# Author:: Adam Edwards (<adamed@getchef.com>)
#
# Copyright:: 2014, Chef Software, Inc.
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

require 'chef/util/powershell/cmdlet'
require 'chef/util/dsc/lcm_output_parser'

class Chef::Util::DSC
  class LocalConfigurationManager
    def initialize(node, configuration_path)
      @node = node
      @configuration_path = configuration_path
      clear_execution_time
    end
    
    def test_configuration(configuration_document)
      status = run_configuration_cmdlet(configuration_document)
      configuration_update_required?(status.return_value)
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

    def run_configuration_cmdlet(configuration_document, apply_configuration = false)
      Chef::Log.debug("DSC: Calling DSC Local Config Manager to #{apply_configuration ? "set" : "test"} configuration document.")
      test_only_parameters = ! apply_configuration ? '-whatif; if (! $?) { exit 1 }' : ''

      start_operation_timing
      command_code = "$ProgressPreference = 'SilentlyContinue';start-dscconfiguration -path #{@configuration_path} -wait -force #{test_only_parameters}"
      status = nil

      begin
        save_configuration_document(configuration_document)
        cmdlet = ::Chef::Util::Powershell::Cmdlet.new(@node, "#{command_code}")
        status = cmdlet.run
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

    def configuration_update_required?(what_if_output)
      Chef::Log.debug("DSC: DSC returned the following '-whatif' output from test operation:\n#{what_if_output}")
      #parse_what_if_output(what_if_output)
      Parser::parse(what_if_output)
    end

    def save_configuration_document(configuration_document)
      ::FileUtils.mkdir_p(@configuration_path)
      ::File.open(configuration_document_path, 'wb') do | file |
        file.write(configuration_document)
      end
    end

    def remove_configuration_document
      ::FileUtils.rm(configuration_document_path)
    end

    def configuration_document_path
      File.join(@configuration_path,'..mof')
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
