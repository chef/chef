#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
    ohai = Ohai::System.new
    # Would be nice to limit this to platform/kernel/arch etc for Ohai 7
    ohai.all_plugins
    node.consume_external_attrs(ohai.data,{})

    ohai
  end

  def registry_safe?
    !registry.value_exists?('HKLM\SYSTEM\CurrentControlSet\Control\Session Manager', { :name => 'PendingFileRenameOperations' }) ||
    !registry.key_exists?('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') ||
    !registry.key_exists?('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired') ||
    !registry.key_exists?('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile')
  end

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let!(:ohai) { run_ohai } # Ensure we have necessary node data
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:recipe) { Chef::Recipe.new("a windows cookbook", "the windows recipe", run_context) }
  let(:registry) { Chef::Win32::Registry.new(run_context) }

  describe "reboot_pending?" do

    describe "when there is nothing to indicate a reboot is pending" do
      it "should return false" do
        pending "Found existing registry keys" unless registry_safe?
        expect(recipe.reboot_pending?).to be_false
      end
    end

    describe 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations' do
      it "returns true if the registry value exists" do
        pending "Found existing registry keys" unless registry_safe?
        registry.set_value('HKLM\SYSTEM\CurrentControlSet\Control\Session Manager', 
            { :name => 'PendingFileRenameOperations', :type => :multi_string, :data => ['\??\C:\foo.txt|\??\C:\bar.txt'] })

        expect(recipe.reboot_pending?).to be_true
      end

      after do
        if registry_safe?
          registry.delete_value('HKLM\SYSTEM\CurrentControlSet\Control\Session Manager', { :name => 'PendingFileRenameOperations' })
        end
      end
    end

    describe 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' do
      it "returns true if the registry key exists" do
        pending "Found existing registry keys" unless registry_safe?
        registry.create_key('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired', false)

        expect(recipe.reboot_pending?).to be_true
      end

      after do
        if registry_safe?
          registry.delete_key('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired', false)
        end
      end
    end

    describe 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired' do
      it "returns true if the registry key exists" do
        pending "Permissions are limited to 'TrustedInstaller' by default"
        pending "Found existing registry keys" unless registry_safe?
        registry.create_key('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired', false)

        expect(recipe.reboot_pending?).to be_true
      end

      after do
        if registry_safe?
          registry.delete_key('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired', false)
        end
      end
    end

    describe 'HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile\Flags' do
      it "returns true if the registry key exists" do
        pending "Found existing registry keys" unless registry_safe?
        registry.create_key('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile', true)
        registry.set_value('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile',
                    { :name => 'Flags', :type => :dword, :data => 3 })

        expect(recipe.reboot_pending?).to be_true
      end

      after do
        if registry_safe?
          registry.delete_value('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile', { :name => 'Flags' })
          registry.delete_key('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile', false)
        end
      end
    end
  end
end
