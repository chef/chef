#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2017, Chef Software Inc.
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

describe Chef::Resource::Mount do
  before(:each) do
    @resource = Chef::Resource::Mount.new("filesystem")
  end

  it "should create a new Chef::Resource::Mount" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Mount)
  end

  it "should have a name" do
    expect(@resource.name).to eql("filesystem")
  end

  it "should set mount_point to the name" do
    expect(@resource.mount_point).to eql("filesystem")
  end

  it "should have a default action of mount" do
    expect(@resource.action).to eql([:mount])
  end

  it "should accept mount, umount, unmount and remount as actions" do
    expect { @resource.action :mount }.not_to raise_error
    expect { @resource.action :umount }.not_to raise_error
    expect { @resource.action :unmount }.not_to raise_error
    expect { @resource.action :remount }.not_to raise_error
    expect { @resource.action :brooklyn }.to raise_error(ArgumentError)
  end

  it "should allow you to set the device attribute" do
    @resource.device "/dev/sdb3"
    expect(@resource.device).to eql("/dev/sdb3")
  end

  it "should set fsck_device to '-' by default" do
    expect(@resource.fsck_device).to eql("-")
  end

  it "should allow you to set the fsck_device attribute" do
    @resource.fsck_device "/dev/rdsk/sdb3"
    expect(@resource.fsck_device).to eql("/dev/rdsk/sdb3")
  end

  it "should allow you to set the fstype attribute" do
    @resource.fstype "nfs"
    expect(@resource.fstype).to eql("nfs")
  end

  it "should allow you to set the dump attribute" do
    @resource.dump 1
    expect(@resource.dump).to eql(1)
  end

  it "should allow you to set the pass attribute" do
    @resource.pass 1
    expect(@resource.pass).to eql(1)
  end

  it "should set the options attribute to defaults" do
    expect(@resource.options).to eql(["defaults"])
  end

  it "should allow options to be sent as a string, and convert to array" do
    @resource.options "rw,noexec"
    expect(@resource.options).to be_a_kind_of(Array)
  end

  it "should allow options attribute as an array" do
    @resource.options %w{ro nosuid}
    expect(@resource.options).to be_a_kind_of(Array)
  end

  it "should allow options to be sent as a delayed evaluator" do
    @resource.options Chef::DelayedEvaluator.new { %w{rw noexec} }
    expect(@resource.options).to eql(%w{rw noexec})
  end

  it "should allow options to be sent as a delayed evaluator, and convert to array" do
    @resource.options Chef::DelayedEvaluator.new { "rw,noexec" }
    expect(@resource.options).to be_a_kind_of(Array)
    expect(@resource.options).to eql(%w{rw noexec})
  end

  it "should accept true for mounted" do
    @resource.mounted(true)
    expect(@resource.mounted).to eql(true)
  end

  it "should accept false for mounted" do
    @resource.mounted(false)
    expect(@resource.mounted).to eql(false)
  end

  it "should set mounted to false by default" do
    expect(@resource.mounted).to eql(false)
  end

  it "should not accept a string for mounted" do
    expect { @resource.mounted("poop") }.to raise_error(ArgumentError)
  end

  it "should accept true for enabled" do
    @resource.enabled(true)
    expect(@resource.enabled).to eql(true)
  end

  it "should accept false for enabled" do
    @resource.enabled(false)
    expect(@resource.enabled).to eql(false)
  end

  it "should set enabled to false by default" do
    expect(@resource.enabled).to eql(false)
  end

  it "should not accept a string for enabled" do
    expect { @resource.enabled("poop") }.to raise_error(ArgumentError)
  end

  it "should default all feature support to false" do
    support_hash = { :remount => false }
    expect(@resource.supports).to eq(support_hash)
  end

  it "should allow you to set feature support as an array" do
    support_array = [ :remount ]
    support_hash = { :remount => true }
    @resource.supports(support_array)
    expect(@resource.supports).to eq(support_hash)
  end

  it "should allow you to set feature support as a hash" do
    support_hash = { :remount => true }
    @resource.supports(support_hash)
    expect(@resource.supports).to eq(support_hash)
  end

  it "should allow you to set username" do
    @resource.username("Administrator")
    expect(@resource.username).to eq("Administrator")
  end

  it "should allow you to set password" do
    @resource.password("Jetstream123!")
    expect(@resource.password).to eq("Jetstream123!")
  end

  it "should allow you to set domain" do
    @resource.domain("TEST_DOMAIN")
    expect(@resource.domain).to eq("TEST_DOMAIN")
  end

  describe "when it has mount point, device type, and fstype" do
    before do
      @resource.device("charmander")
      @resource.mount_point("123.456")
      @resource.device_type(:device)
      @resource.fstype("ranked")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:mount_point]).to eq("123.456")
      expect(state[:device_type]).to eql(:device)
      expect(state[:fstype]).to eq("ranked")
    end

    it "returns the device as its identity" do
      expect(@resource.identity).to eq("charmander")
    end
  end

  describe "when it has username, password and domain" do
    before do
      @resource.mount_point("T:")
      @resource.device("charmander")
      @resource.username("Administrator")
      @resource.password("Jetstream123!")
      @resource.domain("TEST_DOMAIN")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:mount_point]).to eq("T:")
      expect(state[:username]).to eq("Administrator")
      expect(state[:password]).to eq("Jetstream123!")
      expect(state[:domain]).to eq("TEST_DOMAIN")
      expect(state[:device_type]).to eql(:device)
      expect(state[:fstype]).to eq("auto")
    end

  end
end
