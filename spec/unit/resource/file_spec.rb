#
# Author:: Adam Jacob (<adam@chef.io>)
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

describe Chef::Resource::File do

  let(:resource) { Chef::Resource::File.new("fakey_fakerton") }

  it "the path property is the name_property" do
    expect(resource.path).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :create_if_missing, :delete, :touch actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :create_if_missing }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :touch }.not_to raise_error
  end

  it "has a default content of nil" do
    expect(resource.content).to be_nil
  end

  it "is set to back up 5 files by default" do
    expect(resource.backup).to eql(5)
  end

  it "only accept strings for content" do
    expect { resource.content 5 }.to raise_error(ArgumentError)
    expect { resource.content :foo }.to raise_error(ArgumentError)
    expect { resource.content "hello" => "there" }.to raise_error(ArgumentError)
    expect { resource.content "hi" }.not_to raise_error
  end

  it "only accept false or a number for backup" do
    expect { resource.backup true }.to raise_error(ArgumentError)
    expect { resource.backup false }.not_to raise_error
    expect { resource.backup 10 }.not_to raise_error
    expect { resource.backup "blues" }.to raise_error(ArgumentError)
  end

  it "accepts a sha256 for checksum" do
    expect { resource.checksum "0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa" }.not_to raise_error
    expect { resource.checksum "monkey!" }.to raise_error(ArgumentError)
  end

  it "accepts a block, symbol, or string for verify" do
    expect { resource.verify {} }.not_to raise_error
    expect { resource.verify "" }.not_to raise_error
    expect { resource.verify :json }.not_to raise_error
    expect { resource.verify true }.to raise_error(ArgumentError)
    expect { resource.verify false }.to raise_error(ArgumentError)
  end

  it "accepts multiple verify statements" do
    resource.verify "foo"
    resource.verify "bar"
    resource.verify.length == 2
  end

  it "uses the object name as the path by default" do
    expect(resource.path).to eql("fakey_fakerton")
  end

  it "accepts a string as the path" do
    expect { resource.path "/tmp" }.not_to raise_error
    expect(resource.path).to eql("/tmp")
    expect { resource.path({}) }.to raise_error(ArgumentError)
  end

  describe "when it has a path, owner, group, mode, and checksum" do
    before do
      resource.path("/tmp/foo.txt")
      resource.owner("root")
      resource.group("wheel")
      resource.mode("0644")
      resource.checksum("1" * 64)
    end

    context "on unix", :unix_only do
      it "describes its state" do
        state = resource.state_for_resource_reporter
        expect(state[:owner]).to eq("root")
        expect(state[:group]).to eq("wheel")
        expect(state[:mode]).to eq("0644")
        expect(state[:checksum]).to eq("1" * 64)
      end
    end

    it "returns the file path as its identity" do
      expect(resource.identity).to eq("/tmp/foo.txt")
    end

  end

  describe "when access controls are set on windows", windows_only: true do
    before do
      resource.rights :read, "Everyone"
      resource.rights :full_control, "DOMAIN\\User"
    end
    it "describes its state including windows ACL properties" do
      state = resource.state_for_resource_reporter
      expect(state[:rights]).to eq([ { permissions: :read, principals: "Everyone" },
                               { permissions: :full_control, principals: "DOMAIN\\User" } ])
    end
  end
end
