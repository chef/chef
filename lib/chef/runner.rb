#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/exceptions"
require "chef/mixin/params_validate"
require "chef/node"
require "chef/resource_collection"

class Chef
  # == Chef::Runner
  # This class is responsible for executing the steps in a Chef run.
  class Runner

    attr_reader :run_context

    include Chef::Mixin::ParamsValidate

    def initialize(run_context)
      @run_context = run_context
      run_context.runner = self
    end

    def delayed_actions
      @run_context.delayed_actions
    end

    def events
      @run_context.events
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

      # Actually run the action for realsies
      resource.run_action(action, notification_type, notifying_resource)

      # Execute any immediate and queue up any delayed notifications
      # associated with the resource, but only if it was updated *this time*
      # we ran an action on it.
      if resource.updated_by_last_action?
        run_context.immediate_notifications(resource).each do |notification|
          Chef::Log.info("#{resource} sending #{notification.action} action to #{notification.resource} (immediate)")
          run_action(notification.resource, notification.action, :immediate, resource)
        end

        run_context.delayed_notifications(resource).each do |notification|
          # send the notification to the run_context of the receiving resource
          notification.resource.run_context.add_delayed_action(notification)
        end
      end
    end

    # Iterates over the +resource_collection+ in the +run_context+ calling
    # +run_action+ for each resource in turn.
    def converge
      # Resolve all lazy/forward references in notifications
      run_context.resource_collection.each do |resource|
        resource.resolve_notification_references
      end

      # Execute each resource.
      run_context.resource_collection.execute_each_resource do |resource|
        Array(resource.action).each { |action| run_action(resource, action) }
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
        if result.kind_of?(Exception)
          collected_failures.notification_failure(result)
        end
      end
      collected_failures.raise!
    end

    def run_delayed_notification(notification)
      Chef::Log.info( "#{notification.notifying_resource} sending #{notification.action}"\
                      " action to #{notification.resource} (delayed)")
      # Struct of resource/action to call
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
