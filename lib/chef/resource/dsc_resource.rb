#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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
require "chef/dsl/powershell"

class Chef
  class Resource
    class DscResource < Chef::Resource
      provides :dsc_resource, os: "windows"

      # This class will check if the object responds to
      # to_text. If it does, it will call that as opposed
      # to inspect. This is useful for properties that hold
      # objects such as PsCredential, where we do not want
      # to dump the actual ivars
      class ToTextHash < Hash
        def to_text
          descriptions = map do |(property, obj)|
            obj_text = if obj.respond_to?(:to_text)
                         obj.to_text
                       else
                         obj.inspect
                       end
            "#{property}=>#{obj_text}"
          end
          "{#{descriptions.join(', ')}}"
        end
      end

      include Chef::DSL::Powershell

      default_action :run

      def initialize(name, run_context)
        super
        @properties = ToTextHash.new
        @resource = nil
        @reboot_action = :nothing
      end

      def resource(value = nil)
        if value
          @resource = value
        else
          @resource
        end
      end

      def module_name(value = nil)
        if value
          @module_name = value
        else
          @module_name
        end
      end

      def module_version(arg = nil)
        set_or_return(
          :module_version,
          arg,
          :kind_of => [ String ]
        )
      end

      def property(property_name, value = nil)
        if not property_name.is_a?(Symbol)
          raise TypeError, "A property name of type Symbol must be specified, '#{property_name}' of type #{property_name.class} was given"
        end

        if value.nil?
          value_of(@properties[property_name])
        else
          @properties[property_name] = value
        end
      end

      def properties
        @properties.reduce({}) do |memo, (k, v)|
          memo[k] = value_of(v)
          memo
        end
      end

      # This property takes the action message for the reboot resource
      # If the set method of the DSC resource indicate that a reboot
      # is necessary, reboot_action provides the mechanism for a reboot to
      # be requested.
      def reboot_action(value = nil)
        if value
          @reboot_action = value
        else
          @reboot_action
        end
      end

      def timeout(arg = nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => [ Integer ]
        )
      end

      private

      def value_of(value)
        if value.is_a?(DelayedEvaluator)
          value.call
        else
          value
        end
      end
    end
  end
end
