#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "timeout" unless defined?(Timeout)
require_relative "../mixin/powershell_exec"
require_relative "../util/dsc/local_configuration_manager"
require_relative "../mixin/powershell_type_coercions"
require_relative "../util/dsc/resource_store"

class Chef
  class Provider
    class DscResource < Chef::Provider
      include Chef::Mixin::PowershellTypeCoercions
      provides :dsc_resource
      def initialize(new_resource, run_context)
        super
        @new_resource = new_resource
        @module_name = new_resource.module_name
        @module_version = new_resource.module_version
        @reboot_resource = nil
      end

      action :run do
        unless test_resource
          converge_by(generate_description) do
            result = set_resource
            reboot_if_required
          end
        end
      end

      def load_current_resource; end

      def define_resource_requirements
        requirements.assert(:run) do |a|
          a.assertion { supports_dsc_invoke_resource? }
          err = ["You must have PowerShell version >= 5.0.10018.0 to use dsc_resource."]
          a.failure_message Chef::Exceptions::ProviderNotFound,
            err
          a.whyrun err + ["Assuming a previous resource installs PowerShell 5.0.10018.0 or higher."]
          a.block_action!
        end
        requirements.assert(:run) do |a|
          a.assertion { supports_refresh_mode_enabled? || dsc_refresh_mode_disabled? }
          err = ["The LCM must have its RefreshMode set to Disabled for" \
                 " PowerShell versions before 5.0.10586.0."]
          a.failure_message Chef::Exceptions::ProviderNotFound, err.join(" ")
          a.whyrun err + ["Assuming a previous resource sets the RefreshMode."]
          a.block_action!
        end
        requirements.assert(:run) do |a|
          a.assertion { module_usage_valid? }
          err = ["module_name must be supplied along with module_version."]
          a.failure_message Chef::Exceptions::DSCModuleNameMissing,
            err
          a.block_action!
        end
      end

      protected

      def local_configuration_manager
        @local_configuration_manager ||= Chef::Util::DSC::LocalConfigurationManager.new(
          node,
          nil
        )
      end

      def resource_store
        Chef::Util::DSC::ResourceStore.instance
      end

      def supports_dsc_invoke_resource?
        run_context && Chef::Platform.supports_dsc_invoke_resource?(node)
      end

      def dsc_refresh_mode_disabled?
        Chef::Platform.dsc_refresh_mode_disabled?(node)
      end

      def supports_refresh_mode_enabled?
        Chef::Platform.supports_refresh_mode_enabled?(node)
      end

      def module_usage_valid?
        !(!@module_name && @module_version)
      end

      def generate_description
        @converge_description
      end

      def dsc_resource_name
        new_resource.resource.to_s
      end

      def module_name
        @module_name ||= begin
          found = resource_store.find(dsc_resource_name)
          r = case found.length
              when 0
                raise Chef::Exceptions::ResourceNotFound,
                  "Could not find #{dsc_resource_name}. Check to make " \
                  "sure that it shows up when running Get-DscResource"
              when 1
                if found[0]["Module"].nil?
                  "PSDesiredStateConfiguration" # default DSC module
                else
                  found[0]["Module"]["Name"]
                end
              else
                raise Chef::Exceptions::MultipleDscResourcesFound, found
              end
        end
      end

      def test_resource
        result = invoke_resource(:test)
        add_dsc_verbose_log(result)
        result.result["InDesiredState"]
      end

      def set_resource
        result = invoke_resource(:set)
        add_dsc_verbose_log(result)
        create_reboot_resource if result.result["RebootRequired"]
        result
      end

      def add_dsc_verbose_log(result)
        # We really want this information from the verbose stream,
        # however in some versions of WMF, Invoke-DscResource is not correctly
        # writing to that stream and instead just dumping to stdout
        verbose_output = result.verbose.join("\n")
        verbose_output = result.result if verbose_output.empty?

        if @converge_description.nil? || @converge_description.empty?
          @converge_description = verbose_output
        else
          @converge_description << "\n\n"
          @converge_description << verbose_output
        end
      end

      def module_info_object
        @module_version.nil? ? module_name : "@{ModuleName='#{module_name}';ModuleVersion='#{@module_version}'}"
      end

      def invoke_resource(method)
        properties = translate_type(new_resource.properties)
        switches = "-Method #{method} -Name #{new_resource.resource}" \
                   " -Property #{properties} -Module #{module_info_object} -Verbose"
        Timeout.timeout(new_resource.timeout) {
          powershell_exec!("Invoke-DscResource #{switches}")
        }
      end

      def create_reboot_resource
        @reboot_resource = Chef::Resource::Reboot.new(
          "Reboot for #{new_resource.name}",
          run_context
        ).tap do |r|
          r.reason("Reboot for #{new_resource.resource}.")
        end
      end

      def reboot_if_required
        reboot_action = new_resource.reboot_action
        unless @reboot_resource.nil?
          case reboot_action
          when :nothing
            logger.trace("A reboot was requested by the DSC resource, but reboot_action is :nothing.")
            logger.trace("This dsc_resource will not reboot the node.")
          else
            logger.trace("Requesting node reboot with #{reboot_action}.")
            @reboot_resource.run_action(reboot_action)
          end
        end
      end
    end
  end
end
