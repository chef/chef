#
# Author:: Tyler Ball (<tball@chef.io>)
# Author:: Claire McQuin (<claire@getchef.com>)
#
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
require 'chef/audit/rspec_formatter'

describe Chef::Audit::RspecFormatter do
  include RSpec::Support::InSubProcess

  let(:events) { double("events").as_null_object }
  let(:audits) { {} }
  let(:run_context) { instance_double(Chef::RunContext, :events => events, :audits => audits) }
  let(:runner) { Chef::Audit::Runner.new(run_context) }

  let(:output) { double("output") }
  # aggressively define this so we can mock out the new call later
  let!(:formatter) { Chef::Audit::RspecFormatter.new(output) }

  around(:each) do |ex|
    RSpec::Core::Sandbox.sandboxed { ex.run }
  end

  it "should not close the output using our formatter" do
    in_sub_process do
      expect_any_instance_of(Chef::Audit::RspecFormatter).to receive(:new).and_return(formatter)
      expect(formatter).to receive(:close).and_call_original
      expect(output).to_not receive(:close)

      runner.run
    end
  end

end
