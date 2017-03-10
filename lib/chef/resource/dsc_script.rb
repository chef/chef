#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/exceptions"
require "chef/dsl/powershell"

class Chef
  class Resource
    class DscScript < Chef::Resource
      include Chef::DSL::Powershell

      provides :dsc_script, os: "windows"

      default_action :run

      def initialize(name, run_context = nil)
        super
        @imports = {}
      end

      def code(arg = nil)
        if arg && command
          raise ArgumentError, "Only one of 'code' and 'command' attributes may be specified"
        end
        if arg && configuration_name
          raise ArgumentError, "The 'code' and 'command' attributes may not be used together"
        end
        set_or_return(
          :code,
          arg,
          :kind_of => [ String ]
        )
      end

      def configuration_name(arg = nil)
        if arg && code
          raise ArgumentError, "Attribute `configuration_name` may not be set if `code` is set"
        end
        set_or_return(
          :configuration_name,
          arg,
          :kind_of => [ String ]
        )
      end

      def command(arg = nil)
        if arg && code
          raise ArgumentError, "The 'code' and 'command' attributes may not be used together"
        end
        set_or_return(
          :command,
          arg,
          :kind_of => [ String ]
        )
      end

      def configuration_data(arg = nil)
        if arg && configuration_data_script
          raise ArgumentError, "The 'configuration_data' and 'configuration_data_script' attributes may not be used together"
        end
        set_or_return(
          :configuration_data,
          arg,
          :kind_of => [ String ]
        )
      end

      def configuration_data_script(arg = nil)
        if arg && configuration_data
          raise ArgumentError, "The 'configuration_data' and 'configuration_data_script' attributes may not be used together"
        end
        set_or_return(
          :configuration_data_script,
          arg,
          :kind_of => [ String ]
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

      def flags(arg = nil)
        set_or_return(
          :flags,
          arg,
          :kind_of => [ Hash ]
        )
      end

      def cwd(arg = nil)
        set_or_return(
          :cwd,
          arg,
          :kind_of => [ String ]
        )
      end

      def environment(arg = nil)
        set_or_return(
          :environment,
          arg,
          :kind_of => [ Hash ]
        )
      end

      def timeout(arg = nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => [ Integer ]
        )
      end
    end
  end
end
