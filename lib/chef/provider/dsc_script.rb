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
          converge_by(generate_description) do
            run_configuration(:set)
            Chef::Log.info("DSC resource configuration completed successfully")
          end
        end
      end

      def load_current_resource
        @dsc_resources_info = run_configuration(:test)
        @resource_converged = @dsc_resources_info.all? do |resource|
          !resource.changes_state?
        end
      end

      def whyrun_supported?
        true
      end

      protected

      def run_configuration(operation)
        configuration_flags = get_augmented_configuration_flags(@dsc_resource.flags)
        config_directory = ::Dir.mktmpdir("chef-dsc-script")

        config_manager = Chef::Util::DSC::LocalConfigurationManager.new(@run_context.node, config_directory)

        begin
          configuration_document = generate_configuration_document(config_directory, configuration_flags)
          @operations[operation].call(config_manager, configuration_document)
        rescue Exception => e
          Chef::Log.error("DSC operation failed: #{e.message.to_s}")
          raise e
        ensure
          ::FileUtils.rm_rf(config_directory)
        end
      end

      def get_augmented_configuration_flags(flags)
        updated_flags = nil
        if @dsc_resource.configuration_data
          updated_flags = flags.nil? ? {} : flags.dup
          Chef::Util::PathHelper.validate_path(@dsc_resource.configuration_data)
          updated_flags[:configurationdata] = @dsc_resource.configuration_data
        end
        updated_flags
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

      private

      def generate_description
        ["DSC resource script for configuration '#{configuration_friendly_name}'"] + 
          @dsc_resources_info.map do |resource|
            # We ignore the last log message because it only contains the time it took, which looks weird
            cleaned_messages = resource.change_log[0..-2].map { |c| c.sub(/^#{Regexp.escape(resource.name)}/, '').strip }
            cleaned_messages.find_all{ |c| c != ''}.join("\n")
          end
      end
    end
  end
end
