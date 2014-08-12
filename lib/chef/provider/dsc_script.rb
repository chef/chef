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
require 'chef/util/dsc/configuration_generator'
require 'chef/util/dsc/local_configuration_manager'

class Chef
  class Provider
    class DscScript < Chef::Provider
      def initialize(dsc_resource, run_context)
        super(dsc_resource, run_context)
        @dsc_resource = dsc_resource
        @resource_converged = false
        @operations = {
          :set => Proc.new { |config_manager, document| 
            config_manager.set_configuration(document)
          },
          :test => Proc.new { |config_manager, document| 
            config_manager.test_configuration(document)
          }}
      end

      def action_run
        if ! @resource_converged
          converge_by("DSC resource script for configuration '#{configuration_friendly_name}'") do
            run_configuration(:set)
            Chef::Log.info("DSC resource configuration completed successfully")
          end
        end
      end

      def load_current_resource
        @resource_converged = ! run_configuration(:test)
      end

      def whyrun_supported?
        true
      end

      protected

      def run_configuration(operation)
        config_directory = ::Dir.mktmpdir("dsc-script")

        config_manager = Chef::Util::DSC::LocalConfigurationManager.new(@run_context.node, config_directory)

        begin
          configuration_document = generate_configuration_document(config_directory, @dsc_resource.flags)
          @operations[operation].call(config_manager, configuration_document)
        rescue Exception => e
          Chef::Log.error("DSC operation failed: #{e.message.to_s}")
          raise e
        ensure
          ::FileUtils.rm_rf(config_directory)
        end
      end

      def generate_configuration_document(config_directory, configuration_flags)
        shellout_flags = {
          :cwd => @dsc_resource.cwd,
          :environment => @dsc_resource.environment,
          :timeout => @dsc_resource.timeout
        }

        generator = Chef::Util::DSC::ConfigurationGenerator.new(@run_context.node, config_directory)

        if @dsc_resource.command
          generator.configuration_document_from_script_path(@dsc_resource.command, configuration_name, configuration_flags, shellout_flags)
        else
          generator.configuration_document_from_script_code(@dsc_resource.code, configuration_flags, shellout_flags)
        end
      end

      def configuration_name
        @dsc_resource.configuration_name || @dsc_resource.name
      end

      def configuration_friendly_name
        if @dsc_resource.code
          @dsc_resource.name
        else
          configuration_name
        end
      end
    end
  end
end
