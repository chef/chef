#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
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

require_relative "../resource"
require_relative "../exceptions"
require_relative "../dsl/powershell"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class DscScript < Chef::Resource
      include Chef::DSL::Powershell

      provides :dsc_script

      description <<~DESC
        Many DSC resources are comparable to built-in #{ChefUtils::Dist::Infra::PRODUCT} resources. For example, both DSC and #{ChefUtils::Dist::Infra::PRODUCT}
        have file, package, and service resources. The dsc_script resource is most useful for those DSC resources that do not have a direct comparison to a
        resource in #{ChefUtils::Dist::Infra::PRODUCT}, such as the Archive resource, a custom DSC resource, an existing DSC script that performs an important
        task, and so on. Use the dsc_script resource to embed the code that defines a DSC configuration directly within a #{ChefUtils::Dist::Infra::PRODUCT} recipe.

        Warning: The **dsc_script** resource is only available on 64-bit Chef Infra Client.
      DESC

      default_action :run

      def initialize(name, run_context = nil)
        super
        @imports = {}
      end

      def code(arg = nil)
        if arg && command
          raise ArgumentError, "Only one of 'code' and 'command' properties may be specified"
        end
        if arg && configuration_name
          raise ArgumentError, "The 'code' and 'command' properties may not be used together"
        end

        set_or_return(
          :code,
          arg,
          kind_of: [ String ]
        )
      end

      def configuration_name(arg = nil)
        if arg && code
          raise ArgumentError, "Property `configuration_name` may not be set if `code` is set"
        end

        set_or_return(
          :configuration_name,
          arg,
          kind_of: [ String ]
        )
      end

      def command(arg = nil)
        if arg && code
          raise ArgumentError, "The 'code' and 'command' properties may not be used together"
        end

        set_or_return(
          :command,
          arg,
          kind_of: [ String ]
        )
      end

      def configuration_data(arg = nil)
        if arg && configuration_data_script
          raise ArgumentError, "The 'configuration_data' and 'configuration_data_script' properties may not be used together"
        end

        set_or_return(
          :configuration_data,
          arg,
          kind_of: [ String ]
        )
      end

      def configuration_data_script(arg = nil)
        if arg && configuration_data
          raise ArgumentError, "The 'configuration_data' and 'configuration_data_script' properties may not be used together"
        end

        set_or_return(
          :configuration_data_script,
          arg,
          kind_of: [ String ]
        )
      end

      def imports(module_name = nil, *args)
        if module_name
          @imports[module_name] ||= []
          if args.length == 0
            @imports[module_name] << "*"
          else
            @imports[module_name].push(*args)
          end
        else
          @imports
        end
      end

      property :flags, Hash,
        description: "Pass parameters to the DSC script that is specified by the command property. Parameters are defined as key-value pairs, where the value of each key is the parameter to pass. This property may not be used in the same recipe as the code property."

      property :cwd, String,
        description: "The current working directory."

      property :environment, Hash,
        description: "A Hash of environment variables in the form of ({'ENV_VARIABLE' => 'VALUE'}). (These variables must exist for a command to be run successfully)."

      property :timeout, Integer,
        description: "The amount of time (in seconds) a command is to wait before timing out.",
        desired_state: false
    end
  end
end
