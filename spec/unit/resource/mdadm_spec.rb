#
# Author:: Joe Williams (<joe@joetify.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Joe Williams
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

describe Chef::Resource::Mdadm do

  let(:resource) do
    Chef::Resource::Mdadm.new("fakey_fakerton", run_context)
  end

  it "should create a new Chef::Resource::Mdadm" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::Mdadm)
  end

  it "should have a resource name of :mdadm" do
    expect(resource.resource_name).to eql(:mdadm)
  end

  it "should have a default action of create" do
    expect(resource.action).to eql([:create])
  end

  it "should accept create, assemble, stop as actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :assemble }.not_to raise_error
    expect { resource.action :stop }.not_to raise_error
  end

  it "should allow you to set the raid_device attribute" do
    resource.raid_device "/dev/md3"
    expect(resource.raid_device).to eql("/dev/md3")
  end

  it "should allow you to set the chunk attribute" do
    resource.chunk 256
    expect(resource.chunk).to eql(256)
  end

  it "should allow you to set the level attribute" do
    resource.level 1
    expect(resource.level).to eql(1)
  end

  it "should allow you to set the metadata attribute" do
    resource.metadata "1.2"
    expect(resource.metadata).to eql("1.2")
  end

  it "should allow you to set the bitmap attribute" do
    resource.bitmap "internal"
    expect(resource.bitmap).to eql("internal")
  end

  it "should allow you to set the devices attribute" do
    resource.devices ["/dev/sda", "/dev/sdb"]
    expect(resource.devices).to eql(["/dev/sda", "/dev/sdb"])
  end

  it "should allow you to set the exists attribute" do
    resource.exists true
    expect(resource.exists).to eql(true)
  end

  it "should have default mdadm_defaults of false" do
    expect(resource.mdadm_defaults).to eq(false)
  end

  it "should have default mdadm_defaults of true in Chef-13", chef: ">= 13" do
    expect(resource.mdadm_defaults).to eq(true)
  end

  describe "when it has devices, level, and chunk" do
    before do
      resource.raid_device("raider")
      resource.devices(%w{device1 device2})
      resource.level(1)
      resource.chunk(42)
    end

    it "describes its state" do
      state = resource.state
      expect(state[:devices]).to eql(%w{device1 device2})
      expect(state[:level]).to eq(1)
      expect(state[:chunk]).to eq(42)
    end

    it "returns the raid device as its identity" do
      expect(resource.identity).to eq("raider")
    end
  end

  describe "deprecation messages about upcoming changes to defaults" do
    it "should display the deprecation message for metadata" do
      resource.chunk(16)
      expect(Chef).to receive(:log_deprecation).with(/metadata/)
      resource.after_created
    end

    it "should display the deprecation message for chunk size" do
      resource.metadata("1.2")
      expect(Chef).to receive(:log_deprecation).with(/chunk/)
      resource.after_created
    end

    it "should not display any warning messages" do
      resource.chunk(16)
      resource.metadata("1.2")
      expect(Chef).to_not receive(:log_deprecation)
      resource.after_created
    end
  end

  describe "mdadm defaults" do
    it "should allow you to enable mdadm_defaults" do
      resource.mdadm_defaults(true)
      expect(resource.mdadm_defaults).to eql(true)
    end

    it "should set chunk to return nil when not explicitly set and mdadm_defaults is true" do
      resource.mdadm_defaults(true)
      resource.after_created
      expect(resource.chunk).to eql(nil)
    end

    it "should set metadata to return nil when not explicitly set and mdadm_defaults is true" do
      resource.mdadm_defaults(true)
      resource.after_created
      expect(resource.metadata).to eql(nil)
    end

    it "should allow chunk to be explicitly set when mdadm_defaults is true" do
      resource.mdadm_defaults(true)
      resource.chunk(256)
      resource.after_created
      expect(resource.chunk).to eql(256)
    end

    it "should allow metadata to be explicitly set when mdadm_defaults is true" do
      resource.mdadm_defaults(true)
      resource.metadata("1.2")
      resource.after_created
      expect(resource.metadata).to eq("1.2")
    end
  end

end
