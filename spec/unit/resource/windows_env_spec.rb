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

describe Chef::Resource::WindowsEnv do

  let(:resource) { Chef::Resource::WindowsEnv.new("fakey_fakerton") }

  it "creates a new Chef::Resource::WindowsEnv" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::WindowsEnv)
  end

  it "the key_name property is the name_property" do
    expect(resource.key_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete, :modify actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :modify }.not_to raise_error
  end

  it "accepts a string as the env value via 'value'" do
    expect { resource.value "bar" }.not_to raise_error
  end

  it "does not accept a Hash for the env value via 'to'" do
    expect { resource.value({}) }.to raise_error(ArgumentError)
  end

  it "allows you to set an env value via 'to'" do
    resource.value "bar"
    expect(resource.value).to eql("bar")
  end

  describe "when it has key name and value" do
    before do
      resource.key_name("charmander")
      resource.value("level7")
      resource.delim("hi")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:value]).to eq("level7")
    end

    it "returns the key name as its identity" do
      expect(resource.identity).to eq("charmander")
    end
  end

end
