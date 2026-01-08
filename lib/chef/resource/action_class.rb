#
# Author:: John Keiser (<jkeiser@chef.io)
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

require_relative "../provider"
require_relative "../exceptions"
require_relative "../dsl/recipe"

class Chef
  class Resource
    class ActionClass < Chef::Provider
      include Chef::DSL::Recipe

      def to_s
        "#{new_resource || "<no resource>"} action #{action ? action.inspect : "<no action>"}"
      end

      def return_load_current_value
        resource = nil
        if new_resource.respond_to?(:load_current_value!)
          resource = new_resource.class.new(new_resource.name, new_resource.run_context)

          # copy the non-desired state, the identity properties and name property to the new resource
          # (the desired state values must be loaded by load_current_value)
          resource.class.properties.each_value do |property|
            if !property.desired_state? || property.identity? || property.name_property?
              property.set(resource, new_resource.send(property.name)) if new_resource.class.properties[property.name].is_set?(new_resource)
            end
          end

          # we support optionally passing the new_resource as an arg to load_current_value and
          # load_current_value can raise in order to clear the current_resource to nil
          begin
            if resource.method(:load_current_value!).arity > 0
              resource.load_current_value!(new_resource)
            else
              resource.load_current_value!
            end
          rescue Chef::Exceptions::CurrentValueDoesNotExist
            resource = nil
          end
        end
        resource
      end

      # build the before state (current_resource)
      def load_current_resource
        @current_resource = return_load_current_value
      end

      # build the after state (after_resource)
      def load_after_resource
        @after_resource = return_load_current_value
      end

      def self.include_resource_dsl?
        true
      end

      class << self
        #
        # The Chef::Resource class this ActionClass was declared against.
        #
        # @return [Class] The Chef::Resource class this ActionClass was declared against.
        #
        attr_accessor :resource_class
      end

      def self.to_s
        "#{resource_class} action provider"
      end

      def self.inspect
        to_s
      end
    end
  end
end
