# frozen_string_literal: true
#
# Copyright:: Copyright (c) Chef Software Inc.
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

def cloud_reports_true_for(*args, node:)
  args.each do |method|
    it "reports true for #{method}" do
      expect(described_class.send(method, node)).to be true
    end
  end
  (CLOUD_HELPERS - args).each do |method|
    it "reports false for #{method}" do
      expect(described_class.send(method, node)).to be false
    end
  end
end

RSpec.describe ChefUtils::DSL::Cloud do
  ( HELPER_MODULES - [ described_class ] ).each do |klass|
    it "does not have methods that collide with #{klass}" do
      expect((klass.methods - Module.methods) & CLOUD_HELPERS).to be_empty
    end
  end

  CLOUD_HELPERS.each do |helper|
    it "has the #{helper} in the ChefUtils module" do
      expect(ChefUtils).to respond_to(helper)
    end
  end

  context "on alibaba" do
    cloud_reports_true_for(:cloud?, :alibaba?, node: { "alibaba" => {}, "cloud" => {} })
  end

  context "on ec2" do
    cloud_reports_true_for(:cloud?, :ec2?, node: { "ec2" => {}, "cloud" => {} })
  end

  context "on gce" do
    cloud_reports_true_for(:cloud?, :gce?, node: { "gce" => {}, "cloud" => {} })
  end

  context "on rackspace" do
    cloud_reports_true_for(:cloud?, :rackspace?, node: { "rackspace" => {}, "cloud" => {} })
  end

  context "on eucalyptus" do
    cloud_reports_true_for(:cloud?, :eucalyptus?, :euca?, node: { "eucalyptus" => {}, "cloud" => {} })
  end

  context "on linode" do
    cloud_reports_true_for(:cloud?, :linode?, node: { "linode" => {}, "cloud" => {} })
  end

  context "on openstack" do
    cloud_reports_true_for(:cloud?, :openstack?, node: { "openstack" => {}, "cloud" => {} })
  end

  context "on azure" do
    cloud_reports_true_for(:cloud?, :azure?, node: { "azure" => {}, "cloud" => {} })
  end

  context "on digital_ocean" do
    cloud_reports_true_for(:cloud?, :digital_ocean?, :digitalocean?, node: { "digital_ocean" => {}, "cloud" => {} })
  end

  context "on softlayer" do
    cloud_reports_true_for(:cloud?, :softlayer?, node: { "softlayer" => {}, "cloud" => {} })
  end

  context "on virtualbox" do
    it "does not return true for cloud?" do
      expect(described_class.cloud?({ "virtualbox" => {}, "cloud" => nil })).to be false
    end
  end
end
