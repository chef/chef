#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<@aj@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'mixlib/log'

class Chef
  class Log
    extend Mixlib::Log
    
    class << self
      attr_reader :verbose_logger

      @verbose_logger = nil
      @verbose = false
      
      def verbose?
        @verbose
      end

      alias :verbose :verbose?

      def verbose=(value)
        if value
          @verbose = true
          @verbose_logger ||= Logger.new(STDOUT)
          @verbose_logger.level = self.logger.level
          @verbose_logger.formatter = self.logger.formatter
        else
          @verbose, @verbose_logger = false, nil
        end
        self.verbose
      end

      [:debug, :info, :warn, :error, :fatal].each do |method_name|
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{method_name}(msg=nil, &block)
            @logger.#{method_name}(msg, &block)
            @verbose_logger.#{method_name}(msg, &block) if verbose?
          end
        METHOD_DEFN
      end

      [:debug?, :info?, :warn?, :error?, :fatal?].each do |method_name|
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{method_name}
            @logger.#{method_name}
          end
        METHOD_DEFN
      end

      def <<(msg)
        @logger << msg
      end

      def add(severity, message = nil, progname = nil, &block)
        @logger.add(severity, message = nil, progname = nil, &block)
      end

      def init(*opts)
        STDOUT.sync = true if opts.empty?
        opts.first.sync = true if !opts.empty? && opts.first.respond_to?(:sync=)
        super(*opts)
      end
    end

    # NOTE: Mixlib::Log initially sets @logger to nil and depends on
    # #init being called to initialize the logger. We don't want to
    # incur extra method call overhead for every log message so we're
    # accessing the logger by instance variable, which means we need to
    # make Mixlib::Log initialize it.
    init

    class Formatter
      def self.show_time=(*args)
        Mixlib::Log::Formatter.show_time = *args
      end
    end
    
  end
end

