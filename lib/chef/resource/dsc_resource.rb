#
# Author:: Adam Edwards (<adamed@getchef.com>)
#
# Copyright:: 2014, Opscode, Inc.
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
    class DscResource < Chef::Resource

      provides :dsc_resource, platform: "windows"

      attr_reader :properties

      def initialize(name, run_context)
        super
        @properties = {}
        @resource_name = :dsc_resource
        @resource = nil
        @allowed_actions.push(:set)
        @action = :set
      end

      def resource(value=nil)
        if value
          @resource = value
        else
          @resource
        end
      end

      def property(property_name, value=nil)
        if not property_name.is_a?(Symbol)
          raise TypeError, "A property name of type Symbol must be specified, '#{property_name.to_s}' of type #{property_name.class.to_s} was given"
        end

        if value.nil?
          @properties[property_name]
        else
          @properties[property_name] = value
        end
      end
    end
  end
end
