#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require 'logger'

class Chef
  class Log
  
    @logger = nil
    
    class << self
      attr_accessor :logger #:nodoc
      
      # Use Chef::Logger.init when you want to set up the logger manually.  Arguments to this method
      # get passed directly to Logger.new, so check out the documentation for the standard Logger class
      # to understand what to do here.
      #
      # If this method is called with no arguments, it will log to STDOUT at the :info level.
      #
      # It also configures the Logger instance it creates to use the custom Chef::Log::Formatter class.
      def init(*opts)
        if opts.length == 0
          @logger = Logger.new(STDOUT)
        else
          @logger = Logger.new(*opts)
        end
        @logger.formatter = Chef::Log::Formatter.new()
        level(Chef::Config.log_level)
      end
      
      # Sets the level for the Logger object by symbol.  Valid arguments are:
      #
      #  :debug
      #  :info
      #  :warn
      #  :error
      #  :fatal
      #
      # Throws an ArgumentError if you feed it a bogus log level.
      def level(loglevel)
        init() unless @logger
        case loglevel
        when :debug
          @logger.level = Logger::DEBUG
        when :info
          @logger.level = Logger::INFO
        when :warn
          @logger.level = Logger::WARN
        when :error
          @logger.level = Logger::ERROR
        when :fatal
          @logger.level = Logger::FATAL
        else
          raise ArgumentError, "Log level must be one of :debug, :info, :warn, :error, or :fatal"
        end
      end
      
      # Passes any other method calls on directly to the underlying Logger object created with init. If
      # this method gets hit before a call to Chef::Logger.init has been made, it will call 
      # Chef::Logger.init() with no arguments.
      def method_missing(method_symbol, *args)
        init() unless @logger
        if args.length > 0
          @logger.send(method_symbol, *args)
        else
          @logger.send(method_symbol)
        end
      end
      
    end # class << self
  end
end