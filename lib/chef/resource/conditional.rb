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

require 'chef/mixin/shell_out'
require 'chef/guard_interpreter/resource_guard_interpreter'

class Chef
  class Resource
    class Conditional
      include Chef::Mixin::ShellOut

      # We only create these via the `not_if` or `only_if` constructors, and
      # not the default constructor
      class << self
        private :new
      end

      def self.not_if(parent_resource, command=nil, command_opts={}, &block)
        new(:not_if, parent_resource, command, command_opts, &block)
      end

      def self.only_if(parent_resource, command=nil, command_opts={}, &block)
        new(:only_if, parent_resource, command, command_opts, &block)
      end

      attr_reader :positivity
      attr_reader :command
      attr_reader :command_opts
      attr_reader :block

      def initialize(positivity, parent_resource, command=nil, command_opts={}, &block)
        @positivity = positivity
        case command
        when String
          @guard_interpreter = new_guard_interpreter(parent_resource, command, command_opts, &block)
          @command, @command_opts = command, command_opts
          @block = nil
        when nil
          raise ArgumentError, "only_if/not_if requires either a command or a block" unless block_given?
          if parent_resource.guard_interpreter != :default
            msg = "#{parent_resource.name} was given a guard_interpreter of #{parent_resource.guard_interpreter}, "
            msg << "but not given a command as a string. guard_interpreter does not support blocks."
            raise ArgumentError, msg
          end
          @guard_interpreter = nil
          @command, @command_opts = nil, nil
          @block = block
        else
          raise ArgumentError, "Invalid only_if/not_if command: #{command.inspect} (#{command.class})"
        end
      end

      def continue?
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
        @block.call
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

      private

      def new_guard_interpreter(parent_resource, command, opts)
        if parent_resource.guard_interpreter == :default
          guard_interpreter = Chef::GuardInterpreter::DefaultGuardInterpreter.new(command, opts)
        else
          guard_interpreter = Chef::GuardInterpreter::ResourceGuardInterpreter.new(parent_resource, command, opts)
        end
      end

    end
  end
end
