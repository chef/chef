#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/event_dispatch/base"

class Chef
  module EventLoggers
    class UnknownEventLogger < StandardError; end
    class UnavailableEventLogger < StandardError; end

    def self.event_loggers_by_name
      @event_loggers_by_name ||= {}
    end

    def self.register(name, logger)
      event_loggers_by_name[name.to_s] = logger
    end

    def self.by_name(name)
      event_loggers_by_name[name]
    end

    def self.available_event_loggers
      event_loggers_by_name.select do |key, val|
        val.available?
      end.keys
    end

    def self.new(name)
      event_logger_class = by_name(name.to_s)
      raise UnknownEventLogger, "No event logger found for #{name} (available: #{available_event_loggers.join(', ')})" unless event_logger_class
      raise UnavailableEventLogger unless available_event_loggers.include? name.to_s
      event_logger_class.new
    end

    class Base < EventDispatch::Base
      def self.short_name(name)
        Chef::EventLoggers.register(name, self)
      end

      # Returns true if this implementation of EventLoggers can be used
      def self.available?
        false
      end
    end
  end
end
