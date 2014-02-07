#
# Author:: Tyler Cloke (<tyler@opscode.com>)
#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/event_dispatch/base'
require 'chef/formatters/error_inspectors'
require 'chef/formatters/error_descriptor'
require 'chef/formatters/error_mapper'

class Chef

  # == Chef::Formatters
  # Formatters handle printing output about the progress/status of a chef
  # client run to the user's screen.
  module Formatters

    class UnknownFormatter < StandardError; end

    def self.formatters_by_name
      @formatters_by_name ||= {}
    end

    def self.register(name, formatter)
      formatters_by_name[name.to_s] = formatter
    end

    def self.by_name(name)
      formatters_by_name[name]
    end

    def self.available_formatters
      formatters_by_name.keys
    end

    #--
    # TODO: is it too clever to be defining new() on a module like this?
    def self.new(name, out, err)
      formatter_class = by_name(name.to_s) or
        raise UnknownFormatter, "No output formatter found for #{name} (available: #{available_formatters.join(', ')})"

      formatter_class.new(out, err)
    end

    # == Outputter
    # Handles basic printing tasks like colorizing.
    # --
    # TODO: Duplicates functionality from knife, upfactor.
    class Outputter

      attr_reader :out
      attr_reader :err
      attr_accessor :indent
      attr_reader :line_started

      def initialize(out, err)
        @out, @err = out, err
        @indent = 0
        @line_started = false
      end

      def highline
        @highline ||= begin
          require 'highline'
          HighLine.new
        end
      end

      # Print text.  This will start a new line and indent if necessary
      # but will not terminate the line (future print and puts statements
      # will start off where this print left off).
      def color(string, *colors)
        if !@line_started
          @out.print ' ' * indent
          @line_started = true
        end
        if string[-1..-1] == "\n"
          @line_started = false
        end

        if Chef::Config[:color]
          @out.print highline.color(string, *colors)
        else
          @out.print string
        end
      end

      alias :print :color

      # Print a line.  This will continue from the last start_line or print,
      # or start a new line and indent if necessary.
      def puts(string, *colors)
        if !@line_started
          @out.print ' ' * indent
        end

        if Chef::Config[:color]
          @out.puts highline.color(string, *colors)
        else
          @out.puts string
        end
        @line_started = false
      end

      # Print an entire line from start to end.  This will terminate any existing
      # lines and cause indentation.
      def puts_line(string, *colors)
        if @line_started
          @out.puts ''
          @line_started = false
        end

        puts(string, *colors)
      end

      # Print the start of a new line.  This will terminate any existing lines and
      # cause indentation but will not move to the next line yet (future 'print'
      # and 'puts' statements will stay on this line).
      def start_line(string, *colors)
        if @line_started
          @out.puts ''
          @line_started = false
        end
        print(string, *colors)
      end

    end


    # == Formatters::Base
    # Base class that all formatters should inherit from.
    class Base < EventDispatch::Base

      include ErrorMapper

      def self.cli_name(name)
        Chef::Formatters.register(name, self)
      end

      attr_reader :out
      attr_reader :err
      attr_reader :output

      def initialize(out, err)
        @output = Outputter.new(out, err)
      end

      def puts(*args)
        @output.puts(*args)
      end

      def print(*args)
        @output.print(*args)
      end

      def puts_line(*args)
        @output.puts_line(*args)
      end

      def start_line(*args)
        @output.start_line(*args)
      end

      def indent_by(amount)
        @output.indent += amount
      end

      # Input: a Formatters::ErrorDescription object.
      # Outputs error to SDOUT.
      def display_error(description)
        puts("")
        description.display(output)
      end

      def registration_failed(node_name, exception, config)
        #A Formatters::ErrorDescription object
        description = ErrorMapper.registration_failed(node_name, exception, config)
        display_error(description)
      end

      def node_load_failed(node_name, exception, config)
        description = ErrorMapper.node_load_failed(node_name, exception, config)
        display_error(description)
      end

      def run_list_expand_failed(node, exception)
        description = ErrorMapper.run_list_expand_failed(node, exception)
        display_error(description)
      end

      def cookbook_resolution_failed(expanded_run_list, exception)
        description = ErrorMapper.cookbook_resolution_failed(expanded_run_list, exception)
        display_error(description)
      end

      def cookbook_sync_failed(cookbooks, exception)
        description = ErrorMapper.cookbook_sync_failed(cookbooks, exception)
        display_error(description)
      end

      def resource_failed(resource, action, exception)
        description = ErrorMapper.resource_failed(resource, action, exception)
        display_error(description)
      end

      # Generic callback for any attribute/library/lwrp/recipe file in a
      # cookbook getting loaded. The per-filetype callbacks for file load are
      # overriden so that they call this instead. This means that a subclass of
      # Formatters::Base can implement #file_loaded to do the same thing for
      # every kind of file that Chef loads from a recipe instead of
      # implementing all the per-filetype callbacks.
      def file_loaded(path)
      end

      # Generic callback for any attribute/library/lwrp/recipe file throwing an
      # exception when loaded. Default behavior is to use CompileErrorInspector
      # to print contextual info about the failure.
      def file_load_failed(path, exception)
        description = ErrorMapper.file_load_failed(path, exception)
        display_error(description)
      end

      def recipe_not_found(exception)
        description = ErrorMapper.file_load_failed(nil, exception)
        display_error(description)
      end

      # Delegates to #file_loaded
      def library_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def library_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def lwrp_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def lwrp_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def attribute_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def attribute_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def definition_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def definition_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def recipe_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def recipe_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

    end


    # == NullFormatter
    # Formatter that doesn't actually produce any output. You can use this to
    # disable the use of output formatters.
    class NullFormatter < Base

      cli_name(:null)

    end

  end
end

