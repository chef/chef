#
# Author:: John Keiser (<jkeiser@chef.io)
# Copyright:: Copyright 2015-2017, Chef Software Inc.
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

require "chef/provider"
require "chef/exceptions"
require "chef/dsl/recipe"

class Chef
  class Resource
    class ActionClass < Chef::Provider
      include Chef::DSL::Recipe

      def to_s
        "#{new_resource || "<no resource>"} action #{action ? action.inspect : "<no action>"}"
      end

      #
      # If load_current_value! is defined on the resource, use that.
      #
      def load_current_resource
        if new_resource.respond_to?(:load_current_value!)
          # dup the resource and then reset desired-state properties.
          current_resource = new_resource.dup

          # We clear desired state in the copy, because it is supposed to be actual state.
          # We keep identity properties and non-desired-state, which are assumed to be
          # "control" values like `recurse: true`
          current_resource.class.properties.each do |name, property|
            if property.desired_state? && !property.identity? && !property.name_property?
              property.reset(current_resource)
            end
          end

          # Call the actual load_current_value! method. If it raises
          # CurrentValueDoesNotExist, set current_resource to `nil`.
          begin
            # If the user specifies load_current_value do |desired_resource|, we
            # pass in the desired resource as well as the current one.
            if current_resource.method(:load_current_value!).arity > 0
              current_resource.load_current_value!(new_resource)
            else
              current_resource.load_current_value!
            end
          rescue Chef::Exceptions::CurrentValueDoesNotExist
            current_resource = nil
          end
        end

        @current_resource = current_resource
      end

      # XXX: remove in Chef-14
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
