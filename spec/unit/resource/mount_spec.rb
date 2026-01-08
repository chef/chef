#
# Author:: Joshua Timberman (<joshua@chef.io>)
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

describe Chef::Resource::Mount do
  let(:resource) { Chef::Resource::Mount.new("fakey_fakerton") }

  it "the mount_point property is the name_property" do
    expect(resource.mount_point).to eql("fakey_fakerton")
  end

  it "sets the default action as :mount" do
    expect(resource.action).to eql([:mount])
  end

  it "supports :disable, :enable, :mount, :remount, :umount, :unmount actions" do
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :mount }.not_to raise_error
    expect { resource.action :remount }.not_to raise_error
    expect { resource.action :umount }.not_to raise_error
    expect { resource.action :unmount }.not_to raise_error
  end

  it "allows you to set the device property" do
    resource.device "/dev/sdb3"
    expect(resource.device).to eql("/dev/sdb3")
  end

  it "allows you to set mount_point property" do
    resource.mount_point "U:"
    expect(resource.mount_point).to eql("U:")
  end

  it "splits strings passed to the mount_point property" do
    resource.mount_point "U:"
    expect(resource.mount_point).to eql("U:")
  end

  it "strips trailing slashes from mount_point values" do
    resource.mount_point "//192.168.11.102/Share/backup/"
    expect(resource.mount_point).to eql("//192.168.11.102/Share/backup")
  end

  it "does not strip slash when mount_point is root directory" do
    resource.mount_point "/"
    expect(resource.mount_point).to eql("/")
  end

  it "does not strip slash when mount_point is root of network mount" do
    resource.mount_point "127.0.0.1:/"
    expect(resource.mount_point).to eql("127.0.0.1:/")
  end

  it "raises error when mount_point property is not set" do
    expect { resource.mount_point nil }.to raise_error(Chef::Exceptions::ValidationFailed, "Property mount_point must be one of: String!  You passed nil.")
  end

  it "sets fsck_device to '-' by default" do
    expect(resource.fsck_device).to eql("-")
  end

  it "allows you to set the fsck_device property" do
    resource.fsck_device "/dev/rdsk/sdb3"
    expect(resource.fsck_device).to eql("/dev/rdsk/sdb3")
  end

  it "allows you to set the fstype property" do
    resource.fstype "nfs"
    expect(resource.fstype).to eql("nfs")
  end

  it "sets fstype to 'auto' by default" do
    expect(resource.fstype).to eql("auto")
  end

  it "allows you to set the dump property" do
    resource.dump 1
    expect(resource.dump).to eql(1)
  end

  it "allows you to set the pass property" do
    resource.pass 1
    expect(resource.pass).to eql(1)
  end

  it "sets the options property to defaults" do
    expect(resource.options).to eql(["defaults"])
  end

  it "allows options to be sent as a string, and convert to array" do
    resource.options "rw,noexec"
    expect(resource.options).to eql(%w{rw noexec})
  end

  it "strips whitespace around options in a comma deliminated string" do
    resource.options "rw, noexec"
    expect(resource.options).to eql(%w{rw noexec})
  end

  it "allows options property as an array" do
    resource.options %w{ro nosuid}
    expect(resource.options).to eql(%w{ro nosuid})
  end

  it "allows options to be sent as a delayed evaluator" do
    resource.options Chef::DelayedEvaluator.new { %w{rw noexec} }
    expect(resource.options).to eql(%w{rw noexec})
  end

  it "allows options to be sent as a delayed evaluator, and convert to array" do
    resource.options Chef::DelayedEvaluator.new { "rw,noexec" }
    expect(resource.options).to eql(%w{rw noexec})
  end

  it "accepts true for mounted" do
    resource.mounted(true)
    expect(resource.mounted).to eql(true)
  end

  it "accepts false for mounted" do
    resource.mounted(false)
    expect(resource.mounted).to eql(false)
  end

  it "sets mounted to false by default" do
    expect(resource.mounted).to eql(false)
  end

  it "does not accept a string for mounted" do
    expect { resource.mounted("poop") }.to raise_error(ArgumentError)
  end

  it "accepts true for enabled" do
    resource.enabled(true)
    expect(resource.enabled).to eql(true)
  end

  it "accepts false for enabled" do
    resource.enabled(false)
    expect(resource.enabled).to eql(false)
  end

  it "sets enabled to false by default" do
    expect(resource.enabled).to eql(false)
  end

  it "does not accept a string for enabled" do
    expect { resource.enabled("poop") }.to raise_error(ArgumentError)
  end

  it "defaults all feature support to false" do
    support_hash = { remount: false }
    expect(resource.supports).to eq(support_hash)
  end

  it "allows you to set feature support as an array" do
    support_array = [ :remount ]
    support_hash = { remount: true }
    resource.supports(support_array)
    expect(resource.supports).to eq(support_hash)
  end

  it "allows you to set feature support as a hash" do
    support_hash = { remount: true }
    resource.supports(support_hash)
    expect(resource.supports).to eq(support_hash)
  end

  it "allows you to set username" do
    resource.username("Administrator")
    expect(resource.username).to eq("Administrator")
  end

  it "allows you to set password" do
    resource.password("Jetstream123!")
    expect(resource.password).to eq("Jetstream123!")
  end

  it "allows you to set domain" do
    resource.domain("TEST_DOMAIN")
    expect(resource.domain).to eq("TEST_DOMAIN")
  end
end
