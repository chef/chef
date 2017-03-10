#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

require "chef/guard_interpreter"

class Chef
  class GuardInterpreter
    class ResourceGuardInterpreter < DefaultGuardInterpreter

      def initialize(parent_resource, command, opts)
        super(command, opts)
        @parent_resource = parent_resource
        @resource = get_interpreter_resource(parent_resource)
      end

      def evaluate
        # Add attributes inherited from the parent class
        # to the resource
        merge_inherited_attributes

        # Only execute and script resources and use guard attributes.
        # The command to be executed on them are passed via different attributes.
        # Script resources use code attribute and execute resources use
        # command attribute. Moreover script resources are also execute
        # resources. Here we make sure @command is assigned to the right
        # attribute by checking the type of the resources.
        # We need to make sure we check for Script first because any resource
        # that can get to here is an Execute resource.
        if @resource.is_a? Chef::Resource::Script
          block_attributes = @command_opts.merge({ :code => @command })
        else
          block_attributes = @command_opts.merge({ :command => @command })
        end

        # Handles cases like powershell_script where default
        # attributes are different when used in a guard vs. not. For
        # powershell_script in particular, this will go away when
        # the one attribue that causes this changes its default to be
        # the same after some period to prepare for deprecation
        if @resource.class.respond_to?(:get_default_attributes)
          block_attributes = @resource.class.send(:get_default_attributes, @command_opts).merge(block_attributes)
        end

        resource_block = block_from_attributes(block_attributes)
        evaluate_action(nil, &resource_block)
      end

      protected

      def evaluate_action(action = nil, &block)
        @resource.instance_eval(&block)

        run_action = action || @resource.action

        begin
          # Coerce to an array to be safe. This could happen with a legacy
          # resource or something overriding the default_action code in a
          # subclass.
          Array(run_action).each { |action_to_run| @resource.run_action(action_to_run) }
          resource_updated = @resource.updated
        rescue Mixlib::ShellOut::ShellCommandFailed
          resource_updated = nil
        end

        resource_updated
      end

      def get_interpreter_resource(parent_resource)
        if parent_resource.nil? || parent_resource.node.nil?
          raise ArgumentError, "Node for guard resource parent must not be nil"
        end

        resource_class = Chef::Resource.resource_for_node(parent_resource.guard_interpreter, parent_resource.node)

        if resource_class.nil?
          raise ArgumentError, "Specified guard_interpreter resource #{parent_resource.guard_interpreter} unknown for this platform"
        end

        if ! resource_class.ancestors.include?(Chef::Resource::Execute)
          raise ArgumentError, "Specified guard interpreter class #{resource_class} must be a kind of Chef::Resource::Execute resource"
        end

        # Duplicate the node below because the new RunContext
        # overwrites the state of Node instances passed to it.
        # See https://github.com/chef/chef/issues/3485.
        empty_events = Chef::EventDispatch::Dispatcher.new
        anonymous_run_context = Chef::RunContext.new(parent_resource.node.dup, {}, empty_events)
        interpreter_resource = resource_class.new("Guard resource", anonymous_run_context)
        interpreter_resource.is_guard_interpreter = true

        interpreter_resource
      end

      def block_from_attributes(attributes)
        Proc.new do
          attributes.keys.each do |attribute_name|
            send(attribute_name, attributes[attribute_name]) if respond_to?(attribute_name)
          end
        end
      end

      def merge_inherited_attributes
        inherited_attributes = []

        if @parent_resource.class.respond_to?(:guard_inherited_attributes)
          inherited_attributes = @parent_resource.class.send(:guard_inherited_attributes)
        end

        if inherited_attributes && !inherited_attributes.empty?
          inherited_attributes.each do |attribute|
            if @parent_resource.respond_to?(attribute) && @resource.respond_to?(attribute)
              parent_value = @parent_resource.send(attribute)
              child_value = @resource.send(attribute)
              if parent_value || child_value
                @resource.send(attribute, parent_value)
              end
            end
          end
        end
      end
    end
  end
end
