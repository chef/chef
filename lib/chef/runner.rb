#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
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

require_relative "exceptions"
require_relative "mixin/params_validate"
require_relative "node"
require_relative "resource_collection"

class Chef
  # == Chef::Runner
  # This class is responsible for executing the steps in a Chef run.
  class Runner

    attr_reader :run_context

    include Chef::Mixin::ParamsValidate

    def initialize(run_context)
      @run_context = run_context
      @run_context.runner = self
    end

    def delayed_actions
      @run_context.delayed_actions
    end

    def events
      @run_context.events
    end

    def updated_resources
      @run_context.updated_resources
    end

    # Determine the appropriate provider for the given resource, then
    # execute it.
    def run_action(resource, action, notification_type = nil, notifying_resource = nil)
      # If there are any before notifications, why-run the resource
      # and notify anyone who needs notifying
      before_notifications = run_context.before_notifications(resource) || []
      unless before_notifications.empty?
        forced_why_run do
          Chef::Log.info("#{resource} running why-run #{action} action to support before action")
          resource.run_action(action, notification_type, notifying_resource)
        end

        if resource.updated_by_last_action?
          before_notifications.each do |notification|
            Chef::Log.info("#{resource} sending #{notification.action} action to #{notification.resource} (before)")
            run_action(notification.resource, notification.action, :before, resource)
          end
          resource.updated_by_last_action(false)
        end
      end

      # Run the action on the resource.
      resource.run_action(action, notification_type, notifying_resource)

      # Execute any immediate and queue up any delayed notifications
      # associated with the resource, but only if it was updated *this time*
      # we ran an action on it.
      if resource.updated_by_last_action?
        updated_resources.add(resource.declared_key) # track updated resources for unified_mode
        run_context.immediate_notifications(resource).each do |notification|
          if notification.resource.is_a?(String) && run_context.unified_mode
            Chef::Log.debug("immediate notification from #{resource} to #{notification.resource} is delayed until declaration due to unified_mode")
          else
            Chef::Log.info("#{resource} sending #{notification.action} action to #{notification.resource} (immediate)")
            run_action(notification.resource, notification.action, :immediate, resource)
          end
        end

        run_context.delayed_notifications(resource).each do |notification|
          if notification.resource.is_a?(String)
            # for string resources that have not be declared yet in unified mode we only support notifying the current run_context
            run_context.add_delayed_action(notification)
          else
            # send the notification to the run_context of the receiving resource
            notification.resource.run_context.add_delayed_action(notification)
          end
        end
      end
    end

    # Runs all of the actions on a given resource.  This fires notifications and marks
    # the resource as having been executed by the runner.
    #
    # @param resource [Chef::Resource] the resource to run
    #
    def run_all_actions(resource)
      Array(resource.action).each { |action| run_action(resource, action) }
      if run_context.unified_mode
        run_context.reverse_immediate_notifications(resource).each do |n|
          if updated_resources.include?(n.notifying_resource.declared_key)
            n.resolve_resource_reference(run_context.resource_collection)
            Chef::Log.info("#{resource} sent #{n.action} action to #{n.resource} (immediate at declaration time)")
            run_action(n.resource, n.action, :immediate, n.notifying_resource)
          end
        end
      end
    ensure
      resource.executed_by_runner = true
    end

    # Iterates over the resource_collection in the run_context calling
    # run_action for each resource in turn.
    #
    def converge
      # Resolve all lazy/forward references in notifications
      run_context.resource_collection.each(&:resolve_notification_references)

      # Execute each resource.
      run_context.resource_collection.execute_each_resource do |resource|
        unless run_context.resource_collection.unified_mode
          run_all_actions(resource)
        end
      end

      if run_context.resource_collection.unified_mode
        run_context.resource_collection.each { |r| r.resolve_notification_references(true) }
      end

    rescue Exception => e
      Chef::Log.info "Running queued delayed notifications before re-raising exception"
      run_delayed_notifications(e)
    else
      run_delayed_notifications(nil)
      true
    end

    private

    # Run all our :delayed actions
    def run_delayed_notifications(error = nil)
      collected_failures = Exceptions::MultipleFailures.new
      collected_failures.client_run_failure(error) unless error.nil?
      delayed_actions.each do |notification|
        result = run_delayed_notification(notification)
        if result.is_a?(Exception)
          collected_failures.notification_failure(result)
        end
      end
      collected_failures.raise!
    end

    def run_delayed_notification(notification)
      Chef::Log.info( "#{notification.notifying_resource} sending #{notification.action}"\
                      " action to #{notification.resource} (delayed)")
      # notifications may have lazy strings in them to resolve
      notification.resolve_resource_reference(run_context.resource_collection)
      run_action(notification.resource, notification.action, :delayed)
      true
    rescue Exception => e
      e
    end

    # helper to run a block of code with why_run forced to true and then restore it correctly
    def forced_why_run
      saved = Chef::Config[:why_run]
      Chef::Config[:why_run] = true
      yield
    ensure
      Chef::Config[:why_run] = saved
    end

  end
end
