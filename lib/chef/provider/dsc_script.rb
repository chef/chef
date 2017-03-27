#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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
require "chef/util/dsc/configuration_generator"
require "chef/util/dsc/local_configuration_manager"
require "chef/util/path_helper"

class Chef
  class Provider
    class DscScript < Chef::Provider

      provides :dsc_script, os: "windows"

      def initialize(dsc_resource, run_context)
        super(dsc_resource, run_context)
        @dsc_resource = dsc_resource
        @resource_converged = false
        @operations = {
          :set => Proc.new do |config_manager, document, shellout_flags|
            config_manager.set_configuration(document, shellout_flags)
          end,
          :test => Proc.new do |config_manager, document, shellout_flags|
            config_manager.test_configuration(document, shellout_flags)
          end }
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
        if supports_dsc?
          @dsc_resources_info = run_configuration(:test)
          @resource_converged = @dsc_resources_info.all? do |resource|
            !resource.changes_state?
          end
        end
      end

      def define_resource_requirements
        requirements.assert(:run) do |a|
          err = [
            "Could not find PowerShell DSC support on the system",
            powershell_info_str,
            "Powershell 4.0 or higher was not detected on your system and is required to use the dsc_script resource.",
          ]
          a.assertion { supports_dsc? }
          a.failure_message Chef::Exceptions::ProviderNotFound, err.join(" ")
          a.whyrun err + ["Assuming a previous resource installs Powershell 4.0 or higher."]
          a.block_action!
        end
      end

      protected

      def supports_dsc?
        run_context && Chef::Platform.supports_dsc?(node)
      end

      def run_configuration(operation)
        config_directory = ::Dir.mktmpdir("chef-dsc-script")
        configuration_data_path = get_configuration_data_path(config_directory)
        configuration_flags = get_augmented_configuration_flags(configuration_data_path)

        config_manager = Chef::Util::DSC::LocalConfigurationManager.new(@run_context.node, config_directory)

        shellout_flags = {
          :cwd => @dsc_resource.cwd,
          :environment => @dsc_resource.environment,
          :timeout => @dsc_resource.timeout,
        }

        begin
          configuration_document = generate_configuration_document(config_directory, configuration_flags)
          @operations[operation].call(config_manager, configuration_document, shellout_flags)
        rescue Exception => e
          Chef::Log.error("DSC operation failed: #{e.message}")
          raise e
        ensure
          ::FileUtils.rm_rf(config_directory)
        end
      end

      def get_augmented_configuration_flags(configuration_data_path)
        updated_flags = @dsc_resource.flags.nil? ? {} : @dsc_resource.flags.dup
        if configuration_data_path
          Chef::Util::PathHelper.validate_path(configuration_data_path)
          updated_flags[:configurationdata] = configuration_data_path
        end
        updated_flags
      end

      def generate_configuration_document(config_directory, configuration_flags)
        shellout_flags = {
          :cwd => @dsc_resource.cwd,
          :environment => @dsc_resource.environment,
          :timeout => @dsc_resource.timeout,
        }

        generator = Chef::Util::DSC::ConfigurationGenerator.new(@run_context.node, config_directory)

        if @dsc_resource.command
          generator.configuration_document_from_script_path(@dsc_resource.command, configuration_name, configuration_flags, shellout_flags)
        else
          # If code is also not provided, we mimic what the other script resources do (execute nothing)
          Chef::Log.warn("Neither code or command were provided for dsc_resource[#{@dsc_resource.name}].") unless @dsc_resource.code
          generator.configuration_document_from_script_code(@dsc_resource.code || "", configuration_flags, @dsc_resource.imports, shellout_flags)
        end
      end

      def get_configuration_data_path(config_directory)
        if @dsc_resource.configuration_data_script
          @dsc_resource.configuration_data_script
        elsif @dsc_resource.configuration_data
          configuration_data_path = "#{config_directory}/chef_dsc_config_data.psd1"
          ::File.open(configuration_data_path, "wt") do |script|
            script.write(@dsc_resource.configuration_data)
          end
          configuration_data_path
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
        ["converge DSC configuration '#{configuration_friendly_name}'"] +
          @dsc_resources_info.map do |resource|
            if resource.changes_state?
              # We ignore the last log message because it only contains the time it took, which looks weird
              cleaned_messages = resource.change_log[0..-2].map { |c| c.sub(/^#{Regexp.escape(resource.name)}/, "").strip }
              "converge DSC resource #{resource.name} by #{cleaned_messages.find_all { |c| c != '' }.join("\n")}"
            else
              # This is needed because a dsc script can have resources that are both converged and not
              "converge DSC resource #{resource.name} by doing nothing because it is already converged"
            end
          end
      end

      def powershell_info_str
        if run_context && run_context.node[:languages] && run_context.node[:languages][:powershell]
          install_info = "Powershell #{run_context.node[:languages][:powershell][:version]} was found on the system."
        else
          install_info = "Powershell was not found."
        end
      end
    end
  end
end
