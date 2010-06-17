#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'forwardable'

class Chef
  class Handler

    extend Forwardable

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

    ##
    # :method: all_resources
    #
    # An Array containing all resources in the chef run's resource_collection
    def_delegator :@run_status, :all_resources

    ##
    # :method: updated_resources
    #
    # An Array containing all resources that were updated during the chef run
    def_delegator :@run_status, :updated_resources

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

    # The main entry point for report handling. Subclasses should override this
    # method with their own report handling logic.
    def report
    end

    # Runs the report handler, rescuing and logging any errors it may cause.
    # This ensures that all handlers get a chance to run even if one fails.
    # This method should not be overridden by subclasses unless you know what
    # you're doing.
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
      @run_status.to_hash
    end

  end
end
