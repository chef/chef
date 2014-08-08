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

class Chef
  class Resource
    class DscConfiguration < Chef::Resource

      provides :dsc_configuration, :on_platforms => ["windows"]

      def initialize(name, run_context=nil)
        super

        @allowed_actions.push(:set)
        @action = :set

        @configuration = nil
        @configuration_name = nil
        @path = nil
        provider(Chef::Provider::DscConfiguration)
      end

      def configuration(arg=nil)
        if arg && @path
          raise ArgumentError, "Only one of 'configuration' and 'path' properties may be specified"
        end
        if arg && @configuration_name
          raise ArgumentError, "Attribute `configuration` may not be set if `configuration_name` is set"
        end
        set_or_return(
          :configuration,
          arg,
          :kind_of => [ String ]
        )
      end

      def configuration_name(arg=nil)
        if arg && @configuration
          raise ArgumentError, "Attribute `configuration_name` may not be set if `configuration` is set"
        end
        set_or_return(
          :configuration_name,
          arg,
          :kind_of => [ String ]
        )
      end

      def path(arg=nil)
        if arg && @configuration 
          raise ArgumentError, "Only one of 'configuration' and 'path' properties may be specified"
        end
        set_or_return(
          :path,
          arg,
          :kind_of => [ String ]
        )
      end
      
    end
  end
end
