#
# Author:: Tyler Ball (<tball@chef.io>)
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

require 'spec_helper'
require 'rspec/core/sandbox'
require 'chef/audit/runner'
require 'chef/audit/audit_event_proxy'
require 'chef/audit/rspec_formatter'
require 'rspec/support/spec/in_sub_process'
require 'rspec/support/spec/stderr_splitter'


describe Chef::Audit::Runner do
  include RSpec::Support::InSubProcess

  let(:events) { double("events") }
  let(:run_context) { instance_double(Chef::RunContext, :events => events) }
  let(:runner) { Chef::Audit::Runner.new(run_context) }

  around(:each) do |ex|
    RSpec::Core::Sandbox.sandboxed { ex.run }
  end

  describe "#initialize" do
    it "correctly sets the run_context during initialization" do
      expect(runner.instance_variable_get(:@run_context)).to eq(run_context)
    end
  end

  context "during #run" do

    describe "#setup" do
      let(:log_location) { File.join(Dir.tmpdir, 'audit_log') }
      let(:color) { false }

      before do
        Chef::Config[:log_location] = log_location
        Chef::Config[:color] = color
      end

      it "sets all the config values" do
        # This runs the Serverspec includes - we don't want these hanging around in all subsequent tests so
        # we run this in a forked process.  Keeps Serverspec files from getting loaded into main process.
        in_sub_process do
          runner.send(:setup)

          expect(RSpec.configuration.output_stream).to eq(log_location)
          expect(RSpec.configuration.error_stream).to eq(log_location)

          expect(RSpec.configuration.formatters.size).to eq(2)
          expect(RSpec.configuration.formatters).to include(instance_of(Chef::Audit::AuditEventProxy))
          expect(RSpec.configuration.formatters).to include(instance_of(Chef::Audit::RspecFormatter))
          expect(Chef::Audit::AuditEventProxy.class_variable_get(:@@events)).to eq(run_context.events)

          expect(RSpec.configuration.expectation_frameworks).to eq([RSpec::Matchers])
          expect(RSpec::Matchers.configuration.syntax).to eq([:expect])

          expect(RSpec.configuration.color).to eq(color)
          expect(RSpec.configuration.expose_dsl_globally?).to eq(false)

          expect(Specinfra.configuration.backend).to eq(:exec)
        end
      end
    end

    describe "#register_controls" do
      let(:audits) { [] }
      let(:run_context) { instance_double(Chef::RunContext, :audits => audits) }

      it "adds the control group aliases" do
        runner.send(:register_controls)

        expect(RSpec::Core::DSL.example_group_aliases).to include(:__controls__)
        expect(RSpec::Core::DSL.example_group_aliases).to include(:control)
      end

      context "audits exist" do
        let(:audits) { {"audit_name" => group} }
        let(:group) {Struct.new(:args, :block).new(["group_name"], nil)}

        it "sends the audits to the world" do
          runner.send(:register_controls)

          expect(RSpec.world.example_groups.size).to eq(1)
          # For whatever reason, `kind_of` is not working
          # expect(RSpec.world.example_groups).to include(kind_of(RSpec::Core::ExampleGroup)) => FAIL
          g = RSpec.world.example_groups[0]
          expect(g.ancestors).to include(RSpec::Core::ExampleGroup)
          expect(g.description).to eq("group_name")
        end
      end
    end

    describe "#do_run" do
      let(:rspec_runner) { instance_double(RSpec::Core::Runner) }

      it "executes the runner" do
        expect(RSpec::Core::Runner).to receive(:new).with(nil).and_return(rspec_runner)
        expect(rspec_runner).to receive(:run_specs).with([])

        runner.send(:do_run)
      end
    end
  end

  describe "counters" do
    it "correctly calculates failed?" do
      expect(runner.failed?).to eq(false)
    end

    it "correctly calculates num_failed" do
      expect(runner.num_failed).to eq(0)
    end

    it "correctly calculates num_total" do
      expect(runner.num_total).to eq(0)
    end
  end

end
