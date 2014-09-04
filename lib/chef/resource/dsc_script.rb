#
# Author:: Adam Edwards (<adamed@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/exceptions'

class Chef
  class Resource
    class DscScript < Chef::Resource

      provides :dsc_script, :on_platforms => ["windows"]

      def initialize(name, run_context=nil)
        super
        @allowed_actions.push(:run)
        @action = :run
        if(run_context && Chef::Platform.supports_dsc?(run_context.node))
          @provider = Chef::Provider::DscScript
        else
          raise Chef::Exceptions::NoProviderAvailable,
            "#{powershell_info_str(run_context)}\nPowershell 4.0 or higher was not detected on your system and is required to use the dsc_script resource."
        end
      end

      def code(arg=nil)
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

      def configuration_name(arg=nil)
        if arg && code
          raise ArgumentError, "Attribute `configuration_name` may not be set if `code` is set"
        end
        set_or_return(
          :configuration_name,
          arg,
          :kind_of => [ String ]
        )
      end

      def command(arg=nil)
        if arg && code
          raise ArgumentError, "The 'code' and 'command' attributes may not be used together"
        end
        set_or_return(
          :command,
          arg,
          :kind_of => [ String ]
        )
      end

      def configuration_data(arg=nil)
        if arg && configuration_data_script
          raise ArgumentError, "The 'configuration_data' and 'configuration_data_script' attributes may not be used together"
        end
        set_or_return(
          :configuration_data,
          arg,
          :kind_of => [ String ]
        )
      end

      def configuration_data_script(arg=nil)
        if arg && configuration_data
          raise ArgumentError, "The 'configuration_data' and 'configuration_data_script' attributes may not be used together"
        end
        set_or_return(
          :configuration_data_script,
          arg,
          :kind_of => [ String ]
        )
      end

      def flags(arg=nil)
        set_or_return(
          :flags,
          arg,
          :kind_of => [ Hash ]
        )
      end

      def cwd(arg=nil)
        set_or_return(
          :cwd,
          arg,
          :kind_of => [ String ]
        )
      end

      def environment(arg=nil)
        set_or_return(
          :environment,
          arg,
          :kind_of => [ Hash ]
        )
      end

      def timeout(arg=nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => [ Integer ]
        )
      end

      private

      def powershell_info_str(run_context)
        if run_context && run_context.node[:languages] && run_context.node[:languages][:powershell]
            install_info = "Powershell #{run_context.node[:languages][:powershell][:version]} was found on the system."
          else
            install_info = 'Powershell was not found.'
          end
      end
    end
  end
end
