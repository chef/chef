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

  let(:resource) { Chef::Resource::Mdadm.new("fakey_fakerton") }

  it "has a resource name of :mdadm" do
    expect(resource.resource_name).to eql(:mdadm)
  end

  it "the raid_device property is the name_property" do
    expect(resource.raid_device).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :assemble, :create, :stop actions" do
    expect { resource.action :assemble }.not_to raise_error
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :stop }.not_to raise_error
  end

  it "allows you to set the raid_device property" do
    resource.raid_device "/dev/md3"
    expect(resource.raid_device).to eql("/dev/md3")
  end

  it "allows you to set the chunk property" do
    resource.chunk 256
    expect(resource.chunk).to eql(256)
  end

  it "allows you to set the level property" do
    resource.level 1
    expect(resource.level).to eql(1)
  end

  it "allows you to set the metadata property" do
    resource.metadata "1.2"
    expect(resource.metadata).to eql("1.2")
  end

  it "allows you to set the bitmap property" do
    resource.bitmap "internal"
    expect(resource.bitmap).to eql("internal")
  end

  it "allows you to set the layout property" do
    resource.layout "f2"
    expect(resource.layout).to eql("f2")
  end

  it "allows you to set the devices property" do
    resource.devices ["/dev/sda", "/dev/sdb"]
    expect(resource.devices).to eql(["/dev/sda", "/dev/sdb"])
  end

  it "allows you to set the exists property" do
    resource.exists true
    expect(resource.exists).to eql(true)
  end

  describe "when it has devices, level, and chunk" do
    before do
      resource.raid_device("raider")
      resource.devices(%w{device1 device2})
      resource.level(1)
      resource.chunk(42)
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:devices]).to eql(%w{device1 device2})
      expect(state[:level]).to eq(1)
      expect(state[:chunk]).to eq(42)
    end

    it "returns the raid device as its identity" do
      expect(resource.identity).to eq("raider")
    end
  end

end
