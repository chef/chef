#
# Author:: Prajakta Purohit (<prajakta@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
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

require "chef/win32/registry"
require "chef/resource_reporter"
require "spec_helper"

describe Chef::Resource::RegistryKey, :unix_only do
  before(:all) do
    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    node.consume_external_attrs(ohai.data, {})
    run_context = Chef::RunContext.new(node, {}, events)
    @resource = Chef::Resource::RegistryKey.new("HKCU\\Software", run_context)
  end
  context "when load_current_resource is run on a non-windows node" do
    it "throws an exception because you don't have a windows registry (derp)" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{ name: "Color", type: :string, data: "Orange" }])
      expect { @resource.run_action(:create) }.to raise_error(Chef::Exceptions::Win32NotWindows)
    end
  end
end

describe Chef::Resource::RegistryKey, :windows_only, broken: true do

  # parent and key must be single keys, not paths
  let(:parent) { "Opscode" }
  let(:child) { "Whatever" }
  let(:key_parent) { "SOFTWARE\\" + parent }
  let(:key_child) { "SOFTWARE\\" + parent + "\\" + child }
  # must be under HKLM\SOFTWARE for WOW64 redirection to work
  let(:reg_parent) { "HKLM\\" + key_parent }
  let(:reg_child) { "HKLM\\" + key_child }
  let(:hive_class) { ::Win32::Registry::HKEY_LOCAL_MACHINE }
  let(:resource_name) { "This is the name of my Resource" }

  def clean_registry
    if windows64?
      # clean 64-bit space on WOW64
      @registry.architecture = :x86_64
      @registry.delete_key(reg_parent, true)
      @registry.architecture = :machine
    end
    # clean 32-bit space on WOW64
    @registry.architecture = :i386
    @registry.delete_key(reg_parent, true)
    @registry.architecture = :machine
  end

  def reset_registry
    clean_registry
    hive_class.create(key_parent, Win32::Registry::KEY_WRITE | 0x0100)
    hive_class.create(key_parent, Win32::Registry::KEY_WRITE | 0x0200)
  end

  def create_deletable_keys
    # create them both 32-bit and 64-bit
    [ 0x0100, 0x0200 ].each do |flag|
      hive_class.create(key_parent + '\Opscode', Win32::Registry::KEY_WRITE | flag)
      hive_class.open(key_parent + '\Opscode', Win32::Registry::KEY_ALL_ACCESS | flag) do |reg|
        reg["Color", Win32::Registry::REG_SZ] = "Orange"
        reg.write("Opscode", Win32::Registry::REG_MULTI_SZ, %w{Seattle Washington})
        reg["AKA", Win32::Registry::REG_SZ] = "OC"
      end
      hive_class.create(key_parent + '\ReportKey', Win32::Registry::KEY_WRITE | flag)
      hive_class.open(key_parent + '\ReportKey', Win32::Registry::KEY_ALL_ACCESS | flag) do |reg|
        reg["ReportVal4", Win32::Registry::REG_SZ] = "report4"
        reg["ReportVal5", Win32::Registry::REG_SZ] = "report5"
      end
      hive_class.create(key_parent + '\OpscodeWhyRun', Win32::Registry::KEY_WRITE | flag)
      hive_class.open(key_parent + '\OpscodeWhyRun', Win32::Registry::KEY_ALL_ACCESS | flag) do |reg|
        reg["BriskWalk", Win32::Registry::REG_SZ] = "is good for health"
      end
    end
  end

  before(:all) do
    @events = Chef::EventDispatch::Dispatcher.new
    @node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    @node.consume_external_attrs(ohai.data, {})
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::RegistryKey.new(resource_name, @run_context)
    @registry = Chef::Win32::Registry.new(@run_context)

    reset_registry
  end

  # Reporting setup
  before do
    @node.name("windowsbox")

    @rest_client = double("Chef::ServerAPI (mock)")
    allow(@rest_client).to receive(:create_url).and_return("reports/nodes/windowsbox/runs/#{@run_id}")
    allow(@rest_client).to receive(:raw_http_request).and_return({ "result" => "ok" })
    allow(@rest_client).to receive(:post_rest).and_return({ "uri" => "https://example.com/reports/nodes/windowsbox/runs/#{@run_id}" })

    @resource_reporter = Chef::ResourceReporter.new(@rest_client)
    @events.register(@resource_reporter)
    @run_status = Chef::RunStatus.new(@node, @events)
    @resource_reporter.run_started(@run_status)
    @run_id = @resource_reporter.run_id

    @new_resource.cookbook_name = "monkey"
    @cookbook_version = double("Cookbook::Version", version: "1.2.3")
    @new_resource.cookbook_version(@cookbook_version)
  end

  after(:all) do
    clean_registry
  end

  context "when action is create" do
    before(:all) do
      reset_registry
    end
    it "creates registry key, value if the key is missing" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Color", type: :string, data: "Orange" }])
      @new_resource.run_action(:create)

      expect(@registry.key_exists?(reg_child)).to eq(true)
      expect(@registry.data_exists?(reg_child, { name: "Color", type: :string, data: "Orange" })).to eq(true)
    end

    it "does not create the key if it already exists with same value, type and data" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Color", type: :string, data: "Orange" }])
      @new_resource.run_action(:create)

      expect(@registry.key_exists?(reg_child)).to eq(true)
      expect(@registry.data_exists?(reg_child, { name: "Color", type: :string, data: "Orange" })).to eq(true)
    end

    it "does not create the key if it already exists with same value and type but datatype of data differs" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "number", type: :dword, data: "12345" }])
      @new_resource.run_action(:create)

      expect(@new_resource).not_to be_updated_by_last_action
      expect(@registry.key_exists?(reg_child)).to eq(true)
      expect(@registry.data_exists?(reg_child, { name: "number", type: :dword, data: 12344 })).to eq(true)
    end

    it "creates a value if it does not exist" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Mango", type: :string, data: "Yellow" }])
      @new_resource.run_action(:create)

      expect(@registry.data_exists?(reg_child, { name: "Mango", type: :string, data: "Yellow" })).to eq(true)
    end

    it "modifies the data if the key and value exist and type matches" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Color", type: :string, data: "Not just Orange - OpscodeOrange!" }])
      @new_resource.run_action(:create)

      expect(@registry.data_exists?(reg_child, { name: "Color", type: :string, data: "Not just Orange - OpscodeOrange!" })).to eq(true)
    end

    it "modifys the type if the key and value exist and the type does not match" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Color", type: :multi_string, data: ["Not just Orange - OpscodeOrange!"] }])
      @new_resource.run_action(:create)

      expect(@registry.data_exists?(reg_child, { name: "Color", type: :multi_string, data: ["Not just Orange - OpscodeOrange!"] })).to eq(true)
    end

    it "creates subkey if parent exists" do
      @new_resource.key(reg_child + '\OpscodeTest')
      @new_resource.values([{ name: "Chef", type: :multi_string, data: %w{OpscodeOrange Rules} }])
      @new_resource.recursive(false)
      @new_resource.run_action(:create)

      expect(@registry.key_exists?(reg_child + '\OpscodeTest')).to eq(true)
      expect(@registry.value_exists?(reg_child + '\OpscodeTest', { name: "Chef", type: :multi_string, data: %w{OpscodeOrange Rules} })).to eq(true)
    end

    it "raises an error if action create and parent does not exist and recursive is set to false" do
      @new_resource.key(reg_child + '\Missing1\Missing2')
      @new_resource.values([{ name: "OC", type: :string, data: "MissingData" }])
      @new_resource.recursive(false)
      expect { @new_resource.run_action(:create) }.to raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "raises an error if action create and type key missing in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC", data: "my_data" }])
      expect { @new_resource.run_action(:create) }.to raise_error(Chef::Exceptions::RegKeyValuesTypeMissing)
    end

    it "raises an error if action create and data key missing in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC", type: :string }])
      expect { @new_resource.run_action(:create) }.to raise_error(Chef::Exceptions::RegKeyValuesDataMissing)
    end

    it "raises an error if action create and only name key present in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC" }])
      expect { @new_resource.run_action(:create) }.to raise_error(Chef::Exceptions::RegKeyValuesTypeMissing)
    end

    it "does not raise an error if action create and all keys are present in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC", type: :string, data: "my_data" }])
      expect { @new_resource.run_action(:create) }.to_not raise_error
    end

    it "creates missing keys if action create and parent does not exist and recursive is set to true" do
      @new_resource.key(reg_child + '\Missing1\Missing2')
      @new_resource.values([{ name: "OC", type: :string, data: "MissingData" }])
      @new_resource.recursive(true)
      @new_resource.run_action(:create)

      expect(@registry.key_exists?(reg_child + '\Missing1\Missing2')).to eq(true)
      expect(@registry.value_exists?(reg_child + '\Missing1\Missing2', { name: "OC", type: :string, data: "MissingData" })).to eq(true)
    end

    it "creates key with multiple value as specified" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "one", type: :string, data: "1" }, { name: "two", type: :string, data: "2" }, { name: "three", type: :string, data: "3" }])
      @new_resource.recursive(true)
      @new_resource.run_action(:create)

      @new_resource.each_value do |value|
        expect(@registry.value_exists?(reg_child, value)).to eq(true)
      end
    end

    context "when running on 64-bit server", :windows64_only do
      before(:all) do
        reset_registry
      end
      after(:all) do
        @new_resource.architecture(:machine)
        @registry.architecture = :machine
      end
      it "creates a key in a 32-bit registry that is not viewable in 64-bit" do
        @new_resource.key(reg_child + '\Atraxi' )
        @new_resource.values([{ name: "OC", type: :string, data: "Data" }])
        @new_resource.recursive(true)
        @new_resource.architecture(:i386)
        @new_resource.run_action(:create)
        @registry.architecture = :i386
        expect(@registry.data_exists?(reg_child + '\Atraxi', { name: "OC", type: :string, data: "Data" })).to eq(true)
        @registry.architecture = :x86_64
        expect(@registry.key_exists?(reg_child + '\Atraxi')).to eq(false)
      end
    end

    it "prepares the reporting data for action :create" do
      @new_resource.key(reg_child + '\Ood')
      @new_resource.values([{ name: "ReportingVal1", type: :string, data: "report1" }, { name: "ReportingVal2", type: :string, data: "report2" }])
      @new_resource.recursive(true)
      @new_resource.run_action(:create)
      @report = @resource_reporter.prepare_run_data

      expect(@report["action"]).to eq("end")
      expect(@report["resources"][0]["type"]).to eq("registry_key")
      expect(@report["resources"][0]["name"]).to eq(resource_name)
      expect(@report["resources"][0]["id"]).to eq(reg_child + '\Ood')
      expect(@report["resources"][0]["after"][:values]).to eq([{ name: "ReportingVal1", type: :string, data: "report1" },
                                                           { name: "ReportingVal2", type: :string, data: "report2" }])
      expect(@report["resources"][0]["before"][:values]).to eq([])
      expect(@report["resources"][0]["result"]).to eq("create")
      expect(@report["status"]).to eq("success")
      expect(@report["total_res_count"]).to eq("1")
    end

    context "while running in whyrun mode" do
      before(:each) do
        Chef::Config[:why_run] = true
      end

      it "does not raise an exception if the keys do not exist but recursive is set to false" do
        @new_resource.key(reg_child + '\Slitheen\Raxicoricofallapatorius')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "is good for health" }])
        @new_resource.recursive(false)
        @new_resource.run_action(:create) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Slitheen')).to eq(false)
        expect(@registry.key_exists?(reg_child + '\Slitheen\Raxicoricofallapatorius')).to eq(false)
      end

      it "does not create key if the action is create" do
        @new_resource.key(reg_child + '\Slitheen')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "is good for health" }])
        @new_resource.recursive(false)
        @new_resource.run_action(:create)
        expect(@registry.key_exists?(reg_child + '\Slitheen')).to eq(false)
      end

      it "does not raise an exception if the action create and type key missing in values hash" do
        @new_resource.key(reg_child + '\Slitheen')
        @new_resource.values([{ name: "BriskWalk", data: "my_data" }])
        @new_resource.run_action(:create) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Slitheen')).to eq(false)
      end

      it "does not raise an exception if the action create and data key missing in values hash" do
        @new_resource.key(reg_child + '\Slitheen')
        @new_resource.values([{ name: "BriskWalk", type: :string }])
        @new_resource.run_action(:create) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Slitheen')).to eq(false)
      end

      it "does not raise an exception if the action create and only name key present in values hash" do
        @new_resource.key(reg_child + '\Slitheen')
        @new_resource.values([{ name: "BriskWalk" }])
        @new_resource.run_action(:create) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Slitheen')).to eq(false)
      end

      it "does not raise an exception if the action create and all keys are present in values hash" do
        @new_resource.key(reg_child + '\Slitheen')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "my_data" }])
        @new_resource.run_action(:create) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Slitheen')).to eq(false)
      end
    end
  end

  context "when action is create_if_missing" do
    before(:all) do
      reset_registry
    end

    it "creates registry key, value if the key is missing" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Color", type: :string, data: "Orange" }])
      @new_resource.run_action(:create_if_missing)

      expect(@registry.key_exists?(reg_parent)).to eq(true)
      expect(@registry.key_exists?(reg_child)).to eq(true)
      expect(@registry.data_exists?(reg_child, { name: "Color", type: :string, data: "Orange" })).to eq(true)
    end

    it "does not create the key if it already exists with same value, type and data" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Color", type: :string, data: "Orange" }])
      @new_resource.run_action(:create_if_missing)

      expect(@registry.key_exists?(reg_child)).to eq(true)
      expect(@registry.data_exists?(reg_child, { name: "Color", type: :string, data: "Orange" })).to eq(true)
    end

    it "creates a value if it does not exist" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "Mango", type: :string, data: "Yellow" }])
      @new_resource.run_action(:create_if_missing)

      expect(@registry.data_exists?(reg_child, { name: "Mango", type: :string, data: "Yellow" })).to eq(true)
    end

    it "creates subkey if parent exists" do
      @new_resource.key(reg_child + '\Pyrovile')
      @new_resource.values([{ name: "Chef", type: :multi_string, data: %w{OpscodeOrange Rules} }])
      @new_resource.recursive(false)
      @new_resource.run_action(:create_if_missing)

      expect(@registry.key_exists?(reg_child + '\Pyrovile')).to eq(true)
      expect(@registry.value_exists?(reg_child + '\Pyrovile', { name: "Chef", type: :multi_string, data: %w{OpscodeOrange Rules} })).to eq(true)
    end

    it "raises an error if action create and parent does not exist and recursive is set to false" do
      @new_resource.key(reg_child + '\Sontaran\Sontar')
      @new_resource.values([{ name: "OC", type: :string, data: "MissingData" }])
      @new_resource.recursive(false)
      expect { @new_resource.run_action(:create_if_missing) }.to raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "raises an error if action create_if_missing and type key missing in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC", data: "my_data" }])
      expect { @new_resource.run_action(:create_if_missing) }.to raise_error(Chef::Exceptions::RegKeyValuesTypeMissing)
    end

    it "raises an error if action create_if_missing and data key missing in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC", type: :string }])
      expect { @new_resource.run_action(:create_if_missing) }.to raise_error(Chef::Exceptions::RegKeyValuesDataMissing)
    end

    it "raises an error if action create_if_missing and only name key present in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC" }])
      expect { @new_resource.run_action(:create_if_missing) }.to raise_error(Chef::Exceptions::RegKeyValuesTypeMissing)
    end

    it "does not raise an error if action create_if_missing and all keys are present in values hash" do
      @new_resource.key(reg_child)
      @new_resource.values([{ name: "OC", type: :string, data: "my_data" }])
      expect { @new_resource.run_action(:create_if_missing) }.to_not raise_error
    end

    it "creates missing keys if action create and parent does not exist and recursive is set to true" do
      @new_resource.key(reg_child + '\Sontaran\Sontar')
      @new_resource.values([{ name: "OC", type: :string, data: "MissingData" }])
      @new_resource.recursive(true)
      @new_resource.run_action(:create_if_missing)

      expect(@registry.key_exists?(reg_child + '\Sontaran\Sontar')).to eq(true)
      expect(@registry.value_exists?(reg_child + '\Sontaran\Sontar', { name: "OC", type: :string, data: "MissingData" })).to eq(true)
    end

    it "creates key with multiple value as specified" do
      @new_resource.key(reg_child + '\Adipose')
      @new_resource.values([{ name: "one", type: :string, data: "1" }, { name: "two", type: :string, data: "2" }, { name: "three", type: :string, data: "3" }])
      @new_resource.recursive(true)
      @new_resource.run_action(:create_if_missing)

      @new_resource.each_value do |value|
        expect(@registry.value_exists?(reg_child + '\Adipose', value)).to eq(true)
      end
    end

    it "prepares the reporting data for :create_if_missing" do
      @new_resource.key(reg_child + '\Judoon')
      @new_resource.values([{ name: "ReportingVal3", type: :string, data: "report3" }])
      @new_resource.recursive(true)
      @new_resource.run_action(:create_if_missing)
      @report = @resource_reporter.prepare_run_data

      expect(@report["action"]).to eq("end")
      expect(@report["resources"][0]["type"]).to eq("registry_key")
      expect(@report["resources"][0]["name"]).to eq(resource_name)
      expect(@report["resources"][0]["id"]).to eq(reg_child + '\Judoon')
      expect(@report["resources"][0]["after"][:values]).to eq([{ name: "ReportingVal3", type: :string, data: "report3" }])
      expect(@report["resources"][0]["before"][:values]).to eq([])
      expect(@report["resources"][0]["result"]).to eq("create_if_missing")
      expect(@report["status"]).to eq("success")
      expect(@report["total_res_count"]).to eq("1")
    end

    context "while running in whyrun mode" do
      before(:each) do
        Chef::Config[:why_run] = true
      end

      it "does not raise an exception if the keys do not exist but recursive is set to false" do
        @new_resource.key(reg_child + '\Zygons\Zygor')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "is good for health" }])
        @new_resource.recursive(false)
        @new_resource.run_action(:create_if_missing) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Zygons')).to eq(false)
        expect(@registry.key_exists?(reg_child + '\Zygons\Zygor')).to eq(false)
      end

      it "does nothing if the action is create_if_missing" do
        @new_resource.key(reg_child + '\Zygons')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "is good for health" }])
        @new_resource.recursive(false)
        @new_resource.run_action(:create_if_missing)
        expect(@registry.key_exists?(reg_child + '\Zygons')).to eq(false)
      end

      it "does not raise an exception if the action create_if_missing and type key missing in values hash" do
        @new_resource.key(reg_child + '\Zygons')
        @new_resource.values([{ name: "BriskWalk", data: "my_data" }])
        @new_resource.run_action(:create_if_missing) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Zygons')).to eq(false)
      end

      it "does not raise an exception if the action create_if_missing and data key missing in values hash" do
        @new_resource.key(reg_child + '\Zygons')
        @new_resource.values([{ name: "BriskWalk", type: :string }])
        @new_resource.run_action(:create_if_missing) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Zygons')).to eq(false)
      end

      it "does not raise an exception if the action create_if_missing and only name key present in values hash" do
        @new_resource.key(reg_child + '\Zygons')
        @new_resource.values([{ name: "BriskWalk" }])
        @new_resource.run_action(:create_if_missing) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Zygons')).to eq(false)
      end

      it "does not raise an exception if the action create_if_missing and all keys are present in values hash" do
        @new_resource.key(reg_child + '\Zygons')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "my_data" }])
        @new_resource.run_action(:create_if_missing) # should not raise_error
        expect(@registry.key_exists?(reg_child + '\Zygons')).to eq(false)
      end
    end
  end

  context "when the action is delete" do
    before(:all) do
      reset_registry
      create_deletable_keys
    end

    it "takes no action if the specified key path does not exist in the system" do
      expect(@registry.key_exists?(reg_parent + '\Osirian')).to eq(false)

      @new_resource.key(reg_parent + '\Osirian')
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      expect(@registry.key_exists?(reg_parent + '\Osirian')).to eq(false)
    end

    it "takes no action if the key exists but the value does not" do
      expect(@registry.data_exists?(reg_parent + '\Opscode', { name: "Color", type: :string, data: "Orange" })).to eq(true)

      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.values([{ name: "LooksLike", type: :multi_string, data: %w{SeattleGrey OCOrange} }])
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      expect(@registry.data_exists?(reg_parent + '\Opscode', { name: "Color", type: :string, data: "Orange" })).to eq(true)
    end

    it "deletes only specified values under a key path" do
      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.values([{ name: "Opscode", type: :multi_string, data: %w{Seattle Washington} }, { name: "AKA", type: :string, data: "OC" }])
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      expect(@registry.data_exists?(reg_parent + '\Opscode', { name: "Color", type: :string, data: "Orange" })).to eq(true)
      expect(@registry.value_exists?(reg_parent + '\Opscode', { name: "AKA", type: :string, data: "OC" })).to eq(false)
      expect(@registry.value_exists?(reg_parent + '\Opscode', { name: "Opscode", type: :multi_string, data: %w{Seattle Washington} })).to eq(false)
    end

    it "it deletes the values with the same name irrespective of it type and data" do
      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.values([{ name: "Color", type: :multi_string, data: %w{Black Orange} }])
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      expect(@registry.value_exists?(reg_parent + '\Opscode', { name: "Color", type: :string, data: "Orange" })).to eq(false)
    end

    it "prepares the reporting data for action :delete" do
      @new_resource.key(reg_parent + '\ReportKey')
      @new_resource.values([{ name: "ReportVal4", type: :string, data: "report4" }, { name: "ReportVal5", type: :string, data: "report5" }])
      @new_resource.recursive(true)
      @new_resource.run_action(:delete)

      @report = @resource_reporter.prepare_run_data

      expect(@registry.value_exists?(reg_parent + '\ReportKey', [{ name: "ReportVal4", type: :string, data: "report4" }, { name: "ReportVal5", type: :string, data: "report5" }])).to eq(false)

      expect(@report["action"]).to eq("end")
      expect(@report["resources"].count).to eq(1)
      expect(@report["resources"][0]["type"]).to eq("registry_key")
      expect(@report["resources"][0]["name"]).to eq(resource_name)
      expect(@report["resources"][0]["id"]).to eq(reg_parent + '\ReportKey')
      expect(@report["resources"][0]["before"][:values]).to eq([{ name: "ReportVal4", type: :string, data: "report4" },
                                                            { name: "ReportVal5", type: :string, data: "report5" }])
      # Not testing for after values to match since after -> new_resource values.
      expect(@report["resources"][0]["result"]).to eq("delete")
      expect(@report["status"]).to eq("success")
      expect(@report["total_res_count"]).to eq("1")
    end

    context "while running in whyrun mode" do
      before(:each) do
        Chef::Config[:why_run] = true
      end
      it "does nothing if the action is delete" do
        @new_resource.key(reg_parent + '\OpscodeWhyRun')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "is good for health" }])
        @new_resource.recursive(false)
        @new_resource.run_action(:delete)

        expect(@registry.key_exists?(reg_parent + '\OpscodeWhyRun')).to eq(true)
      end
    end
  end

  context "when the action is delete_key" do
    before(:all) do
      reset_registry
      create_deletable_keys
    end

    it "takes no action if the specified key path does not exist in the system" do
      expect(@registry.key_exists?(reg_parent + '\Osirian')).to eq(false)

      @new_resource.key(reg_parent + '\Osirian')
      @new_resource.recursive(false)
      @new_resource.run_action(:delete_key)

      expect(@registry.key_exists?(reg_parent + '\Osirian')).to eq(false)
    end

    it "deletes key if it has no subkeys and recursive == false" do
      @new_resource.key(reg_parent + '\OpscodeTest')
      @new_resource.recursive(false)
      @new_resource.run_action(:delete_key)

      expect(@registry.key_exists?(reg_parent + '\OpscodeTest')).to eq(false)
    end

    it "raises an exception if the key has subkeys and recursive == false" do
      @new_resource.key(reg_parent)
      @new_resource.recursive(false)
      expect { @new_resource.run_action(:delete_key) }.to raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "ignores the values under a key" do
      @new_resource.key(reg_parent + '\OpscodeIgnoredValues')
      # @new_resource.values([{:name=>"DontExist", :type=>:string, :data=>"These will be ignored anyways"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:delete_key)
    end

    it "deletes the key if it has subkeys and recursive == true" do
      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.recursive(true)
      @new_resource.run_action(:delete_key)

      expect(@registry.key_exists?(reg_parent + '\Opscode')).to eq(false)
    end

    it "prepares the reporting data for action :delete_key" do
      @new_resource.key(reg_parent + '\ReportKey')
      @new_resource.recursive(true)
      @new_resource.run_action(:delete_key)

      @report = @resource_reporter.prepare_run_data
      expect(@report["action"]).to eq("end")
      expect(@report["resources"][0]["type"]).to eq("registry_key")
      expect(@report["resources"][0]["name"]).to eq(resource_name)
      expect(@report["resources"][0]["id"]).to eq(reg_parent + '\ReportKey')
      # Not testing for before or after values to match since
      # after -> new_resource.values and
      # before -> current_resource.values
      expect(@report["resources"][0]["result"]).to eq("delete_key")
      expect(@report["status"]).to eq("success")
      expect(@report["total_res_count"]).to eq("1")
    end
    context "while running in whyrun mode" do
      before(:each) do
        Chef::Config[:why_run] = true
      end

      it "does not throw an exception if the key has subkeys but recursive is set to false" do
        @new_resource.key(reg_parent + '\OpscodeWhyRun')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "is good for health" }])
        @new_resource.recursive(false)
        @new_resource.run_action(:delete_key)
      end
      it "does nothing if the action is delete_key" do
        @new_resource.key(reg_parent + '\OpscodeWhyRun')
        @new_resource.values([{ name: "BriskWalk", type: :string, data: "is good for health" }])
        @new_resource.recursive(false)
        @new_resource.run_action(:delete_key)

        expect(@registry.key_exists?(reg_parent + '\OpscodeWhyRun')).to eq(true)
      end
    end
  end
end
