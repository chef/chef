#--
# Author:: Adam Jacob (<adam@chef.io>)
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
require_relative "client"
require "forwardable" unless defined?(Forwardable)

class Chef
  # The base class for an Exception or Notification Handler. Create your own
  # handler by subclassing Chef::Handler. When a Chef run fails with an
  # uncaught Exception, Chef will set the +run_status+ on your handler and call
  # +report+
  #
  # @example
  #   require 'net/smtp'
  #
  #   module MyOrg
  #     class OhNoes < Chef::Handler
  #
  #       def report
  #         # Create the email message
  #         message  = "From: Your Name <your@mail.address>\n"
  #         message << "To: Destination Address <someone@example.com>\n"
  #         message << "Subject: Chef Run Failure\n"
  #         message << "Date: #{Time.now.rfc2822}\n\n"
  #
  #         # The Node is available as +node+
  #         message << "Chef run failed on #{node.name}\n"
  #         # +run_status+ is a value object with all of the run status data
  #         message << "#{run_status.formatted_exception}\n"
  #         # Join the backtrace lines. Coerce to an array just in case.
  #         message << Array(backtrace).join("\n")
  #
  #         # Send the email
  #         Net::SMTP.start('your.smtp.server', 25) do |smtp|
  #           smtp.send_message message, 'from@address', 'to@address'
  #         end
  #       end
  #
  #     end
  #   end
  #
  class Handler

    # FIXME: Chef::Handler should probably inherit from EventDispatch::Base
    # and should wire up to those events rather than the "notifications" system
    # which is hanging off of Chef::Client.  Those "notifications" could then be
    # deprecated in favor of events, and this class could become decoupled from
    # the Chef::Client object.

    def self.handler_for(*args)
      if args.include?(:start)
        Chef::Config[:start_handlers] ||= []
        Chef::Config[:start_handlers] |= [self]
      end
      if args.include?(:report)
        Chef::Config[:report_handlers] ||= []
        Chef::Config[:report_handlers] |= [self]
      end
      if args.include?(:exception)
        Chef::Config[:exception_handlers] ||= []
        Chef::Config[:exception_handlers] |= [self]
      end
    end

    # The list of currently configured start handlers
    def self.start_handlers
      Array(Chef::Config[:start_handlers])
    end

    def self.resolve_handler_instance(handler)
      if handler.is_a?(Class)
        if handler.respond_to?(:instance)
          # support retrieving a Singleton reporting object
          handler.instance
        else
          # just a class with no way to insert data
          handler.new
        end
      else
        # the Chef::Config array contains an instance, not a class
        handler
      end
    end

    # Run the start handlers. This will usually be called by a notification
    # from Chef::Client
    def self.run_start_handlers(run_status)
      Chef::Log.info("Running start handlers")
      start_handlers.each do |handler|
        handler = resolve_handler_instance(handler)
        handler.run_report_safely(run_status)
      end
      Chef::Log.info("Start handlers complete.")
    end

    # Wire up a notification to run the start handlers when the chef run
    # starts.
    Chef::Client.when_run_starts do |run_status|
      run_start_handlers(run_status)
    end

    # The list of currently configured report handlers
    def self.report_handlers
      Array(Chef::Config[:report_handlers])
    end

    # Run the report handlers. This will usually be called by a notification
    # from Chef::Client
    def self.run_report_handlers(run_status)
      events = run_status.events
      events.handlers_start(report_handlers.size)
      Chef::Log.info("Running report handlers")
      report_handlers.each do |handler|
        handler = resolve_handler_instance(handler)
        handler.run_report_safely(run_status)
        events.handler_executed(handler)
      end
      events.handlers_completed
      Chef::Log.info("Report handlers complete")
    end

    # Wire up a notification to run the report handlers if the chef run
    # succeeds.
    Chef::Client.when_run_completes_successfully do |run_status|
      run_report_handlers(run_status)
    end

    # The list of currently configured exception handlers
    def self.exception_handlers
      Array(Chef::Config[:exception_handlers])
    end

    # Run the exception handlers. Usually will be called by a notification
    # from Chef::Client when the run fails.
    def self.run_exception_handlers(run_status)
      events = run_status.events
      events.handlers_start(exception_handlers.size)
      Chef::Log.error("Running exception handlers")
      exception_handlers.each do |handler|
        handler = resolve_handler_instance(handler)
        handler.run_report_safely(run_status)
        events.handler_executed(handler)
      end
      events.handlers_completed
      Chef::Log.error("Exception handlers complete")
    end

    # Wire up a notification to run the exception handlers if the chef run fails.
    Chef::Client.when_run_fails do |run_status|
      run_exception_handlers(run_status)
    end

    extend Forwardable

    # The Chef::RunStatus object containing data about the Chef run.
    attr_reader :run_status

    ##
    # :method: start_time
    #
    # The time the chef run started
    def_delegator :@run_status, :start_time

    ##
    # :method: end_time
    #
    # The time the chef run ended
    def_delegator :@run_status, :end_time

    ##
    # :method: elapsed_time
    #
    # The time elapsed between the start and finish of the chef run
    def_delegator :@run_status, :elapsed_time

    ##
    # :method: run_context
    #
    # The Chef::RunContext object used by the chef run
    def_delegator :@run_status, :run_context

    ##
    # :method: exception
    #
    # The uncaught Exception that terminated the chef run, or nil if the run
    # completed successfully
    def_delegator :@run_status, :exception

    ##
    # :method: backtrace
    #
    # The backtrace captured by the uncaught exception that terminated the chef
    # run, or nil if the run completed successfully
    def_delegator :@run_status, :backtrace

    ##
    # :method: node
    #
    # The Chef::Node for this client run
    def_delegator :@run_status, :node

    # @return Array<Chef::Resource> all resources other than unprocessed
    #
    def all_resources
      @all_resources ||= action_collection&.filtered_collection(unprocessed: false)&.resources || []
    end

    # @return Array<Chef::Resource> all updated resources
    #
    def updated_resources
      @updated_resources ||= action_collection&.filtered_collection(up_to_date: false, skipped: false, failed: false, unprocessed: false)&.resources || []
    end

    # @return Array<Chef::Resource> all up_to_date resources
    #
    def up_to_date_resources
      @up_to_date_resources ||= action_collection&.filtered_collection(updated: false, skipped: false, failed: false, unprocessed: false)&.resources || []
    end

    # @return Array<Chef::Resource> all failed resources
    #
    def failed_resources
      @failed_resources ||= action_collection&.filtered_collection(updated: false, up_to_date: false, skipped: false, unprocessed: false)&.resources || []
    end

    # @return Array<Chef::Resource> all skipped resources
    #
    def skipped_resources
      @skipped_resources ||= action_collection&.filtered_collection(updated: false, up_to_date: false, failed: false, unprocessed: false)&.resources || []
    end

    # Unprocessed resources are those which are left over in the outer recipe context when a run fails.
    # Sub-resources of unprocessed resourced are impossible to capture because they would require processing
    # the outer resource.
    #
    # @return Array<Chef::Resource> all unprocessed resources
    #
    def unprocessed_resources
      @unprocessed_resources ||= action_collection&.filtered_collection(updated: false, up_to_date: false, failed: false, skipped: false)&.resources || []
    end

    ##
    # :method: success?
    #
    # Was the chef run successful? True if the chef run did not raise an
    # uncaught exception
    def_delegator :@run_status, :success?

    ##
    # :method: failed?
    #
    # Did the chef run fail? True if the chef run raised an uncaught exception
    def_delegator :@run_status, :failed?

    def action_collection
      @run_status.run_context.action_collection
    end

    # The main entry point for report handling. Subclasses should override this
    # method with their own report handling logic.
    def report; end

    # Runs the report handler, rescuing and logging any errors it may cause.
    # This ensures that all handlers get a chance to run even if one fails.
    # This method should not be overridden by subclasses unless you know what
    # you're doing.
    #
    # @api private
    def run_report_safely(run_status)
      run_report_unsafe(run_status)
    rescue Exception => e
      Chef::Log.error("Report handler #{self.class.name} raised #{e.inspect}")
      Array(e.backtrace).each { |line| Chef::Log.error(line) }
    ensure
      @run_status = nil
    end

    # Runs the report handler without any error handling. This method should
    # not be used directly except in testing.
    def run_report_unsafe(run_status)
      @run_status = run_status
      report
    end

    # Return the Hash representation of the run_status
    def data
      @run_status.to_h
    end

  end
end
