#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/dsl/reboot_pending"
require "chef/win32/registry"
require "spec_helper"

describe Chef::DSL::RebootPending, :windows_only do
  def run_ohai
    node.consume_external_attrs(OHAI_SYSTEM.data, {})
  end

  let(:node) { Chef::Node.new }
  let!(:ohai) { run_ohai } # Ensure we have necessary node data
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:recipe) { Chef::Recipe.new("a windows cookbook", "the windows recipe", run_context) }
  let(:registry) { Chef::Win32::Registry.new(run_context) }

  describe "reboot_pending?" do
    let(:reg_key) { nil }
    let(:original_set) { false }

    before(:all) { @any_flag = Hash.new }

    after { @any_flag[reg_key] = original_set }

    describe 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations' do
      let(:reg_key) { 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager' }
      let(:original_set) { registry.value_exists?(reg_key, { :name => "PendingFileRenameOperations" }) }

      it "returns true if the registry value exists" do
        skip "found existing registry key" if original_set
        registry.set_value(reg_key,
            { :name => "PendingFileRenameOperations", :type => :multi_string, :data => ['\??\C:\foo.txt|\??\C:\bar.txt'] })

        expect(recipe.reboot_pending?).to be_truthy
      end

      after do
        unless original_set
          registry.delete_value(reg_key, { :name => "PendingFileRenameOperations" })
        end
      end
    end

    describe 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired' do
      let(:reg_key) { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired' }
      let(:original_set) { registry.key_exists?(reg_key) }

      it "returns true if the registry key exists" do
        skip "found existing registry key" if original_set
        pending "Permissions are limited to 'TrustedInstaller' by default"
        registry.create_key(reg_key, false)

        expect(recipe.reboot_pending?).to be_truthy
      end

      after do
        unless original_set
          registry.delete_key(reg_key, false)
        end
      end
    end

    describe 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' do
      let(:reg_key) { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' }
      let(:original_set) { registry.key_exists?(reg_key) }

      it "returns true if the registry key exists" do
        skip "found existing registry key" if original_set
        registry.create_key(reg_key, false)

        expect(recipe.reboot_pending?).to be_truthy
      end

      after do
        unless original_set
          registry.delete_key(reg_key, false)
        end
      end
    end

    describe "when there is nothing to indicate a reboot is pending" do
      it "should return false" do
        skip "reboot pending" if @any_flag.any? { |_, v| v == true }
        expect(recipe.reboot_pending?).to be_falsey
      end
    end
  end
end
