#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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

require "spec_helper"

describe Chef::Resource::Env do

  before(:each) do
    @resource = Chef::Resource::Env.new("FOO")
  end

  it "should create a new Chef::Resource::Env" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Env)
  end

  it "should have a name" do
    expect(@resource.name).to eql("FOO")
  end

  it "should have a default action of 'create'" do
    expect(@resource.action).to eql([:create])
  end

  { :create => false, :delete => false, :modify => false, :flibber => true }.each do |action, bad_value|
    it "should #{bad_value ? 'not' : ''} accept #{action}" do
      if bad_value
        expect { @resource.action action }.to raise_error(ArgumentError)
      else
        expect { @resource.action action }.not_to raise_error
      end
    end
  end

  it "should use the object name as the key_name by default" do
    expect(@resource.key_name).to eql("FOO")
  end

  it "should accept a string as the env value via 'value'" do
    expect { @resource.value "bar" }.not_to raise_error
  end

  it "should not accept a Hash for the env value via 'to'" do
    expect { @resource.value Hash.new }.to raise_error(ArgumentError)
  end

  it "should allow you to set an env value via 'to'" do
    @resource.value "bar"
    expect(@resource.value).to eql("bar")
  end

  describe "when it has key name and value" do
    before do
      @resource.key_name("charmander")
      @resource.value("level7")
      @resource.delim("hi")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:value]).to eq("level7")
    end

    it "returns the key name as its identity" do
      expect(@resource.identity).to eq("charmander")
    end
  end

end
