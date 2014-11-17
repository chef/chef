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

describe "Duplicated `package` DSL in Chef and Serverspec" do

  # TODO disable rspec global DSL - but do we want it enabled for OUR rspecs?  No, because we always have a runner?
  # TODO disable serverspec global DSL

  let(:run_context) {
    node = Chef::Node.new
    Chef::RunContext.new(node, {}, nil)
  }

  it "Should call the Chef Recipe DSL in a Chef Recipe" do
    # Chef::DSL::Recipe#method_missing calls #resource_for_node twice when looking up the Resource instance - once in
    # #have_resource_class_for? and once in #declare_resource.  Chef::DSL::Recipe#resource_class_for calls
    # Chef::Resource#resource_for_node
    expect(Chef::Resource).to receive(:resource_for_node).with(:package, instance_of(Chef::Node)).exactly(2).times.and_return(Chef::Resource::Package)
    expect(Chef::Resource::Package).to receive(:new).with("foo1", run_context).and_call_original

    Chef::Recipe.new("cookbook", "recipe", run_context).instance_eval do
      # Inside a recipe self refers to a Recipe object, so it calls the correct #method_missing chain to find the
      # package resource
      package "foo1"
    end
  end

  it "Should call the Serverspec DSL in a `controls` block" do
    expect(Chef::Resource).to_not receive(:resource_for_node)
    # Waiting until here to require this because otherwise it complains that it hasn't been configured yet
    # and configuration takes place in the `controls` method
    require 'serverspec'

    Chef::Recipe.new("cookbook", "recipe", run_context).instance_eval do
      # Inside a `controls` block, self refers to a subclass of RSpec::ExampleGroups so `package` calls the correct
      # serverspec helper
      controls "some controls" do
        package "foo2"
      end
    end
  end

  it "Should still use the recipe DSL outside of a controls block after a controls block has ran" do
    expect(Serverspec::Type::Package).to receive(:new).with("foo3")
    expect(Serverspec::Type::Package).to receive(:new).with("baz")
    expect(Chef::Resource).to receive(:resource_for_node).with(:package, instance_of(Chef::Node)).exactly(4).times.and_return(Chef::Resource::Package)
    expect(Chef::Resource::Package).to receive(:new).with("bar", run_context).and_call_original
    expect(Chef::Resource::Package).to receive(:new).with("bang", run_context).and_call_original

    Chef::Recipe.new("cookbook", "recipe", run_context).instance_eval do
      controls "some controls" do
        package "foo3"
      end

      package "bar"

      controls "some more controls" do
        package "baz"
      end

      package "bang"
    end
  end

  it "Should not allow `control` or `__controls__` to be defined outside of a `controls` block" do
    expect {
      Chef::Recipe.new("cookbook", "recipe", run_context).instance_eval do
        control("foo4")
      end
    }.to raise_error(NoMethodError, /No resource or method named `control'/)

    Chef::Recipe.new("cookbook", "recipe", run_context).instance_eval do
      controls "some more controls" do
        control "foo5"
      end
    end

    # Even after seeing a `controls` block these methods should not work - even when running in rspec
    expect {
      Chef::Recipe.new("cookbook", "recipe", run_context).instance_eval do
        control("foo4")
      end
    }.to raise_error(NoMethodError, /No resource or method named `control'/)
  end

  it "Should include serverspec specific matchers only inside `controls` block" do
    # cgroup is a rspec matcher I'm assuming we won't define elsewhere
    # TODO this is currently failing because the RSpec::Core::ExampleGroup has already been extended with
    # the serverspec helpers
    expect { cgroup('group1') }.to raise_error(NoMethodError, /No resource or method named `cgroup'/)

    expect(self).to receive(:cgroup).and_call_original
    controls "cgroup controls" do
      describe cgroup('group1') do
        true
      end
    end

    expect { cgroup('group1') }.to raise_error(NoMethodError, /No resource or method named `cgroup'/)
  end

  # TODO write cookbook which actually tests both `package` DSLs
end
