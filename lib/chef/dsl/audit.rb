#
# Author:: Tyler Ball (<tball@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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
require 'rspec/core'

class Chef
  module DSL
    module Audit

      # List of `controls` example groups to be executed
      @example_groups = nil

      # Adds the control_group and block (containing controls to execute) to the runner's list of pending examples
      def control_group(group_name, &group_block)
        puts "entered group named #{group_name}"
        @example_groups = []

        if group_block
          yield
        end

        # TODO add the @example_groups list to the runner for later execution
        p @example_groups

        # Reset this to nil so we can tell if a `controls` message is sent outside a `control_group` block
        # Prevents defining then un-defining the `controls` singleton method
        @example_groups = nil
      end

      def controls(*args, &control_block)
        if @example_groups.nil?
          raise "Cannot define a `controls` unless inside a `control_group`"
        end

        example_name = args[0]
        puts "entered control block named #{example_name}"
        # TODO is this the correct way to define one?
        # https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/example_group.rb#L197
        # https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/example_group.rb#L323
        @example_groups << ::RSpec::Core::ExampleGroup.describe(args, &control_block)
      end

    end
  end
end


