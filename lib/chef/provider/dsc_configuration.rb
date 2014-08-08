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
require 'chef/util/dsc/dsc_local_config_manager'

class Chef
  class Provider
    class DscConfiguration < Chef::Provider
      def initialize(dsc_resource, run_context)
        super(dsc_resource, run_context)
        @dsc_resource = dsc_resource
        @resource_converged = false
        @configuration_document = nil
      end

      def action_set
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
        if ! [:set, :test].include?(operation)
          raise RuntimeError, "Invalid operation `#{operation.to_s}` was specified"
        end

        config_directory = ::Dir.mktmpdir("dsc-script")
        config_manager = Chef::Util::DSC::DscLocalConfigManager.new(config_directory)

        begin
          configuration_document = generate_configuration_document(config_directory)
          if operation == :set
            config_manager.set_configuration(configuration_document)
          else
            config_manager.test_configuration(configuration_document)
          end
        rescue Exception => e
          Chef::Log.error("DSC operation failed: #{e.message.to_s}")
          raise e
        ensure
          ::FileUtils.rm_rf(config_directory)
        end
      end

      def generate_configuration_document(config_directory)
        return @configuration_document if @configuration_document

        Chef::Log.debug("DSC: DSC code:\n '#{configuration_code}'")

        generated_script_path = write_document_generation_script(config_directory) if @dsc_resource.path.nil?
        script_path = @dsc_resource.path || generated_script_path
        configuration_document_location = nil
        document_generation_cmdlet = Chef::Util::Powershell::Cmdlet.new(configuration_document_generation_code(script_path, configuration_name))

        begin
          document_generation_cmdlet.run({}, {:cwd => config_directory})
          configuration_document_location = find_configuration_document(config_directory)
        ensure
          ::FileUtils.rm(generated_script_path) if generated_script_path
        end  

        if ! configuration_document_location
          raise RuntimeError, "No DSC configuration for '#{configuration_name}' was generated from supplied DSC script"
        end

        @configuration_document = get_configuration_document(configuration_document_location)
        ::FileUtils.rm_rf(configuration_document_location)
        @configuration_document
      end

      def write_document_generation_script(config_directory)
        script_path = "#{config_directory}/dsc_config.ps1"
        ::File.open(script_path, 'wt') do | script |
          script.write(configuration_code)
        end
        script_path
      end

      def configuration_name
        if @dsc_resource.configuration
          'chef_dsc'
        else
          @dsc_resource.configuration_name || @dsc_resource.name
        end
      end

      def configuration_friendly_name
        if @dsc_resource.configuration
          @dsc_resource.name
        else
          configuration_name
        end
      end

      def configuration_code
        "$ProgressPreference = 'SilentlyContinue';Configuration '#{configuration_name}'\n{\n\t#{@dsc_resource.configuration}\n}\n"
      end

      def configuration_document_generation_code(configuration_script, configuration_name)
        ". '#{configuration_script}';#{configuration_name}"
      end

      def find_configuration_document(config_directory)
        document_directory = ::File.join(config_directory, configuration_name)
        document_file_name = ::Dir.entries(document_directory).find { | path | path =~ /.*.mof/ }
        ::File.join(document_directory, document_file_name)
      end

      def get_configuration_document(document_directory)
        ::File.open(document_directory, 'rb') do | file |
          file.read
        end
      end
    end
  end
end
