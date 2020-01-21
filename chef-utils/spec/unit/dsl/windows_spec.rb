#
# Copyright:: Copyright 2020, Chef Software Inc.
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

def windows_reports_true_for(*args)
  args.each do |method|
    it "reports true for #{method}" do
      expect(described_class.send(method, node)).to be true
    end
  end
  (WINDOWS_HELPERS - args).each do |method|
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
