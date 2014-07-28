require 'chef/logging/event_log'
require 'win32/eventlog'
include Win32

class Chef
  module Logging
    class WindowsEventLogger < Logging::EventLogger
      # These must match those that are defined in the manifest file
      RUN_START_EVENT_ID = 10000
      RUN_STARTED_EVENT_ID = 10001
      RUN_COMPLETED_EVENT_ID = 10002
      RUN_FAILED_EVENT_ID = 10003

      EVENT_CATEGORY_ID = 11000
      LOG_CATEGORY_ID = 11001

      # Since we must install the event logger, this is not really configurable
      SOURCE = 'RubyMsg'

      def initialize
        @eventlog = EventLog::open('EventWriter')
      end

      def run_start(version)
        @eventlog.report_event(
          :event_type => EventLog::INFO_TYPE, 
          :source => SOURCE,
          :event_id => RUN_START_EVENT_ID,
          :data => [version]
        )
      end

      def run_started(run_status)
        @run_status = run_status
        @eventlog.report_event(
          :event_type => EventLog::INFO_TYPE, 
          :source => SOURCE,
          :event_id => RUN_STARTED_EVENT_ID,
          :data => [run_status.run_id]
        )
      end

      def run_completed(node)
        @eventlog.report_event(
          :event_type => EventLog::INFO_TYPE, 
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
        @eventlog.report_event(
          :event_type => EventLog::ERROR_TYPE, 
          :source => SOURCE, 
          :event_id => RUN_FAILED_EVENT_ID,
          :data => [@run_status.run_id, 
                    @run_status.elapsed_time.to_s, 
                    e.class.name, 
                    e.message, 
                    e.backtrace.join("\n")]
        )
      end

    end
  end
end
