#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'logger'

module Chef
  module Expander

    class InvalidLogDevice < ArgumentError
    end

    class InvalidLogLevel < ArgumentError
    end

    # Customized Logger class that dispenses with the unnecessary mutexing.
    # As long as you write one line at a time, the OS will take care of keeping
    # your output in order. Expander commonly runs as a cluster of worker
    # processes so the mutexing wasn't actually helping us anyway.
    #
    # We don't use the program name field in the logger, so support for that
    # has been removed. The log format is also hardcoded since we don't ever
    # change the format.
    class Logger < ::Logger

      LEVELS = { :debug=>DEBUG, :info=>INFO, :warn=>WARN, :error=>ERROR, :fatal=>FATAL}
      LEVEL_INTEGERS = LEVELS.invert
      LEVEL_TO_STR = Hash[LEVEL_INTEGERS.map {|i,sym| [i,sym.to_s.upcase]}]

      LOG_DEVICES = []

      at_exit do
        LOG_DEVICES.each {|io| io.close if io.respond_to?(:closed?) && !io.closed?}
      end

      attr_reader :log_device

      # (re-)initialize the Logger with a new IO object or file to log to.
      def init(log_device)
        @log_device = initialize_log_device(log_device)
      end

      def initialize(log_device)
        @level = DEBUG
        init(log_device)
      end

      def level=(new_level)
        @level =  if new_level.kind_of?(Fixnum) && LEVEL_INTEGERS.key?(new_level)
          new
        elsif LEVELS.key?(new_level)
          LEVELS[new_level]
        else
          raise InvalidLogLevel, "#{new_level} is not a valid log level. Valid log levels are [#{LEVEL_INTEGERS.keys.join(',')}] and [#{LEVELS.join(',')}]"
        end
      end

      def <<(msg)
        @log_device.print(msg)
      end

      def add(severity=UNKNOWN, message = nil, progname = nil, &block)
        return true unless severity >= @level

        message ||= progname # level methods (e.g, #debug) pass explicit message as progname

        if message.nil? && block_given?
          message = yield
        end

        self << sprintf("[%s] %s: %s\n", Time.new.rfc2822(), LEVEL_TO_STR[severity], msg2str(message))
        true
      end

      alias :log :add

      private

      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" <<
            (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end

      def logging_at_severity?(severity=nil)
      end

      def initialize_log_device(dev)
        unless dev.respond_to? :sync=
          assert_valid_path!(dev)
          dev = File.open(dev.to_str, "a")
          LOG_DEVICES << dev
        end

        dev.sync = true
        dev
      end

      def assert_valid_path!(path)
        enclosing_directory = File.dirname(path)
        unless File.directory?(enclosing_directory)
          raise InvalidLogDevice, "You must create the enclosing directory #{enclosing_directory} before the log file #{path} can be created."
        end
        if File.exist?(path)
          unless File.writable?(path)
            raise InvalidLogDevice, "The log file you specified (#{path}) is not writable by user #{Process.euid}"
          end
        elsif !File.writable?(enclosing_directory)
          raise InvalidLogDevice, "You specified a log file #{path} but user #{Process.euid} is not permitted to create files there."
        end
      end

    end
  end
end