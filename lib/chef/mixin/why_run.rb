#
# Author:: Dan DeLeo ( <dan@chef.io> )
# Author:: Marc Paradise ( <marc@chef.io> )
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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
  module Mixin
    module WhyRun

      # ConvergeActions implements the logic for why run. A ConvergeActions
      # object wraps a collection of actions, which consist of a descriptive
      # string and a block/Proc. Actions are executed by calling #converge!
      # When why_run mode is enabled, each action's description will be
      # printed, but the block will not be called. Conversely, in normal mode,
      # the block is called, but the message is not printed.
      #
      # In general, this class should be accessed through the API provided by
      # Chef::Provider.
      class ConvergeActions
        attr_reader :actions

        def initialize(resource, run_context, action)
          @resource, @run_context = resource, run_context
          @actions = []
        end

        def events
          @run_context.events
        end

        # Adds an action to the list. +descriptions+ can either be an Array of
        # Strings, or a single String describing the action; +block+ is a
        # block/proc that implements the action.
        def add_action(descriptions, &block)
          @actions << [descriptions, block]
          if (@resource.respond_to?(:is_guard_interpreter) && @resource.is_guard_interpreter) || !Chef::Config[:why_run]
            yield
          end
          events.resource_update_applied(@resource, @action, descriptions)
        end

        # True if there are no actions to execute.
        def empty?
          @actions.empty?
        end
      end

      # ResourceRequirements provides a framework for making assertions about
      # the host system's state. It also provides a mechanism for making
      # assumptions about what the system's state might have been when running
      # in why run mode.
      #
      # For example, consider a recipe that consists of a package resource and
      # a service resource. If the service's init script is installed by the
      # package, and Chef is running in why run mode, then the service resource
      # would fail when attempting to run `/etc/init.d/software-name status`.
      # In order to provide a more useful approximation of what would happen in
      # a real chef run, we want to instead assume that the service was created
      # but isn't running. The logic would look like this:
      #
      #     # Hypothetical service provider demonstrating why run assumption logic.
      #     # This isn't the actual API, it just shows the logic.
      #     class HypotheticalServiceProvider < Chef::Provider
      #
      #       def load_current_resource
      #         # Make sure we have the init script available:
      #         if ::File.exist?("/etc/init.d/some-service"
      #           # If the init script exists, proceed as normal:
      #           status_cmd = shell_out("/etc/init.d/some-service status")
      #           if status_cmd.success?
      #             @current_resource.status(:running)
      #           else
      #             @current_resource.status(:stopped)
      #           end
      #         else
      #           if whyrun_mode?
      #             # If the init script is not available, and we're in why run mode,
      #             # assume that some previous action would've created it:
      #             log("warning: init script '/etc/init.d/some-service' is not available")
      #             log("warning: assuming that the init script would have been created, assuming the state of 'some-service' is 'stopped'")
      #             @current_resource.status(:stopped)
      #           else
      #             raise "expected init script /etc/init.d/some-service doesn't exist"
      #           end
      #         end
      #       end
      #
      #     end
      #
      # In short, the code above does the following:
      # * runs a test to determine if a requirement is met:
      #   `::File.exist?("/etc/init.d/some-service"`
      # * raises an error if the requirement is not met, and we're not in why
      #   run mode.
      # * if we *are* in why run mode, print a message explaining the
      #   situation, and run some code that makes an assumption about what the
      #   state of the system would be. In this case, we also skip the normal
      #   `load_current_resource` logic
      # * when the requirement *is* met, we run the normal `load_current_resource`
      #   logic
      #
      # ResourceRequirements encapsulates the above logic in a more declarative API.
      #
      # === Examples
      # Assertions and assumptions should be created through the WhyRun#assert
      # method, which gets mixed in to providers. See that method's
      # documentation for examples.
      class ResourceRequirements

        # Implements the logic for a single assertion/assumption. See the
        # documentation for ResourceRequirements for full discussion.
        class Assertion
          class AssertionFailure < RuntimeError
          end

          def initialize
            @block_action = false
            @assertion_proc = nil
            @failure_message = nil
            @whyrun_message = nil
            @resource_modifier = nil
            @assertion_failed = false
            @exception_type = AssertionFailure
          end

          # Defines the code block that determines if a requirement is met. The
          # block should return a truthy value to indicate that the requirement
          # is met, and a falsey value if the requirement is not met.
          #   # in a provider:
          #   assert(:some_action) do |a|
          #     # This provider requires the file /tmp/foo to exist:
          #     a.assertion { ::File.exist?("/tmp/foo") }
          #   end
          def assertion(&assertion_proc)
            @assertion_proc = assertion_proc
          end

          # Defines the failure message, and optionally the Exception class to
          # use when a requirement is not met. It works like `raise`:
          #   # in a provider:
          #   assert(:some_action) do |a|
          #     # This example shows usage with 1 or 2 args by calling #failure_message twice.
          #     # In practice you should only call this once per Assertion.
          #
          #     # Set the Exception class explicitly
          #     a.failure_message(Chef::Exceptions::MissingRequiredFile, "File /tmp/foo doesn't exist")
          #     # Fallback to the default error class (AssertionFailure)
          #     a.failure_message("File /tmp/foo" doesn't exist")
          #   end
          def failure_message(*args)
            case args.size
            when 1
              @failure_message = args[0]
            when 2
              @exception_type, @failure_message = args[0], args[1]
            else
              raise ArgumentError, "#{self.class}#failure_message takes 1 or 2 arguments, you gave #{args.inspect}"
            end
          end

          # Defines a message and optionally provides a code block to execute
          # when the requirement is not met and Chef is executing in why run
          # mode
          #
          # If no failure_message is provided (above), then execution
          # will be allowed to continue in both whyrun and non-whyrun
          # mode
          #
          # @example With a service resource that requires /etc/init.d/service-name to exist:
          #   # in a provider
          #   assert(:start, :restart) do |a|
          #     a.assertion { ::File.exist?("/etc/init.d/service-name") }
          #     a.whyrun("Init script '/etc/init.d/service-name' doesn't exist, assuming a prior action would have created it.") do
          #       # blindly assume that the service exists but is stopped in why run mode:
          #       @new_resource.status(:stopped)
          #     end
          #   end
          def whyrun(message, &resource_modifier)
            @whyrun_message = message
            @resource_modifier = resource_modifier
          end

          # Prevents associated actions from being invoked in whyrun mode.
          # This will also stop further processing of assertions for a given action.
          #
          # An example from the template provider: if the source template doesn't exist
          # we can't parse it in the action_create block of template - something that we do
          # even in whyrun mode.  Because the source template may have been created in an earlier
          # step, we still want to keep going in whyrun mode.
          #
          # assert(:create, :create_if_missing) do |a|
          #   a.assertion { File::exists?(@new_resource.source) }
          #   a.whyrun "Template source file does not exist, assuming it would have been created."
          #   a.block_action!
          # end
          #
          def block_action!
            @block_action = true
          end

          def block_action?
            @block_action
          end

          def assertion_failed?
            @assertion_failed
          end

          # Runs the assertion/assumption logic. Will raise an Exception of the
          # type specified in #failure_message (or AssertionFailure by default)
          # if the requirement is not met and Chef is not running in why run
          # mode. An exception will also be raised if running in why run mode
          # and no why run message or block has been declared.
          def run(action, events, resource)
            if !@assertion_proc || !@assertion_proc.call
              @assertion_failed = true
              if Chef::Config[:why_run] && @whyrun_message
                events.provider_requirement_failed(action, resource, @exception_type, @failure_message)
                events.whyrun_assumption(action, resource, @whyrun_message) if @whyrun_message
                @resource_modifier.call if @resource_modifier
              else
                if @failure_message
                  events.provider_requirement_failed(action, resource, @exception_type, @failure_message)
                  raise @exception_type, @failure_message
                end
              end
            end
          end
        end

        def initialize(resource, run_context)
          @resource, @run_context = resource, run_context
          @assertions = Hash.new { |h, k| h[k] = [] }
          @blocked_actions = []
        end

        def events
          @run_context.events
        end

        # Check to see if a given action is blocked by a failed assertion
        #
        # Takes the action name to be verified.
        def action_blocked?(action)
          @blocked_actions.include?(action)
        end

        # Define a new Assertion.
        #
        # Takes a list of action names for which the assertion should be made.
        #
        # @example A File provider that requires the parent directory to exist:
        #
        #   assert(:create, :create_if_missing) do |a|
        #     parent_dir = File.basename(@new_resource.path)
        #     a.assertion { ::File.directory?(parent_dir) }
        #     a.failure_message(Exceptions::ParentDirectoryDoesNotExist,
        #                       "Can't create file #{@new_resource.path}: parent directory #{parent_dir} doesn't exist")
        #     a.why_run("assuming parent directory #{parent_dir} would have been previously created"
        #   end
        #
        # @example A service provider that requires the init script to exist:
        #
        #   assert(:start, :restart) do |a|
        #     a.assertion { ::File.exist?(@new_resource.init_script) }
        #     a.failure_message(Exceptions::MissingInitScript,
        #                       "Can't check status of #{@new_resource}: init script #{@new_resource.init_script} is missing")
        #     a.why_run("Assuming init script would have been created and service is stopped") do
        #       @current_resource.status(:stopped)
        #     end
        #   end
        #
        # @example A File provider that will error out if you don't have permissions do delete the file, *even in why run mode*:
        #   assert(:delete) do |a|
        #     a.assertion { ::File.writable?(@new_resource.path) }
        #     a.failure_message(Exceptions::InsufficientPrivileges,
        #                       "You don't have sufficient privileges to delete #{@new_resource.path}")
        #   end
        #
        # @example A Template provider that will prevent action execution but continue the run in whyrun mode if the template source is not available.
        #   assert(:create, :create_if_missing) do |a|
        #     a.assertion { File::exist?(@new_resource.source) }
        #     a.failure_message Chef::Exceptions::TemplateError, "Template #{@new_resource.source} could not be found exist."
        #     a.whyrun "Template source #{@new_resource.source} does not exist. Assuming it would have been created."
        #     a.block_action!
        #   end
        #
        #   assert(:delete) do |a|
        #     a.assertion { ::File.writable?(@new_resource.path) }
        #     a.failure_message(Exceptions::InsufficientPrivileges,
        #                       "You don't have sufficient privileges to delete #{@new_resource.path}")
        #   end
        def assert(*actions)
          assertion = Assertion.new
          yield assertion
          actions.each { |action| @assertions[action] << assertion }
        end

        # Run the assertion and assumption logic.
        def run(action)
          @assertions[action.to_sym].each do |a|
            a.run(action, events, @resource)
            if a.assertion_failed? && a.block_action?
              @blocked_actions << action
              break
            end
          end
        end
      end
    end
  end
end
