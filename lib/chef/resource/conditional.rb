#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "chef/mixin/shell_out"
require "chef/guard_interpreter"

class Chef
  class Resource
    class Conditional
      include Chef::Mixin::ShellOut

      # We only create these via the `not_if` or `only_if` constructors, and
      # not the default constructor
      class << self
        private :new
      end

      def self.not_if(parent_resource, command = nil, command_opts = {}, &block)
        new(:not_if, parent_resource, command, command_opts, &block)
      end

      def self.only_if(parent_resource, command = nil, command_opts = {}, &block)
        new(:only_if, parent_resource, command, command_opts, &block)
      end

      attr_reader :positivity
      attr_reader :command
      attr_reader :command_opts
      attr_reader :block

      def initialize(positivity, parent_resource, command = nil, command_opts = {}, &block)
        @positivity = positivity
        @command, @command_opts = command, command_opts
        @block = block
        @block_given = block_given?
        @parent_resource = parent_resource

        raise ArgumentError, "only_if/not_if requires either a command or a block" unless command || block_given?
      end

      def configure
        case @command
        when String, Array
          @guard_interpreter = Chef::GuardInterpreter.for_resource(@parent_resource, @command, @command_opts)
          @block = nil
        when nil
          # We should have a block if we get here
          # Check to see if the user set the guard_interpreter on the parent resource. Note that
          # this error will not be raised when using the default_guard_interpreter
          if @parent_resource.guard_interpreter != @parent_resource.default_guard_interpreter
            msg = "#{@parent_resource.name} was given a guard_interpreter of #{@parent_resource.guard_interpreter}, "
            msg << "but not given a command as a string. guard_interpreter does not support blocks (because they just contain ruby)."
            raise ArgumentError, msg
          end

          @guard_interpreter = nil
          @command, @command_opts = nil, nil
        else
          # command was passed, but it wasn't a String
          raise ArgumentError, "Invalid only_if/not_if command, expected a string: #{command.inspect} (#{command.class})"
        end
      end

      # this is run during convergence via Chef::Resource#run_action -> Chef::Resource#should_skip?
      def continue?
        # configure late in case guard_interpreter is specified on the resource after the conditional
        configure

        case @positivity
        when :only_if
          evaluate
        when :not_if
          !evaluate
        else
          raise "Cannot evaluate resource conditional of type #{@positivity}"
        end
      end

      def evaluate
        @guard_interpreter ? evaluate_command : evaluate_block
      end

      def evaluate_command
        @guard_interpreter.evaluate
      rescue Chef::Exceptions::CommandTimeout
        Chef::Log.warn "Command '#{@command}' timed out"
        false
      end

      def evaluate_block
        @block.call.tap do |rv|
          if rv.is_a?(String) && !rv.empty?
            # This is probably a mistake:
            #   not_if { "command" }
            sanitized_rv = @parent_resource.sensitive ? "a string" : rv.inspect
            Chef::Log.warn("#{@positivity} block for #{@parent_resource} returned #{sanitized_rv}, did you mean to run a command?" +
              (@parent_resource.sensitive ? "" : " If so use '#{@positivity} #{sanitized_rv}' in your code."))
          end
        end
      end

      def short_description
        @positivity
      end

      def description
        cmd_or_block = @command ? "command `#{@command}`" : "ruby block"
        "#{@positivity} #{cmd_or_block}"
      end

      def to_text
        if @command
          "#{positivity} \"#{@command}\""
        else
          "#{@positivity} { #code block }"
        end
      end
    end
  end
end
