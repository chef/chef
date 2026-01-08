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

WINDOWS_BOOL_HELPERS = %i{windows_server_core? windows_server? windows_workstation?}.freeze

def windows_reports_true_for(*args)
  args.each do |method|
    it "reports true for #{method}" do
      expect(described_class.send(method, node)).to be true
    end
  end
  (WINDOWS_BOOL_HELPERS - args).each do |method|
    it "reports false for #{method}" do
      expect(described_class.send(method, node)).to be false
    end
  end
end

RSpec.describe ChefUtils::DSL::Windows do
  ( HELPER_MODULES - [ described_class ] ).each do |klass|
    it "does not have methods that collide with #{klass}" do
      expect((klass.methods - Module.methods) & WINDOWS_HELPERS).to be_empty
    end
  end

  WINDOWS_HELPERS.each do |helper|
    it "has the #{helper} in the ChefUtils module" do
      expect(ChefUtils).to respond_to(helper)
    end
  end

  context "windows boolean helpers" do
    context "on Windows Server Core" do
      let(:node) { { "kernel" => { "server_core" => true } } }

      windows_reports_true_for(:windows_server_core?)
    end

    context "on Windows Workstation" do
      let(:node) { { "kernel" => { "product_type" => "Workstation" } } }

      windows_reports_true_for(:windows_workstation?)
    end

    context "on Windows Server" do
      let(:node) { { "kernel" => { "product_type" => "Server" } } }

      windows_reports_true_for(:windows_server?)
    end
  end

  context "#windows_nt_version on Windows Server 2012 R2" do
    let(:node) { { "os_version" => "6.3.9600" } }
    it "it returns a ChefUtils::VersionString object with 6.3.9600" do
      expect(described_class.send(:windows_nt_version, node)).to eq "6.3.9600"
      expect(described_class.send(:windows_nt_version, node)).to be_a_kind_of ChefUtils::VersionString
    end
  end

  context "#powershell_version on Windows Server 2012 R2" do
    let(:node) { { "languages" => { "powershell" => { "version" => "4.0" } } } }
    it "it returns a ChefUtils::VersionString object with 4.0" do
      expect(described_class.send(:powershell_version, node)).to eq "4.0"
      expect(described_class.send(:powershell_version, node)).to be_a_kind_of ChefUtils::VersionString
    end
  end
end
