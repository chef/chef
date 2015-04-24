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
        register_control_groups
        do_run
      end

      def failed?
        RSpec.world.reporter.failed_examples.size > 0
      end

      def num_failed
        RSpec.world.reporter.failed_examples.size
      end

      def num_total
        RSpec.world.reporter.examples.size
      end

      def exclusion_pattern
        Regexp.new(".+[\\\/]lib[\\\/]chef[\\\/]")
      end

      private
      # Prepare to run audits:
      #  - Require files
      #  - Configure RSpec
      #  - Configure Specinfra/Serverspec
      def setup
        require_deps
        configure_rspec
        configure_specinfra
      end

      # RSpec uses a global configuration object, RSpec.configuration. We found
      # there was interference between the configuration for audit-mode and
      # the configuration for our own spec tests in these cases:
      #   1. Specinfra and Serverspec modify RSpec.configuration when loading.
      #   2. Setting output/error streams.
      #   3. Adding formatters.
      #   4. Defining example group aliases.
      #
      # Moreover, Serverspec loads its DSL methods into the global namespace,
      # which causes conflicts with the Chef namespace for resources and packages.
      #
      # We wait until we're in the audit-phase of the chef-client run to load
      # these files. This helps with the namespacing problems we saw, and
      # prevents Specinfra and Serverspec from modifying the RSpec configuration
      # used by our spec tests.
      def require_deps
        require 'rspec'
        require 'rspec/its'
        require 'specinfra'
        require 'specinfra/helper'
        require 'specinfra/helper/set'
        require 'serverspec/helper'
        require 'serverspec/matcher'
        require 'serverspec/subject'
        require 'chef/audit/audit_event_proxy'
        require 'chef/audit/rspec_formatter'

        Specinfra::Backend::Cmd.send(:include, Specinfra::Helper::Set)
      end

      # Configure RSpec just the way we like it:
      #   - Set location of error and output streams
      #   - Add custom audit-mode formatters
      #   - Explicitly disable :should syntax
      #   - Set :color option according to chef config
      #   - Disable exposure of global DSL
      def configure_rspec
        set_streams
        add_formatters
        disable_should_syntax

        RSpec.configure do |c|
          c.color = Chef::Config[:color]
          c.expose_dsl_globally = false
          c.backtrace_exclusion_patterns << exclusion_pattern
        end
      end

      # Set the error and output streams which audit-mode will use to report
      # human-readable audit information.
      #
      # This should always be called before #add_formatters. RSpec won't allow
      # the output stream to be changed for a formatter once the formatter has
      # been added.
      def set_streams
        RSpec.configuration.output_stream = Chef::Config[:log_location]
        RSpec.configuration.error_stream = Chef::Config[:log_location]
      end

      # Add formatters which we use to
      #   1. Output human-readable data to the output stream,
      #   2. Collect JSON data to send back to the analytics server.
      def add_formatters
        RSpec.configuration.add_formatter(Chef::Audit::AuditEventProxy)
        RSpec.configuration.add_formatter(Chef::Audit::RspecFormatter)
        Chef::Audit::AuditEventProxy.events = run_context.events
      end

      # Audit-mode uses RSpec 3. :should syntax is deprecated by default in
      # RSpec 3, so we explicitly disable it here.
      #
      # This can be removed once :should is removed from RSpec.
      def disable_should_syntax
        RSpec.configure do |config|
          config.expect_with :rspec do |c|
            c.syntax = :expect
          end
        end
      end

      # Set up the backend for Specinfra/Serverspec.  :exec is the local system; on Windows, it is :cmd
      def configure_specinfra
        if Chef::Platform.windows?
          Specinfra.configuration.backend = :cmd
          Specinfra.configuration.os = { :family => 'windows' }
        else
          Specinfra.configuration.backend = :exec
        end
      end

      # Iterates through the control groups registered to this run_context, builds an
      # example group (RSpec::Core::ExampleGroup) object per control group, and
      # registers the group with the RSpec.world.
      #
      # We could just store an array of example groups and not use RSpec.world,
      # but it may be useful later if we decide to apply our own ordering scheme
      # or use example group filters.
      def register_control_groups
        add_example_group_methods
        run_context.audits.each do |name, group|
          ctl_grp = RSpec::Core::ExampleGroup.__control_group__(*group.args, &group.block)
          RSpec.world.register(ctl_grp)
        end
      end

      # Add example group method aliases to RSpec.
      #
      # __control_group__: Used internally to create example groups from the control
      #               groups saved in the run_context.
      #      control: Used within the context of a control group block, like RSpec's
      #               describe or context.
      def add_example_group_methods
        RSpec::Core::ExampleGroup.define_example_group_method :__control_group__
        RSpec::Core::ExampleGroup.define_example_group_method :control
      end

      # Run the audits!
      def do_run
        # RSpec::Core::Runner wants to be initialized with an
        # RSpec::Core::ConfigurationOptions object, which is used to process
        # command line configuration arguments. We directly fiddle with the
        # internal RSpec configuration object, so we give nil here and let
        # RSpec pick up its own configuration and world.
        runner = RSpec::Core::Runner.new(nil)
        runner.run_specs(RSpec.world.ordered_example_groups)
      end

    end
  end
end
