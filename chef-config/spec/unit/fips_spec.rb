#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

require "chef-config/fips"
require "spec_helper"

RSpec.describe "ChefConfig.fips?" do
  let(:enabled) { "0" }

  context "on *nix" do
    let(:fips_path) { "/proc/sys/crypto/fips_enabled" }

    before(:each) do
      allow(ChefConfig).to receive(:windows?).and_return(false)
      allow(::File).to receive(:exist?).with(fips_path).and_return(true)
      allow(::File).to receive(:read).with(fips_path).and_return(enabled)
    end

    context "fips file is present and contains 1" do
      let(:enabled) { "1" }

      it "returns true" do
        expect(ChefConfig.fips?).to be(true)
      end
    end

    context "fips file does not contain 1" do
      let(:enabled) { "0" }

      it "returns false" do
        expect(ChefConfig.fips?).to be(false)
      end
    end

    context "fips file is not present" do
      before do
        allow(::File).to receive(:exist?).with(fips_path).and_return(false)
      end

      it "returns false" do
        expect(ChefConfig.fips?).to be(false)
      end
    end
  end

  context "on windows", :windows_only do
    let(:fips_key) { 'System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy' }
    let(:win_reg_entry) { { "Enabled" => enabled } }

    before(:each) do
      allow(ChefConfig).to receive(:windows?).and_return(true)
      allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).with(fips_key, arch).and_yield(win_reg_entry)
    end

    shared_examples "fips_detection" do
      context "fips enabled key is set to 1" do
        let(:enabled) { 1 }

        it "returns true" do
          expect(ChefConfig.fips?).to be(true)
        end
      end

      context "fips enabled key is set to 0" do
        let(:enabled) { 0 }

        it "returns false" do
          expect(ChefConfig.fips?).to be(false)
        end
      end

      context "fips key does not exist" do
        before do
          allow(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).and_raise(Win32::Registry::Error, 50)
        end

        it "returns false" do
          expect(ChefConfig.fips?).to be(false)
        end
      end
    end

    context "on 32 bit ruby" do
      let(:arch) { Win32::Registry::KEY_READ | 0x100 }

      before { stub_const("::RbConfig::CONFIG", { "target_cpu" => "i386" } ) }

      it_behaves_like "fips_detection"
    end

    context "on 64 bit ruby" do
      let(:arch) { Win32::Registry::KEY_READ | 0x200 }

      before { stub_const("::RbConfig::CONFIG", { "target_cpu" => "x86_64" } ) }

      it_behaves_like "fips_detection"
    end

    context "on unknown ruby" do
      let(:arch) { Win32::Registry::KEY_READ }

      before { stub_const("::RbConfig::CONFIG", { "target_cpu" => nil } ) }

      it_behaves_like "fips_detection"
    end
  end
end
