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
require "fauxhai"

def os_reports_true_for(*args)
  args.each do |method|
    it "reports true for #{method}" do
      expect(described_class.send(method, node)).to be true
    end
  end
  (OS_HELPERS - args).each do |method|
    it "reports false for #{method}" do
      expect(described_class.send(method, node)).to be false
    end
  end
end

RSpec.describe ChefUtils::DSL::OS do
  let(:node) { Fauxhai.mock(options).data }

  ( HELPER_MODULES - [ described_class ] ).each do |klass|
    it "does not have methods that collide with #{klass}" do
      expect((klass.methods - Module.methods) & OS_HELPERS).to be_empty
    end
  end

  OS_HELPERS.each do |helper|
    it "has the #{helper} in the ChefUtils module" do
      expect(ChefUtils).to respond_to(helper)
    end
  end

  context "on ubuntu" do
    let(:options) { { platform: "ubuntu" } }

    os_reports_true_for(:linux?)
  end

  context "on raspbian" do
    let(:options) { { platform: "raspbian" } }

    os_reports_true_for(:linux?)
  end

  context "on linuxmint" do
    let(:options) { { platform: "linuxmint" } }

    os_reports_true_for(:linux?)
  end

  context "on debian" do
    let(:options) { { platform: "debian" } }

    os_reports_true_for(:linux?)
  end

  context "on amazon" do
    let(:options) { { platform: "amazon" } }

    os_reports_true_for(:linux?)
  end

  context "on arch" do
    let(:options) { { platform: "arch" } }

    os_reports_true_for(:linux?)
  end

  context "on centos" do
    let(:options) { { platform: "centos" } }

    os_reports_true_for(:linux?)
  end

  context "on clearos" do
    let(:options) { { platform: "clearos" } }

    os_reports_true_for(:linux?)
  end

  context "on dragonfly4" do
    let(:options) { { platform: "dragonfly4" } }

    os_reports_true_for
  end

  context "on fedora" do
    let(:options) { { platform: "fedora" } }

    os_reports_true_for(:linux?)
  end

  context "on freebsd" do
    let(:options) { { platform: "freebsd" } }

    os_reports_true_for
  end

  context "on gentoo" do
    let(:options) { { platform: "gentoo" } }

    os_reports_true_for(:linux?)
  end

  context "on mac_os_x" do
    let(:options) { { platform: "mac_os_x" } }

    os_reports_true_for(:darwin?)
  end

  context "on openbsd" do
    let(:options) { { platform: "openbsd" } }

    os_reports_true_for
  end

  context "on opensuse" do
    let(:options) { { platform: "opensuse" } }

    os_reports_true_for(:linux?)
  end

  context "on oracle" do
    let(:options) { { platform: "oracle" } }

    os_reports_true_for(:linux?)
  end

  context "on redhat" do
    let(:options) { { platform: "redhat" } }

    os_reports_true_for(:linux?)
  end

  context "on smartos" do
    let(:options) { { platform: "smartos" } }

    os_reports_true_for
  end

  context "on solaris2" do
    let(:options) { { platform: "solaris2" } }

    os_reports_true_for
  end

  context "on suse" do
    let(:options) { { platform: "suse" } }

    os_reports_true_for(:linux?)
  end

  context "on windows" do
    let(:options) { { platform: "windows" } }

    os_reports_true_for
  end
end
