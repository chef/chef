#
# Author:: Seth Chisamore (<schisamo@chef.io>)
#
# Copyright:: 2011-2018, Chef Software, Inc.
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
class Chef
  class Resource
    class WindowsFeature < Chef::Resource
      resource_name :windows_feature
      provides :windows_feature

      property :feature_name, [Array, String], name_property: true
      property :source, String
      property :all, [true, false], default: false
      property :management_tools, [true, false], default: false
      property :install_method, Symbol, equal_to: [:windows_feature_dism, :windows_feature_powershell, :windows_feature_servermanagercmd]
      property :timeout, Integer, default: 600

      action :install do
        run_default_provider :install
      end

      action :remove do
        run_default_provider :remove
      end

      action :delete do
        run_default_provider :delete
      end

      action_class do
        # @return [Symbol] :windows_feature_dism or the provider specified in install_method property
        def locate_default_provider
          if new_resource.install_method
            new_resource.install_method
          else
            :windows_feature_dism
          end
        end

        # call the appropriate windows_feature resource based on the specified provider
        # @return [void]
        def run_default_provider(desired_action)
          case locate_default_provider
          when :windows_feature_dism
            windows_feature_dism new_resource.name do
              action desired_action
              feature_name new_resource.feature_name
              source new_resource.source if new_resource.source
              all new_resource.all
              timeout new_resource.timeout
            end
          when :windows_feature_servermanagercmd
            raise "Support for Windows feature installation via servermanagercmd.exe has been removed as this support is no longer needed in Windows 2008 R2 and above. You will need to update your cookbook to install either via dism or powershell (preferred)."
          when :windows_feature_powershell
            windows_feature_powershell new_resource.name do
              action desired_action
              feature_name new_resource.feature_name
              source new_resource.source if new_resource.source
              all new_resource.all
              timeout new_resource.timeout
              management_tools new_resource.management_tools
            end
          end
        end
      end
    end
  end
end
