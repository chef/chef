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

describe Chef::Resource::SelinuxInstall do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxInstall.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:install) }

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install, :upgrade, :remove actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :upgrade }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "sets default packages on 'rhel', 'fedora', 'amazon' platforms" do
    node.automatic_attrs[:platform_family] = "rhel"
    expect(resource.packages).to eql(%w{make policycoreutils selinux-policy selinux-policy-targeted selinux-policy-devel libselinux-utils setools-console})
  end

  it "sets default packages on debian irrespective of platform_version" do
    node.automatic_attrs[:platform_family] = "debian"
    expect(resource.packages).to eql(%w{make policycoreutils selinux-basics selinux-policy-default selinux-policy-dev auditd setools})
  end

  it "sets default packages on ubuntu 18.04 platforms" do
    node.automatic_attrs[:platform_family] = "debian"
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = 18.04
    expect(resource.packages).to eql(%w{make policycoreutils selinux selinux-basics selinux-policy-default selinux-policy-dev auditd setools})
  end

  it "sets default packages on ubuntu platforms and versions other than 18.04" do
    node.automatic_attrs[:platform_family] = "debian"
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = 20.04
    expect(resource.packages).to eql(%w{make policycoreutils selinux-basics selinux-policy-default selinux-policy-dev auditd setools})
  end
end
