require 'spec_helper'
require 'spec/support/audit_helper'
require 'chef/audit/runner'
require 'chef/audit/audit_event_proxy'
require 'chef/audit/rspec_formatter'
require 'chef/run_context'
require 'pry'

##
# This functional test ensures that our runner can be setup to not interfere with existing RSpec
# configuration and world objects.  When normally running Chef, there is only 1 RSpec instance
# so this isn't needed.  In unit testing the Runner should be mocked appropriately.

describe Chef::Audit::Runner do

  let(:events) { double("events") }
  let(:run_context) { instance_double(Chef::RunContext) }
  let(:runner) { Chef::Audit::Runner.new(run_context) }

  # This is the first thing that gets called, and determines how the examples are ran
  around(:each) do |ex|
    Sandboxing.sandboxed { ex.run }
  end

  describe "#configure_rspec" do

    it "adds the necessary formatters" do
      # We don't expect the events to receive any calls because the AuditEventProxy that was registered from `runner.run`
      # only existed in the Configuration object that got removed by the sandboxing
      #expect(events).to receive(:control_example_success)

      expect(RSpec.configuration.formatters.size).to eq(0)
      expect(run_context).to receive(:events).and_return(events)
      expect(Chef::Audit::AuditEventProxy).to receive(:events=)

      runner.send(:add_formatters)

      expect(RSpec.configuration.formatters.size).to eq(2)
      expect(RSpec.configuration.formatters[0]).to be_instance_of(Chef::Audit::AuditEventProxy)
      expect(RSpec.configuration.formatters[1]).to be_instance_of(Chef::Audit::RspecFormatter)

    end

  end

  # When running these, because we are not mocking out any of the formatters we expect to get dual output on the
  # command line
  describe "#run" do

    before do
      expect(run_context).to receive(:events).and_return(events)
    end

    it "Correctly runs an empty controls block" do
      expect(run_context).to receive(:audits).and_return({})
      runner.run
    end

    it "Correctly runs a single successful control" do
      should_pass = lambda do
        it "should pass" do
          expect(2 - 2).to eq(0)
        end
      end

      expect(run_context).to receive(:audits).and_return({
        "should pass" => {:args => [], :block => should_pass}
      })

      # TODO capture the output and verify it
      runner.run
    end

    it "Correctly runs a single failing control", :pending do

    end

  end

end
