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

class Chef
  class Resource
    class Conditional
      include Chef::Mixin::ShellOut

      # We only create these via the `not_if` or `only_if` constructors, and
      # not the default constructor
      class << self
        private :new
      end

      def self.not_if(command=nil, command_opts={}, &block)
        new(:not_if, command, command_opts, &block)
      end

      def self.only_if(command=nil, command_opts={}, &block)
        new(:only_if, command, command_opts, &block)
      end

      attr_reader :positivity
      attr_reader :command
      attr_reader :command_opts
      attr_reader :block

      def initialize(positivity, command=nil, command_opts={}, &block)
        @positivity = positivity
        case command
        when String
          @command, @command_opts = command, command_opts
          @block = nil
        when nil
          raise ArgumentError, "only_if/not_if requires either a command or a block" unless block_given?
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
        @command ? evaluate_command : evaluate_block
      end

      def evaluate_command
        shell_out(@command, @command_opts).status.success?
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

    end
  end
end
