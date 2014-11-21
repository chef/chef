#
# Author:: Claire McQuin (<claire@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

class Chef
  class Audit
    class Runner

      attr_reader :run_context
      private :run_context

      def initialize(run_context)
        @run_context = run_context
      end

      def run
        setup
        register_controls
        runner = RSpec::Core::Runner.new(nil)
        runner.run_specs(RSpec.world.ordered_example_groups)
      end

      private
      def setup
        require_deps
        set_streams
        add_formatters
        disable_should_syntax
        configure_specinfra
        add_example_group_methods
      end

      def register_controls
        run_context.controls.each do |name, group|
          ctl_grp = RSpec::Core::ExampleGroup.__controls__(*group[:args], &group[:block])
          RSpec.world.register(ctl_grp)
        end
      end

      def require_deps
        require 'rspec'
        require 'rspec/its'
        require 'specinfra'
        require 'serverspec/helper'
        require 'serverspec/matcher'
        require 'serverspec/subject'
        require 'chef/audit/audit_event_proxy'
        require 'chef/audit/rspec_formatter'
      end

      def set_streams
        RSpec.configuration.output_stream = Chef::Config[:log_location]
        RSpec.configuration.error_stream = Chef::Config[:log_location]
      end

      def add_formatters
        RSpec.configuration.add_formatter(Chef::Audit::AuditEventProxy)
        RSpec.configuration.add_formatter(Chef::Audit::RspecFormatter)
        Chef::Audit::AuditEventProxy.events = run_context.events
      end

      def disable_should_syntax
        RSpec.configure do |config|
          config.expect_with :rspec do |c|
            c.syntax = :expect
          end
        end
      end

      def configure_specinfra
        Specinfra.configuration.backend = :exec
      end

      def add_example_group_methods
        RSpec::Core::ExampleGroup.define_example_group_method :__controls__
        RSpec::Core::ExampleGroup.define_example_group_method :control
      end

    end
  end
end
