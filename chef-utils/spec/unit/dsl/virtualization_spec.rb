#
# Copyright:: Copyright 2018-2020, Chef Software Inc.
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
require "fauxhai"

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

  context "on kvm" do
    virtualization_reports_true_for(:virtual?, :kvm?, node: { "virtualization" => { "system" => "kvm" } })
  end
  context "on lxc" do
    virtualization_reports_true_for(:virtual?, :lxc?, node: { "virtualization" => { "system" => "lxc" } })
  end
  context "on parallels" do
    virtualization_reports_true_for(:virtual?, :parallels?, node: { "virtualization" => { "system" => "parallels" } })
  end
  context "on virtualbox" do
    virtualization_reports_true_for(:virtual?, :virtualbox?, :vbox?, node: { "virtualization" => { "system" => "vbox" } })
  end
  context "on vmware" do
    virtualization_reports_true_for(:virtual?, :vmware?, node: { "virtualization" => { "system" => "vmware" } })
  end
  context "on openvz" do
    virtualization_reports_true_for(:virtual?, :openvz?, node: { "virtualization" => { "system" => "openvz" } })
  end
  context "on anything else" do
    virtualization_reports_true_for(:physical?, node: {} )
  end
end
