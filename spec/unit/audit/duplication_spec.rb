#
# Author:: Tyler Ball (<tball@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef, Inc.
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
require 'chef/recipe'
require 'chef/audit/runner'

describe "Duplicated `package` DSL in Chef and Serverspec" do

  # TODO (?) disable rspec global DSL - but do we want it enabled for OUR rspecs?  No, because we always have a runner?
  # TODO (?) disable serverspec global DSL

  let(:cookbook_repo) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "data", "cookbooks")) }
  let(:audit_recipes) { File.join(cookbook_repo, "audit", "recipes") }

  let(:cookbook_loader) do
    loader = Chef::CookbookLoader.new(cookbook_repo)
    loader.load_cookbooks
    loader
  end

  let(:cookbook_collection) { Chef::CookbookCollection.new(cookbook_loader) }

  let(:node) do
    Chef::Node.new.tap {|n| n.normal[:tags] = [] }
  end

  let(:events) do
    Chef::EventDispatch::Dispatcher.new
  end

  let(:run_context) do
    Chef::RunContext.new(node, cookbook_collection, events)
  end

  let(:auditor) do
    auditor = Chef::Audit::Runner.new(run_context)
    allow(auditor).to receive(:configure_rspec).and_return(true)
    allow(auditor).to receive(:do_run).and_return(true)
    auditor
  end

  it "Should call the Chef Recipe DSL in a Chef Recipe" do
    # Chef::DSL::Recipe#method_missing calls #resource_for_node twice when looking up the Resource instance - once in
    # #have_resource_class_for? and once in #declare_resource.  Chef::DSL::Recipe#resource_class_for calls
    # Chef::Resource#resource_for_node
    expect(Chef::Resource).to receive(:resource_for_node).with(:package, instance_of(Chef::Node)).exactly(2).times.and_return(Chef::Resource::Package)
    expect(Chef::Resource::Package).to receive(:new).with("foo1", run_context).and_call_original

    Chef::Recipe.new("audit", "default", run_context).from_file(File.join(audit_recipes, "default.rb"))
  end

  it "Should call the Serverspec DSL in a `controls` block" do
    expect(Chef::Resource).to_not receive(:resource_for_node)
    # Waiting until here to require this because otherwise it complains that it hasn't been configured yet
    # and configuration takes place in the `controls` method
    require 'serverspec'

    Chef::Recipe.new("audit", "single_controls", run_context).from_file(File.join(audit_recipes, "single_controls.rb"))
  end

  it "Should still use the recipe DSL outside of a controls block after a controls block has ran" do
    expect(Serverspec::Type::Package).to receive(:new).with("foo3")
    expect(Serverspec::Type::Package).to receive(:new).with("baz")
    expect(Chef::Resource).to receive(:resource_for_node).with(:package, instance_of(Chef::Node)).exactly(4).times.and_return(Chef::Resource::Package)
    expect(Chef::Resource::Package).to receive(:new).with("bar", run_context).and_call_original
    expect(Chef::Resource::Package).to receive(:new).with("bang", run_context).and_call_original

    Chef::Recipe.new("audit", "multiple_controls", run_context).from_file(File.join(audit_recipes, "multiple_controls.rb"))
    # Have to run the auditor because we have logic inside a `controls` block to test - that doesn't get evaluated
    # until the auditor is ran
    auditor.run
  end

  it "Should not allow `control` or `__controls__` to be defined outside of a `controls` block" do
    expect_any_instance_of(Chef::Recipe).to receive(:controls).with("some more controls").and_call_original
    expect_any_instance_of(Chef::Recipe).to receive(:control).with("foo4").and_call_original

    expect {
      Chef::Recipe.new("audit", "defined_outside_block", run_context).from_file(File.join(audit_recipes, "defined_outside_block.rb"))
    }.to raise_error(NoMethodError, /No resource or method named `control'/)
  end

  it "Should include serverspec specific matchers only inside `controls` block" do
    # cgroup is a rspec matcher I'm assuming we won't define elsewhere
    expect(Serverspec::Type::Cgroup).to receive(:new).with("group1").and_call_original
    expect {
      Chef::Recipe.new("audit", "serverspec_helpers", run_context).from_file(File.join(audit_recipes, "serverspec_helpers.rb"))
    }.to raise_error(NoMethodError, /No resource or method named `cgroup' for `Chef::Recipe/)
    auditor.run
  end
end
