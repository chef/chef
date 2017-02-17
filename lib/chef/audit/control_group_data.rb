#
# Author:: Tyler Ball (<tball@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "securerandom"

class Chef
  class Audit
    class AuditData
      attr_reader :node_name, :run_id, :control_groups
      attr_accessor :start_time, :end_time

      def initialize(node_name, run_id)
        @node_name = node_name
        @run_id = run_id
        @control_groups = []
      end

      def add_control_group(control_group)
        control_groups << control_group
      end

      def to_hash
        {
            :node_name => node_name,
            :run_id => run_id,
            :start_time => start_time,
            :end_time => end_time,
            :control_groups => control_groups.collect { |c| c.to_hash },
        }
      end
    end

    class ControlGroupData
      attr_reader :name, :status, :number_succeeded, :number_failed, :controls, :metadata

      def initialize(name, metadata = {})
        @status = "success"
        @controls = []
        @number_succeeded = 0
        @number_failed = 0
        @name = name
        @metadata = metadata
      end

      def example_success(control_data)
        @number_succeeded += 1
        control = create_control(control_data)
        control.status = "success"
        controls << control
        control
      end

      def example_failure(control_data, details)
        @number_failed += 1
        @status = "failure"
        control = create_control(control_data)
        control.details = details if details
        control.status = "failure"
        controls << control
        control
      end

      def to_hash
        # We sort it so the examples appear in the output in the same order
        # they appeared in the recipe
        controls.sort! { |x, y| x.line_number <=> y.line_number }
        h = {
              :name => name,
              :status => status,
              :number_succeeded => number_succeeded,
              :number_failed => number_failed,
              :controls => controls.collect { |c| c.to_hash },
        }
        # If there is a duplicate key, metadata will overwrite it
        add_display_only_data(h).merge(metadata)
      end

      private

      def create_control(control_data)
        ControlData.new(control_data)
      end

      # The id and control sequence number are ephemeral data - they are not needed
      # to be persisted and can be regenerated at will.  They are only needed
      # for display purposes.
      def add_display_only_data(group)
        group[:id] = SecureRandom.uuid
        group[:controls].collect!.with_index do |c, i|
          # i is zero-indexed, and we want the display one-indexed
          c[:sequence_number] = i + 1
          c
        end
        group
      end

    end

    class ControlData
      attr_reader :name, :resource_type, :resource_name, :context, :line_number
      attr_accessor :status, :details

      def initialize(control_data = {})
        control_data.each do |k, v|
          instance_variable_set("@#{k}", v)
        end
      end

      def to_hash
        h = {
            :name => name,
            :status => status,
            :details => details,
            :resource_type => resource_type,
            :resource_name => resource_name,
        }
        h[:context] = context || []
        h
      end
    end

  end
end
