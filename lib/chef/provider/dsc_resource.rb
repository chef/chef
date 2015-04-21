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
require 'chef/util/dsc/resource_store'

class Chef
  class Provider
    class DscResource < Chef::Provider
      include Chef::Mixin::PowershellTypeCoercions

      provides :dsc_resource, os: "windows"

      def initialize(new_resource, run_context)
        super
        @new_resource = new_resource
        @module_name = new_resource.module_name
      end

      def action_run
        if ! test_resource
          converge_by(generate_description) do
            result = set_resource
          end
        end
      end

      def load_current_resource
      end

      def whyrun_supported?
        true
      end

      def define_resource_requirements
        requirements.assert(:run) do |a|
          a.assertion { supports_dsc_invoke_resource? }
          err = ["You must have Powershell version >= 5.0.10018.0 to use dsc_resource."]
          a.failure_message Chef::Exceptions::NoProviderAvailable,
            err
          a.whyrun err + ["Assuming a previous resource installs Powershell 5.0.10018.0 or higher."]
          a.block_action!
        end
        requirements.assert(:run) do |a|
          a.assertion {
            meta_configuration['RefreshMode'] == 'Disabled'
          }
          err = ["The LCM must have its RefreshMode set to Disabled. "]
          a.failure_message Chef::Exceptions::NoProviderAvailable, err.join(' ')
          a.whyrun err + ["Assuming a previous resource sets the RefreshMode."]
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
                  "Could not find #{dsc_resource_name}. Check to make "\
                  "sure that it shows up when running Get-DscResource"
              when 1
                if found[0]['Module'].nil?
                  :none
                else
                  found[0]['Module']['Name']
                end
              else
                raise Chef::Exceptions::MultipleDscResourcesFound, found
              end
        end
      end

      def test_resource
        result = invoke_resource(:test)
        # We really want this information from the verbose stream,
        # however Invoke-DscResource is not correctly writing to that
        # stream and instead just dumping to stdout
        @converge_description = result.stdout
        result.return_value[0]["InDesiredState"]
      end

      def set_resource
        result = invoke_resource(:set)
        result.return_value
      end

      def invoke_resource(method, output_format=:object)
        properties = translate_type(@new_resource.properties)
        switches = "-Method #{method.to_s} -Name #{@new_resource.resource}"\
                   " -Property #{properties} -Verbose"

        if module_name != :none
          switches += " -Module #{module_name}"
        end

        cmdlet = Chef::Util::Powershell::Cmdlet.new(
          node,
          "Invoke-DscResource #{switches}",
          output_format
        )
        cmdlet.run!
      end

      def meta_configuration
        cmdlet = Chef::Util::Powershell::Cmdlet.new(node, "Get-DscLocalConfigurationManager", :object)
        result = cmdlet.run!
        result.return_value
      end

    end
  end
end
