#
# Chef::Logger
#
# A simple wrapper for the standard Ruby Logger.  
#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'logger'

class Chef
  class Log
  
    @logger = nil
    
    class << self
      attr_reader :logger #:nodoc
      
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