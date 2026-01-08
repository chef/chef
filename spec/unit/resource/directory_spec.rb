#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::Directory do
  let(:resource) { Chef::Resource::Directory.new("fakey_fakerton") }

  it "the path property is the name_property" do
    expect(resource.path).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "accepts a string as the path" do
    expect { resource.path "/tmp" }.not_to raise_error
    expect(resource.path).to eql("/tmp")
    expect { resource.path({}) }.to raise_error(ArgumentError)
  end

  it "allows you to have specify whether the action is recursive with true/false" do
    expect { resource.recursive true }.not_to raise_error
    expect { resource.recursive false }.not_to raise_error
    expect { resource.recursive "monkey" }.to raise_error(ArgumentError)
  end

  describe "when it has group, mode, and owner" do
    before do
      resource.path("/tmp/foo/bar/")
      resource.group("wheel")
      resource.mode("0664")
      resource.owner("root")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:group]).to eq("wheel")
      expect(state[:mode]).to eq("0664")
      expect(state[:owner]).to eq("root")
    end

    it "returns the directory path as its identity" do
      expect(resource.identity).to eq("/tmp/foo/bar/")
    end
  end
end
