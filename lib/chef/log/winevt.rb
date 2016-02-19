#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/event_loggers/base"
require "chef/platform/query_helpers"
require "chef/mixin/unformatter"

class Chef
  class Log
    #
    # Chef::Log::WinEvt class.
    # usage in client.rb:
    #  log_location Chef::Log::WinEvt.new
    #
    class WinEvt
      # These must match those that are defined in the manifest file
      INFO_EVENT_ID = 10100
      WARN_EVENT_ID = 10101
      DEBUG_EVENT_ID = 10102
      ERROR_EVENT_ID = 10103
      FATAL_EVENT_ID = 10104

      # Since we must install the event logger, this is not really configurable
      SOURCE = "Chef"

      include Chef::Mixin::Unformatter

      attr_accessor :sync, :formatter, :level

      def initialize(eventlog = nil)
        @eventlog = eventlog || ::Win32::EventLog.open("Application")
      end

      def close
      end

      def info(msg)
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::INFO_TYPE,
          :source => SOURCE,
          :event_id => INFO_EVENT_ID,
          :data => [msg]
        )
      end

      def warn(msg)
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::WARN_TYPE,
          :source => SOURCE,
          :event_id => WARN_EVENT_ID,
          :data => [msg]
        )
      end

      def debug(msg)
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::INFO_TYPE,
          :source => SOURCE,
          :event_id => DEBUG_EVENT_ID,
          :data => [msg]
        )
      end

      def error(msg)
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::ERROR_TYPE,
          :source => SOURCE,
          :event_id => ERROR_EVENT_ID,
          :data => [msg]
        )
      end

      def fatal(msg)
        @eventlog.report_event(
          :event_type => ::Win32::EventLog::ERROR_TYPE,
          :source => SOURCE,
          :event_id => FATAL_EVENT_ID,
          :data => [msg]
        )
      end

    end
  end
end
