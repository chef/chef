#
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

describe Chef::Resource::Sudo do

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::Sudo.new("fakey_fakerton", run_context) }

  it "has a resource name of :sudo" do
    expect(resource.resource_name).to eql(:sudo)
  end

  it "the filename property is the name_property" do
    expect(resource.filename).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete, :install, :remove actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "coerces filename property values . & ~ to __" do
    resource.filename "something.something~"
    expect(resource.filename).to eql("something__something__")
  end

  it "supports the legacy 'user' property" do
    resource.user ["foo"]
    expect(resource.users).to eql(["foo"])
  end

  it "supports the legacy 'groups' property" do
    resource.group ["%foo"]
    expect(resource.groups).to eql(["%foo"])
  end

  it "coerces users & groups String vals to Arrays" do
    resource.users "something"
    resource.groups "%something"
    expect(resource.users).to eql(["something"])
    expect(resource.groups).to eql(["%something"])
  end

  it "coerces users & group String vals no matter the spacing" do
    resource.users "user1, user2 , user3 ,user4"
    resource.groups "group1, group2 , group3 ,group4"
    expect(resource.users).to eql(%w{user1 user2 user3 user4})
    expect(resource.groups).to eql(["%group1", "%group2", "%group3", "%group4"])
  end

  it "coerces groups values to properly start with %" do
    resource.groups ["foo", "%bar"]
    expect(resource.groups).to eql(["%foo", "%bar"])
  end

  it "it sets the config prefix to /etc on linux" do
    node.automatic[:platform_family] = "debian"
    expect(resource.config_prefix).to eql("/etc")
  end

  it "it sets the config prefix to /private/etc on macOS" do
    node.automatic[:platform_family] = "mac_os_x"
    expect(resource.config_prefix).to eql("/private/etc")
  end

  it "it sets the config prefix to /usr/local/etc on FreeBSD" do
    node.automatic[:platform_family] = "freebsd"
    expect(resource.config_prefix).to eql("/usr/local/etc")
  end

  it "it sets the config prefix to /opt/local/etc on smartos" do
    node.automatic[:platform_family] = "smartos"
    expect(resource.config_prefix).to eql("/opt/local/etc")
  end
end
