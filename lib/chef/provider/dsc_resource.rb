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
require 'chef/util/dsc/local_configuration_manager'
require 'chef/mixin/powershell_type_coercions'

class Chef
  class Provider
    class DscResource < Chef::Provider

      provides :dsc_resource, os: "windows"

      def initialize(new_resource, run_context)
        super
        @new_resource = new_resource
        @resource_converged = false
      end

      def action_run
        if ! @resource_converged
          converge_by(generate_description) do
            set_configuration
          end
        end
      end

      def load_current_resource
        @resource_converged = test_resource
      end

      def whyrun_supported?
        true
      end

      def define_resource_requirements
        requirements.assert(:run) do |a|
          a.assertion { supports_dsc_invoke_resource? }
          err = "Assuming a previous resource installs Powershell 5.0.10018.0 or higher."
          a.failure_message Chef::Exceptions::NoProviderAvailable,
            err
          a.whyrun err
          a.block_action!
        end
        requirements.assert(:run) do |a|
          a.assertion {
            local_configuration_manager.meta_configuration['RefreshMode'] == 'Disabled'
          }
          err = ["The LCM must have its RefreshMode set to Disabled. "]
          a.failure_message Chef::Exceptions::NoProviderAvailable, err.join(' ')
          a.whyrun err + ["Assuming a previous resource sets the RefreshMode."]
          a.block_action!
        end
      end

      protected

      def local_configuration_manager
        @local_configuration_manager ||= Chef::Util::DSC::LocalConfigurationManager(
          @run_context.node,
          nil
        )
      end

      def supports_dsc_invoke_resource?
        run_context && Chef::Platform.supports_dsc_invoke_resource?(node)
      end

      def generate_description
        "Converge dsc resource"
      end

      def test_resource
        result = invoke_resource(:test)
        result.return_value["IsDesiredState"]
      end

      def set_resource
        result = invoke_resource(:set)
        result.return_value
      end

      def invoke_resource(method)
        properties = translate_type(@new_resource.properties)
        switches = "-Method #{method.to_s} -Name #{@new_resource.resource} -Property"
            + "#{properties} -Verbose"
        cmdlet = Chef::Util::Powershell::Cmdlet.new(
          @node,
          "Invoke-DscResource #{switches}",
          :object
        )
        cmdlet.run!
      end

      def meta_configuration
        cmdlet = Chef::Util::Powershell::Cmdlet.new(@node, "Get-DscLocalConfigurationManager", :object)
        result = cmdlet.run!
        result.return_value
      end

    end
  end
end
