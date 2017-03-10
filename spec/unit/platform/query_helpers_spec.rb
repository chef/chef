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

require "spec_helper"

describe "Chef::Platform#windows_server_2003?" do
  it "returns false early when not on windows" do
    allow(ChefConfig).to receive(:windows?).and_return(false)
    expect(Chef::Platform).not_to receive(:require)
    expect(Chef::Platform.windows_server_2003?).to be_falsey
  end

  # CHEF-4888: Need to call WIN32OLE.ole_initialize in new threads
  it "does not raise an exception" do
    expect { Thread.fork { Chef::Platform.windows_server_2003? }.join }.not_to raise_error
  end
end

describe "Chef::Platform#windows_nano_server?" do
  include_context "Win32"

  let(:key) { "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Server\\ServerLevels" }
  let(:key_query_value) { 0x0001 }
  let(:access) { key_query_value | 0x0100 }
  let(:hive) { double("Win32::Registry::HKEY_LOCAL_MACHINE") }
  let(:registry) { double("Win32::Registry") }

  before(:all) do
    Win32::Registry = Class.new
    Win32::Registry::Error = Class.new(RuntimeError)
  end

  before do
    Win32::Registry::HKEY_LOCAL_MACHINE = hive
    Win32::Registry::KEY_QUERY_VALUE = key_query_value
  end

  after do
    Win32::Registry.send(:remove_const, "HKEY_LOCAL_MACHINE") if defined?(Win32::Registry::HKEY_LOCAL_MACHINE)
    Win32::Registry.send(:remove_const, "KEY_QUERY_VALUE") if defined?(Win32::Registry::KEY_QUERY_VALUE)
  end

  it "returns false early when not on windows" do
    allow(ChefConfig).to receive(:windows?).and_return(false)
    expect(Chef::Platform).to_not receive(:require)
    expect(Chef::Platform.windows_nano_server?).to be false
  end

  it "returns true when the registry value is 1" do
    allow(ChefConfig).to receive(:windows?).and_return(true)
    allow(Chef::Platform).to receive(:require).with("win32/registry")
    expect(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).
      with(key, access).
      and_yield(registry)
    expect(registry).to receive(:[]).with("NanoServer").and_return(1)
    expect(Chef::Platform.windows_nano_server?).to be true
  end

  it "returns false when the registry value is not 1" do
    allow(ChefConfig).to receive(:windows?).and_return(true)
    allow(Chef::Platform).to receive(:require).with("win32/registry")
    expect(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).
      with(key, access).
      and_yield(registry)
    expect(registry).to receive(:[]).with("NanoServer").and_return(0)
    expect(Chef::Platform.windows_nano_server?).to be false
  end

  it "returns false when the registry value does not exist" do
    allow(ChefConfig).to receive(:windows?).and_return(true)
    allow(Chef::Platform).to receive(:require).with("win32/registry")
    expect(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).
      with(key, access).
      and_yield(registry)
    expect(registry).to receive(:[]).with("NanoServer").
      and_raise(Win32::Registry::Error, "The system cannot find the file specified.")
    expect(Chef::Platform.windows_nano_server?).to be false
  end

  it "returns false when the registry key does not exist" do
    allow(ChefConfig).to receive(:windows?).and_return(true)
    allow(Chef::Platform).to receive(:require).with("win32/registry")
    expect(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).
      with(key, access).
      and_raise(Win32::Registry::Error, "The system cannot find the file specified.")
    expect(Chef::Platform.windows_nano_server?).to be false
  end
end

describe "Chef::Platform#supports_msi?" do
  include_context "Win32" # clear and restore Win32:: namespace

  let(:key) { "System\\CurrentControlSet\\Services\\msiserver" }
  let(:key_query_value) { 0x0001 }
  let(:access) { key_query_value }
  let(:hive) { double("Win32::Registry::HKEY_LOCAL_MACHINE") }
  let(:registry) { double("Win32::Registry") }

  before(:all) do
    Win32::Registry = Class.new
    Win32::Registry::Error = Class.new(RuntimeError)
  end

  before do
    Win32::Registry::HKEY_LOCAL_MACHINE = hive
    Win32::Registry::KEY_QUERY_VALUE = key_query_value
  end

  after do
    Win32::Registry.send(:remove_const, "HKEY_LOCAL_MACHINE") if defined?(Win32::Registry::HKEY_LOCAL_MACHINE)
    Win32::Registry.send(:remove_const, "KEY_QUERY_VALUE") if defined?(Win32::Registry::KEY_QUERY_VALUE)
  end

  it "returns false early when not on windows" do
    allow(ChefConfig).to receive(:windows?).and_return(false)
    expect(Chef::Platform).to_not receive(:require)
    expect(Chef::Platform.supports_msi?).to be false
  end

  it "returns true when the registry key exists" do
    allow(ChefConfig).to receive(:windows?).and_return(true)
    allow(Chef::Platform).to receive(:require).with("win32/registry")
    expect(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).
      with(key, access).
      and_yield(registry)
    expect(Chef::Platform.supports_msi?).to be true
  end

  it "returns false when the registry key does not exist" do
    allow(ChefConfig).to receive(:windows?).and_return(true)
    allow(Chef::Platform).to receive(:require).with("win32/registry")
    expect(Win32::Registry::HKEY_LOCAL_MACHINE).to receive(:open).
      with(key, access).
      and_raise(Win32::Registry::Error, "The system cannot find the file specified.")
    expect(Chef::Platform.supports_msi?).to be false
  end
end

describe "Chef::Platform#supports_dsc?" do
  it "returns false if powershell is not present" do
    node = Chef::Node.new
    expect(Chef::Platform.supports_dsc?(node)).to be_falsey
  end

  ["1.0", "2.0", "3.0"].each do |version|
    it "returns false for Powershell #{version}" do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = version
      expect(Chef::Platform.supports_dsc?(node)).to be_falsey
    end
  end

  ["4.0", "5.0"].each do |version|
    it "returns true for Powershell #{version}" do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = version
      expect(Chef::Platform.supports_dsc?(node)).to be_truthy
    end
  end
end

describe "Chef::Platform#supports_dsc_invoke_resource?" do
  it "returns false if powershell is not present" do
    node = Chef::Node.new
    expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_falsey
  end

  ["1.0", "2.0", "3.0", "4.0", "5.0.10017.9"].each do |version|
    it "returns false for Powershell #{version}" do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = version
      expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_falsey
    end
  end

  it "returns true for Powershell 5.0.10018.0" do
    node = Chef::Node.new
    node.automatic[:languages][:powershell][:version] = "5.0.10018.0"
    expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_truthy
  end
end

describe "Chef::Platform#dsc_refresh_mode_disabled?" do
  let(:node) { instance_double("Chef::Node") }
  let(:cmdlet) { instance_double("Chef::Util::Powershell::Cmdlet") }
  let(:cmdlet_result) { instance_double("Chef::Util::Powershell::CmdletResult") }

  it "returns true when RefreshMode is Disabled" do
    expect(Chef::Util::Powershell::Cmdlet).to receive(:new).
      with(node, "Get-DscLocalConfigurationManager", :object).
      and_return(cmdlet)
    expect(cmdlet).to receive(:run!).and_return(cmdlet_result)
    expect(cmdlet_result).to receive(:return_value).and_return({ "RefreshMode" => "Disabled" })
    expect(Chef::Platform.dsc_refresh_mode_disabled?(node)).to be true
  end

  it "returns false when RefreshMode is not Disabled" do
    expect(Chef::Util::Powershell::Cmdlet).to receive(:new).
      with(node, "Get-DscLocalConfigurationManager", :object).
      and_return(cmdlet)
    expect(cmdlet).to receive(:run!).and_return(cmdlet_result)
    expect(cmdlet_result).to receive(:return_value).and_return({ "RefreshMode" => "LaLaLa" })
    expect(Chef::Platform.dsc_refresh_mode_disabled?(node)).to be false
  end
end
