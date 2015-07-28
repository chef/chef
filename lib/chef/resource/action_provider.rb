#
# Author:: John Keiser (<jkeiser@chef.io)
# Copyright:: Copyright (c) 2015 Opscode, Inc.
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
    module ActionProvider
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
          current_resource.class.properties.each do |name,property|
            if property.desired_state? && !property.identity? && !property.name_property?
              property.reset(current_resource)
            end
          end

          if current_resource.method(:load_current_value!).arity > 0
            current_resource.load_current_value!(new_resource)
          else
            current_resource.load_current_value!
          end
        elsif superclass.public_instance_method?(:load_current_resource)
          super
        end
        @current_resource = current_resource
      end

      #
      # Handle patchy convergence safely.
      #
      # - Does *not* call the block if the current_resource's properties match
      #   the properties the user specified on the resource.
      # - Calls the block if current_resource does not exist
      # - Calls the block if the user has specified any properties in the resource
      #   whose values are *different* from current_resource.
      # - Does *not* call the block if why-run is enabled (just prints out text).
      # - Prints out automatic green text saying what properties have changed.
      #
      # @param properties An optional list of property names (symbols). If not
      #   specified, `new_resource.class.state_properties` will be used.
      # @param converge_block The block to do the converging in.
      #
      # @return [Boolean] whether the block was executed.
      #
      def converge_if_changed(*properties, &converge_block)
        properties = new_resource.class.state_properties.map { |p| p.name } if properties.empty?
        properties = properties.map { |p| p.to_sym }
        if current_resource
          # Collect the list of modified properties
          specified_properties = properties.select { |property| new_resource.property_is_set?(property) }
          modified = specified_properties.select { |p| new_resource.send(p) != current_resource.send(p) }
          if modified.empty?
            Chef::Log.debug("Skipping update of #{new_resource.to_s}: has not changed any of the specified properties #{specified_properties.map { |p| "#{p}=#{new_resource.send(p).inspect}" }.join(", ")}.")
            return false
          end

          # Print the pretty green text and run the block
          property_size = modified.map { |p| p.size }.max
          modified = modified.map { |p| "  set #{p.to_s.ljust(property_size)} to #{new_resource.send(p).inspect} (was #{current_resource.send(p).inspect})" }
          converge_by([ "update #{new_resource.to_s}" ] + modified, &converge_block)

        else
          # The resource doesn't exist. Mark that we are *creating* this, and
          # write down any properties we are setting.
          created = []
          properties.each do |property|
            if new_resource.property_is_set?(property)
              created << "      set #{property.to_s.ljust(property_size)} to #{new_resource.send(property).inspect}"
            else
              created << "  default #{property.to_s.ljust(property_size)} to #{new_resource.send(property).inspect}"
            end
          end

          converge_by([ "create #{new_resource.to_s}" ] + created, &converge_block)
        end
        true
      end

      def self.included(other)
        other.extend(ClassMethods)
        other.use_inline_resources
        other.include_resource_dsl true
      end

      module ClassMethods
      end
    end
  end
end
