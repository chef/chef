#
# Author:: Tyler Ball (<tball@chef.io>)
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

RSpec::Support.require_rspec_core "formatters/base_text_formatter"

class Chef
  class Audit
    class AuditEventProxy < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self, :stop, :example_group_started

      # TODO I don't like this, but I don't see another way to pass this in
      # see rspec files configuration.rb#L671 and formatters.rb#L129
      def self.events=(events)
        @@events = events
      end

      def events
        @@events
      end

      def example_group_started(notification)
        if notification.group.parent_groups.size == 1
          # top level `control_group` block
          desc = notification.group.description
          Chef::Log.debug("Entered `control_group` block named #{desc}")
          events.control_group_started(desc)
        end
      end

      def stop(notification)
        Chef::Log.info("Successfully executed all `control_group` blocks and contained examples")
        notification.examples.each do |example|
          control_group_name, control_data = build_control_from(example)
          e = example.exception
          if e
            events.control_example_failure(control_group_name, control_data, e)
          else
            events.control_example_success(control_group_name, control_data)
          end
        end
      end

      private

      def build_control_from(example)
        described_class = example.metadata[:described_class]
        if described_class
          resource_type = described_class.class.name.split(":")[-1]
          resource_name = described_class.name
        end

        # The following code builds up the context - the list of wrapping `describe` or `control` blocks
        describe_groups = []
        group = example.metadata[:example_group]
        # If the innermost block has a resource instead of a string, don't include it in context
        describe_groups.unshift(group[:description]) if described_class.nil?
        group = group[:parent_example_group]
        until group.nil?
          describe_groups.unshift(group[:description])
          group = group[:parent_example_group]
        end

        # We know all of our examples each live in a top-level `control_group` block - get this name now
        outermost_group_desc = describe_groups.shift

        [outermost_group_desc, {
            :name => example.description,
            :desc => example.full_description,
            :resource_type => resource_type,
            :resource_name => resource_name,
            :context => describe_groups,
            :line_number => example.metadata[:line_number],
        }]
      end

    end
  end
end
