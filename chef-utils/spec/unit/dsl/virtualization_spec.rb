# frozen_string_literal: true
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

def virtualization_reports_true_for(*args, node:)
  args.each do |method|
    it "reports true for #{method}" do
      expect(described_class.send(method, node)).to be true
    end
  end
  (VIRTUALIZATION_HELPERS - args).each do |method|
    it "reports false for #{method}" do
      expect(described_class.send(method, node)).to be false
    end
  end
end

RSpec.describe ChefUtils::DSL::Virtualization do
  ( HELPER_MODULES - [ described_class ] ).each do |klass|
    it "does not have methods that collide with #{klass}" do
      expect((klass.methods - Module.methods) & VIRTUALIZATION_HELPERS).to be_empty
    end
  end

  VIRTUALIZATION_HELPERS.each do |helper|
    it "has the #{helper} in the ChefUtils module" do
      expect(ChefUtils).to respond_to(helper)
    end
  end

  context "on hyperv" do
    virtualization_reports_true_for(:guest?, :virtual?, :hyperv?, node: { "virtualization" => { "system" => "hyperv", "role" => "guest" } })
  end
  context "on kvm" do
    virtualization_reports_true_for(:guest?, :virtual?, :kvm?, node: { "virtualization" => { "system" => "kvm",  "role" => "guest" } })
    virtualization_reports_true_for(:hypervisor?, :physical?, :kvm_host?, node: { "virtualization" => { "system" => "kvm", "role" => "host" } })
  end
  context "on lxc" do
    virtualization_reports_true_for(:guest?, :virtual?, :lxc?, node: { "virtualization" => { "system" => "lxc", "role" => "guest" } })
    virtualization_reports_true_for(:hypervisor?, :physical?, :lxc_host?, node: { "virtualization" => { "system" => "lxc", "role" => "host" } })
  end
  context "on parallels" do
    virtualization_reports_true_for(:guest?, :virtual?, :parallels?, node: { "virtualization" => { "system" => "parallels", "role" => "guest" } })
    virtualization_reports_true_for(:hypervisor?, :physical?, :parallels_host?, node: { "virtualization" => { "system" => "parallels", "role" => "host" } })
  end
  context "on virtualbox" do
    virtualization_reports_true_for(:guest?, :virtual?, :virtualbox?, :vbox?, node: { "virtualization" => { "system" => "vbox", "role" => "guest" } })
    virtualization_reports_true_for(:hypervisor?, :physical?, :vbox_host?, node: { "virtualization" => { "system" => "vbox", "role" => "host" } })
  end
  context "on vmware" do
    virtualization_reports_true_for(:guest?, :virtual?, :vmware?, node: { "virtualization" => { "system" => "vmware", "role" => "guest" } })
    virtualization_reports_true_for(:hypervisor?, :physical?, :vmware_host?, node: { "virtualization" => { "system" => "vmware", "role" => "host" } })
  end
  context "on openvz" do
    virtualization_reports_true_for(:guest?, :virtual?, :openvz?, node: { "virtualization" => { "system" => "openvz", "role" => "guest" } })
    virtualization_reports_true_for(:hypervisor?, :physical?, :openvz_host?, node: { "virtualization" => { "system" => "openvz", "role" => "host" } })
  end
  context "on metal which is not a virt host" do
    virtualization_reports_true_for(:physical?, node: {} )
  end
end
