#
# Author:: Jay Mundrawala (<jdm@getchef.com>)
#
# Copyright:: 2014, Chef Software, Inc.
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

require 'chef/event_loggers/base'
require 'chef/platform/query_helpers'

if Chef::Platform::windows? and not Chef::Platform::windows_server_2003?
  if defined? Windows::Constants
    [:INFINITE, :WAIT_FAILED, :FORMAT_MESSAGE_IGNORE_INSERTS, :ERROR_INSUFFICIENT_BUFFER].each do |c|
      # These are redefined in 'win32/eventlog'
      Windows::Constants.send(:remove_const, c) if Windows::Constants.const_defined? c
    end
  end

  require 'win32/eventlog'
end

class Chef
  module EventLoggers
    class WindowsEventLogger < EventLoggers::Base
      short_name(:win_evt)

      # These must match those that are defined in the manifest file
      RUN_START_EVENT_ID = 10000
      RUN_STARTED_EVENT_ID = 10001
      RUN_COMPLETED_EVENT_ID = 10002
      RUN_FAILED_EVENT_ID = 10003

      EVENT_CATEGORY_ID = 11000
      LOG_CATEGORY_ID = 11001

      # Since we must install the event logger, this is not really configurable
      SOURCE = 'Chef'

      def self.available?
        return Chef::Platform::windows?
      end

      def initialize
        @eventlog = ::Win32::EventLog::open('Application')
      end

      def run_start(version)
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::INFO_TYPE,
          :source => SOURCE,
          :event_id => RUN_START_EVENT_ID,
          :data => [version]
        )
      end

      def run_started(run_status)
        @run_status = run_status
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::INFO_TYPE,
          :source => SOURCE,
          :event_id => RUN_STARTED_EVENT_ID,
          :data => [run_status.run_id]
        )
      end

      def run_completed(node)
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::INFO_TYPE,
          :source => SOURCE,
          :event_id => RUN_COMPLETED_EVENT_ID,
          :data => [@run_status.run_id, @run_status.elapsed_time.to_s]
        )
      end

      #Failed chef-client run %1 in %2 seconds.
      #Exception type: %3
      #Exception message: %4
      #Exception backtrace: %5
      def run_failed(e)
        data =
          if @run_status
            [@run_status.run_id,
             @run_status.elapsed_time.to_s]
          else
            ["UNKNOWN", "UNKNOWN"]
          end

        @eventlog.report_event(
          :event_type => ::Win32::EventLog::ERROR_TYPE,
          :source => SOURCE,
          :event_id => RUN_FAILED_EVENT_ID,
          :data => data + [e.class.name,
                           e.message,
                           e.backtrace.join("\n")]
        )
      end

    end
  end
end
