#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "event_dispatch/base"

class Chef
  class ActionCollection < EventDispatch::Base
    include Enumerable
    extend Forwardable

    class ActionRecord

      # @return [Chef::Resource] The declared resource state.
      #
      attr_accessor :new_resource

      # @return [Chef::Resource] The current_resource object (before-state).  This can be nil
      # for non-why-run-safe resources in why-run mode, or if load_current_resource itself
      # threw an exception (which should be considered a bug in that load_current_resource
      # implementation, but must be handled), or for unprocessed resources.
      attr_accessor :current_resource

      # @return [Chef::Resource] the after_resource object (after-state).  This can be nil for
      # non custom-resources or resources that do not implement load_after_resource.
      attr_accessor :after_resource

      # @return [Symbol] # The action that was run (or scheduled to run in the case of "unprocessed" resources).
      attr_accessor :action

      # @return [Exception] The exception that was thrown
      attr_accessor :exception

      # @return [Hash] JSON-formatted error description from the Chef::Formatters::ErrorMapper
      attr_accessor :error_description

      # @return [Numeric] The elapsed time in seconds with machine precision
      attr_accessor :elapsed_time

      # @return [Chef::Resource::Conditional] The conditional that caused the resource to be skipped
      attr_accessor :conditional

      # The status of the resource:
      #   - updated:     ran and converged
      #   - up_to_date:  skipped due to idempotency
      #   - skipped:     skipped due to a conditional
      #   - failed:      failed with an exception
      #   - unprocessed: resources that were not touched by a run that failed
      #
      # @return [Symbol] status
      #
      attr_accessor :status

      # The "nesting" level.  Outer resources in recipe context are 0 here, while for every
      # sub-resource_collection inside of a custom resource this number is incremented by 1.
      # Resources that are fired via build-resource or manually creating and firing
      #
      # @return [Integer]
      #
      attr_accessor :nesting_level

      def initialize(new_resource, action, nesting_level)
        @new_resource = new_resource
        @action = action
        @nesting_level = nesting_level
      end

      # @return [Boolean] true if there was no exception
      def success?
        !exception
      end
    end

    attr_reader :action_records
    attr_reader :pending_updates
    attr_reader :run_context
    attr_reader :events

    def initialize(events, run_context = nil, action_records = [])
      @action_records  = action_records
      @pending_updates = []
      @events          = events
      @run_context     = run_context
    end

    def_delegators :@action_records, :each, :last

    # Allows getting at the action_records collection filtered by nesting level and status.
    #
    # TODO: filtering by resource type+name
    #
    # @return [Chef::ActionCollection]
    #
    def filtered_collection(max_nesting: nil, up_to_date: true, skipped: true, updated: true, failed: true, unprocessed: true)
      subrecords = action_records.select do |rec|
        ( max_nesting.nil? || rec.nesting_level <= max_nesting ) &&
          ( rec.status == :up_to_date && up_to_date ||
            rec.status == :skipped && skipped ||
            rec.status == :updated && updated ||
            rec.status == :failed && failed ||
            rec.status == :unprocessed && unprocessed )
      end
      self.class.new(events, run_context, subrecords)
    end

    def resources
      action_records.map(&:new_resource)
    end

    # This hook gives us the run_context immediately after it is created so that we can wire up this object to it.
    #
    # (see EventDispatch::Base#)
    #
    def cookbook_compilation_start(run_context)
      run_context.action_collection = self
      # this hook is now poorly named since it is just a callback that lets other consumers snag a reference to the action_collection
      run_context.events.enqueue(:action_collection_registration, self)
      @run_context = run_context
    end

    # Consumers must call register -- either directly or through the action_collection_registration hook.  If
    # nobody has registered any interest, then no action tracking will be done.
    #
    # @params object [Object] callers should call with `self`
    #
    def register(object)
      Chef::Log.warn "the action collection no longer requires registration at #{caller[0]}"
    end

    # End of an unsuccessful converge used to fire off detect_unprocessed_resources.
    #
    # (see EventDispatch::Base#)
    #
    def converge_failed(exception)
      detect_unprocessed_resources
    end

    # Hook to start processing a resource.  May be called within processing of an outer resource
    # so the pending_updates array forms a stack that sub-resources are popped onto and off of.
    # This is always called.
    #
    # (see EventDispatch::Base#)
    #
    def resource_action_start(new_resource, action, notification_type = nil, notifier = nil)
      pending_updates << ActionRecord.new(new_resource, action, pending_updates.length)
    end

    # Hook called after a current resource is loaded.  If load_current_resource fails, this hook will
    # not be called and current_resource will be nil, and the resource_failed hook will be called.
    #
    # (see EventDispatch::Base#)
    #
    def resource_current_state_loaded(new_resource, action, current_resource)
      current_record.current_resource = current_resource
    end

    # Hook called after an after resource is loaded.  If load_after_resource fails, this hook will
    # not be called and after_resource will be nil, and the resource_failed hook will be called.
    #
    # (see EventDispatch::Base#)
    #
    def resource_after_state_loaded(new_resource, action, after_resource)
      current_record.after_resource = after_resource
    end

    # Hook called after an action is determined to be up to date.
    #
    # (see EventDispatch::Base#)
    #
    def resource_up_to_date(new_resource, action)
      current_record.status = :up_to_date
    end

    # Hook called after an action is determined to be skipped due to a conditional.
    #
    # (see EventDispatch::Base#)
    #
    def resource_skipped(resource, action, conditional)
      current_record.status = :skipped
      current_record.conditional = conditional
    end

    # Hook called after an action modifies the system and is marked updated.
    #
    # (see EventDispatch::Base#)
    #
    def resource_updated(new_resource, action)
      current_record.status = :updated
    end

    # Hook called after an action fails.
    #
    # (see EventDispatch::Base#)
    #
    def resource_failed(new_resource, action, exception)
      current_record.status = :failed
      current_record.exception = exception
      current_record.error_description = Formatters::ErrorMapper.resource_failed(new_resource, action, exception).for_json
    end

    # Hook called after an action is completed.  This is always called, even if the action fails.
    #
    # (see EventDispatch::Base#)
    #
    def resource_completed(new_resource)
      current_record.elapsed_time = new_resource.elapsed_time

      # Verify if the resource has sensitive data and create a new blank resource with only
      # the name so we can report it back without sensitive data
      # XXX?: what about sensitive data in the current_resource?
      # FIXME: this needs to be display-logic
      if current_record.new_resource.sensitive
        klass = current_record.new_resource.class
        resource_name = current_record.new_resource.name
        current_record.new_resource = klass.new(resource_name)
      end

      action_records << pending_updates.pop
    end

    private

    # @return [Chef::ActionCollection::ActionRecord] the current record we are working on at the top of the stack
    def current_record
      pending_updates[-1]
    end

    # If the chef-client run fails in the middle, we are left with a half-completed resource_collection, this
    # method is responsible for adding all of the resources which have not yet been touched.  They are marked
    # as being "unprocessed".
    #
    def detect_unprocessed_resources
      run_context.resource_collection.all_resources.select { |resource| resource.executed_by_runner == false }.each do |resource|
        Array(resource.action).each do |action|
          record = ActionRecord.new(resource, action, 0)
          record.status = :unprocessed
          action_records << record
        end
      end
    end
  end
end
