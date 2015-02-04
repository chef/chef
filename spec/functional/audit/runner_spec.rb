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
require 'rspec/support/spec/in_sub_process'
require 'rspec/support/spec/stderr_splitter'
require 'tempfile'

##
# This functional test ensures that our runner can be setup to not interfere with existing RSpec
# configuration and world objects.  When normally running Chef, there is only 1 RSpec instance
# so this isn't needed.  In unit testing the Runner should be mocked appropriately.

describe Chef::Audit::Runner do

  # The functional tests must be run in a sub_process.  Including Serverspec includes the Serverspec DSL - this
  # conflicts with our `package` DSL (among others) when we try to test `package` inside an RSpec example.
  # Our DSL leverages `method_missing` while the Serverspec DSL defines a method on the RSpec::Core::ExampleGroup.
  # The defined method wins our and returns before our `method_missing` DSL can be called.
  #
  # Running in a sub_process means the serverspec libraries will only be included in a forked process, not the main one.
  include RSpec::Support::InSubProcess

  let(:events) { double("events").as_null_object }
  let(:runner) { Chef::Audit::Runner.new(run_context) }
  let(:stdout) { StringIO.new }

  around(:each) do |ex|
    RSpec::Core::Sandbox.sandboxed { ex.run }
  end

  before do
    Chef::Config[:log_location] = stdout
  end
  
  describe "#run" do

    let(:audits) { {} }
    let(:run_context) { instance_double(Chef::RunContext, :events => events, :audits => audits) }
    let(:controls_name) { "controls_name" }

    it "Correctly runs an empty controls block" do
      in_sub_process do
        runner.run
      end
    end

    shared_context "passing audit" do
      let(:audits) do
        should_pass = lambda do
          it "should pass" do
            expect(2 - 2).to eq(0)
          end
        end
        { controls_name => Struct.new(:args, :block).new([controls_name], should_pass)}
      end
    end

    shared_context "failing audit" do
      let(:audits) do
        should_fail = lambda do
          it "should fail" do
            expect(2 - 1).to eq(0)
          end
        end
        { controls_name => Struct.new(:args, :block).new([controls_name], should_fail)}
      end
    end

    context "there is a single successful control" do
      include_context "passing audit"
      it "correctly runs" do
        in_sub_process do
          runner.run

          expect(stdout.string).to match(/1 example, 0 failures/)
        end
      end
    end

    context "there is a single failing control" do
      include_context "failing audit"
      it "correctly runs" do
        in_sub_process do
          runner.run

          expect(stdout.string).to match(/Failure\/Error: expect\(2 - 1\)\.to eq\(0\)/)
          expect(stdout.string).to match(/1 example, 1 failure/)
          expect(stdout.string).to match(/# controls_name should fail/)
        end
      end
    end

    describe "log location is a file" do
      let(:tmpfile) { Tempfile.new("audit") }
      before do
        Chef::Config[:log_location] = tmpfile.path
      end

      after do
        tmpfile.close
        tmpfile.unlink
      end

      include_context "failing audit"
      it "correctly runs" do
        in_sub_process do
          runner.run

          contents = tmpfile.read
          expect(contents).to match(/Failure\/Error: expect\(2 - 1\)\.to eq\(0\)/)
          expect(contents).to match(/1 example, 1 failure/)
          expect(contents).to match(/# controls_name should fail/)
        end
      end
    end

  end

end
