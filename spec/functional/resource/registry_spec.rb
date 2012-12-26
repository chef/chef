#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
    node.consume_external_attrs(ohai.data,{})
    run_context = Chef::RunContext.new(node, {}, events)
    @resource = Chef::Resource::RegistryKey.new("HKCU\\Software", run_context)
  end
  context "when load_current_resource is run on a non-windows node" do
    it "throws an exception because you don't have a windows registry (derp)" do
      @resource.key("HKCU\\Software\\Opscode")
      @resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      lambda{@resource.run_action(:create)}.should raise_error(Chef::Exceptions::Win32NotWindows)
    end
  end
end

describe Chef::Resource::RegistryKey, :windows_only do

  # parent and key must be single keys, not paths
  let(:parent) { 'Opscode' }
  let(:child) { 'Whatever' }
  let(:key_parent) { "SOFTWARE\\" + parent }
  let(:key_child) { "SOFTWARE\\" + parent + "\\" + child }
  # must be under HKLM\SOFTWARE for WOW64 redirection to work
  let(:reg_parent) { "HKLM\\" + key_parent }
  let(:reg_child) { "HKLM\\" + key_child }
  let(:hive_class) { ::Win32::Registry::HKEY_LOCAL_MACHINE }
  let(:resource_name) { "This is the name of my Resource" }

  def clean_registry
    # clean 64-bit space on WOW64
    begin
      hive_class.open(key_parent, Win32::Registry::KEY_WRITE | 0x0100) do |reg|
        reg.delete_key(child, true)
      end
    rescue
    end
    # clean 32-bit space on WOW64
    begin
      hive_class.open(key_parent, Win32::Registry::KEY_WRITE | 0x0200) do |reg|
        reg.delete_key(child, true)
      end
    rescue
    end
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
        reg.write("Opscode", Win32::Registry::REG_MULTI_SZ, ["Seattle", "Washington"])
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
    @node.consume_external_attrs(ohai.data,{})
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::RegistryKey.new(resource_name, @run_context)
    @registry = Chef::Win32::Registry.new(@run_context)

    @current_whyrun = Chef::Config[:why_run]

    reset_registry
  end

  #Reporting setup
  before do
    @node.name("windowsbox")
    @rest_client = mock("Chef::REST (mock)")
    @rest_client.stub!(:create_url).and_return("reports/nodes/windowsbox/runs/ABC123");
    @rest_client.stub!(:raw_http_request).and_return({"result"=>"ok"});
    @rest_client.stub!(:post_rest).and_return({"uri"=>"https://example.com/reports/nodes/windowsbox/runs/ABC123"});

    @resource_reporter = Chef::ResourceReporter.new(@rest_client)
    @events.register(@resource_reporter)
    @resource_reporter.node_load_completed(@node, :expanded_run_list, :config)

    @new_resource.cookbook_name = "monkey"
    @cookbook_version = mock("Cookbook::Version", :version => "1.2.3")
    @new_resource.stub!(:cookbook_version).and_return(@cookbook_version)
  end

  after (:all) do
    clean_registry
  end

  context "when action is create" do
    before (:all) do
      reset_registry
    end
    it "creates registry key, value if the key is missing" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @new_resource.run_action(:create)

      @registry.key_exists?(reg_child).should == true
      @registry.data_exists?(reg_child, {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "does not create the key if it already exists with same value, type and data" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @new_resource.run_action(:create)

      @registry.key_exists?(reg_child).should == true
      @registry.data_exists?(reg_child, {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "creates a value if it does not exist" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Mango", :type=>:string, :data=>"Yellow"}])
      @new_resource.run_action(:create)

      @registry.data_exists?(reg_child, {:name=>"Mango", :type=>:string, :data=>"Yellow"}).should == true
    end

    it "modifies the data if the key and value exist and type matches" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Color", :type=>:string, :data=>"Not just Orange - OpscodeOrange!"}])
      @new_resource.run_action(:create)

      @registry.data_exists?(reg_child, {:name=>"Color", :type=>:string, :data=>"Not just Orange - OpscodeOrange!"}).should == true
    end

    it "modifys the type if the key and value exist and the type does not match" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Color", :type=>:multi_string, :data=>["Not just Orange - OpscodeOrange!"]}])
      @new_resource.run_action(:create)

      @registry.data_exists?(reg_child, {:name=>"Color", :type=>:multi_string, :data=>["Not just Orange - OpscodeOrange!"]}).should == true
    end

    it "creates subkey if parent exists" do
      @new_resource.key(reg_child + '\OpscodeTest')
      @new_resource.values([{:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}])
      @new_resource.recursive(false)
      @new_resource.run_action(:create)

      @registry.key_exists?(reg_child + '\OpscodeTest').should == true
      @registry.value_exists?(reg_child + '\OpscodeTest', {:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}).should == true
    end

    it "gives error if action create and parent does not exist and recursive is set to false" do
      @new_resource.key(reg_child + '\Missing1\Missing2')
      @new_resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @new_resource.recursive(false)
      lambda{@new_resource.run_action(:create)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "creates missing keys if action create and parent does not exist and recursive is set to true" do
      @new_resource.key(reg_child + '\Missing1\Missing2')
      @new_resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:create)

      @registry.key_exists?(reg_child + '\Missing1\Missing2').should == true
      @registry.value_exists?(reg_child + '\Missing1\Missing2', {:name=>"OC", :type=>:string, :data=>"MissingData"}).should == true
    end

    it "creates key with multiple value as specified" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"one", :type=>:string, :data=>"1"},{:name=>"two", :type=>:string, :data=>"2"},{:name=>"three", :type=>:string, :data=>"3"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:create)

      @new_resource.values.each do |value|
        @registry.value_exists?(reg_child, value).should == true
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
        @new_resource.values([{:name=>"OC", :type=>:string, :data=>"Data"}])
        @new_resource.recursive(true)
        @new_resource.architecture(:i386)
        @new_resource.run_action(:create)
        @registry.architecture = :i386
        @registry.data_exists?(reg_child + '\Atraxi', {:name=>"OC", :type=>:string, :data=>"Data"}).should == true
        @registry.architecture = :x86_64
        @registry.key_exists?(reg_child + '\Atraxi').should == false
      end
    end

    it "prepares the reporting data for action :create" do
      @new_resource.key(reg_child + '\Ood')
      @new_resource.values([{:name=>"ReportingVal1", :type=>:string, :data=>"report1"},{:name=>"ReportingVal2", :type=>:string, :data=>"report2"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:create)
      @report = @resource_reporter.prepare_run_data

      @report["action"].should == "end"
      @report["resources"][0]["type"].should == "registry_key"
      @report["resources"][0]["name"].should == resource_name
      @report["resources"][0]["id"].should == reg_child + '\Ood'
      @report["resources"][0]["after"][:values].should == [{:name=>"ReportingVal1", :type=>:string, :data=>"report1"},
                                                           {:name=>"ReportingVal2", :type=>:string, :data=>"report2"}]
      @report["resources"][0]["before"][:values].should == []
      @report["resources"][0]["result"].should == "create"
      @report["status"].should == "success"
      @report["total_res_count"].should == "1"
    end

    context "while running in whyrun mode" do
      before (:all) do
        Chef::Config[:why_run] = true
      end
      after (:all) do
        Chef::Config[:why_run] = @current_whyrun
      end

      it "does not throw an exception if the keys do not exist but recursive is set to false" do
        @new_resource.key(reg_child + '\Slitheen\Raxicoricofallapatorius')
        @new_resource.values([{:name=>"BriskWalk",:type=>:string,:data=>"is good for health"}])
        @new_resource.recursive(false)
        lambda{@new_resource.run_action(:create)}.should_not raise_error
        @registry.key_exists?(reg_child + '\Slitheen').should == false
        @registry.key_exists?(reg_child + '\Slitheen\Raxicoricofallapatorius').should == false
      end
      it "does not create key if the action is create" do
        @new_resource.key(reg_child + '\Slitheen')
        @new_resource.values([{:name=>"BriskWalk",:type=>:string,:data=>"is good for health"}])
        @new_resource.recursive(false)
        @new_resource.run_action(:create)
        @registry.key_exists?(reg_child + '\Slitheen').should == false
      end
    end
  end

  context "when action is create_if_missing" do
    before (:all) do
      reset_registry
    end

    it "creates registry key, value if the key is missing" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @new_resource.run_action(:create_if_missing)

      @registry.key_exists?(reg_parent).should == true
      @registry.key_exists?(reg_child).should == true
      @registry.data_exists?(reg_child, {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "does not create the key if it already exists with same value, type and data" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Color", :type=>:string, :data=>"Orange"}])
      @new_resource.run_action(:create_if_missing)

      @registry.key_exists?(reg_child).should == true
      @registry.data_exists?(reg_child, {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "creates a value if it does not exist" do
      @new_resource.key(reg_child)
      @new_resource.values([{:name=>"Mango", :type=>:string, :data=>"Yellow"}])
      @new_resource.run_action(:create_if_missing)

      @registry.data_exists?(reg_child, {:name=>"Mango", :type=>:string, :data=>"Yellow"}).should == true
    end

    it "creates subkey if parent exists" do
      @new_resource.key(reg_child + '\Pyrovile')
      @new_resource.values([{:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}])
      @new_resource.recursive(false)
      @new_resource.run_action(:create_if_missing)

      @registry.key_exists?(reg_child + '\Pyrovile').should == true
      @registry.value_exists?(reg_child + '\Pyrovile', {:name=>"Chef", :type=>:multi_string, :data=>["OpscodeOrange", "Rules"]}).should == true
    end

    it "gives error if action create and parent does not exist and recursive is set to false" do
      @new_resource.key(reg_child + '\Sontaran\Sontar')
      @new_resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @new_resource.recursive(false)
      lambda{@new_resource.run_action(:create_if_missing)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "creates missing keys if action create and parent does not exist and recursive is set to true" do
      @new_resource.key(reg_child + '\Sontaran\Sontar')
      @new_resource.values([{:name=>"OC", :type=>:string, :data=>"MissingData"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:create_if_missing)

      @registry.key_exists?(reg_child + '\Sontaran\Sontar').should == true
      @registry.value_exists?(reg_child + '\Sontaran\Sontar', {:name=>"OC", :type=>:string, :data=>"MissingData"}).should == true
    end

    it "creates key with multiple value as specified" do
      @new_resource.key(reg_child + '\Adipose')
      @new_resource.values([{:name=>"one", :type=>:string, :data=>"1"},{:name=>"two", :type=>:string, :data=>"2"},{:name=>"three", :type=>:string, :data=>"3"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:create_if_missing)

      @new_resource.values.each do |value|
        @registry.value_exists?(reg_child + '\Adipose', value).should == true
      end
    end

    it "prepares the reporting data for :create_if_missing" do
      @new_resource.key(reg_child + '\Judoon')
      @new_resource.values([{:name=>"ReportingVal3", :type=>:string, :data=>"report3"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:create_if_missing)
      @report = @resource_reporter.prepare_run_data

      @report["action"].should == "end"
      @report["resources"][0]["type"].should == "registry_key"
      @report["resources"][0]["name"].should == resource_name
      @report["resources"][0]["id"].should == reg_child + '\Judoon'
      @report["resources"][0]["after"][:values].should == [{:name=>"ReportingVal3", :type=>:string, :data=>"report3"}]
      @report["resources"][0]["before"][:values].should == []
      @report["resources"][0]["result"].should == "create_if_missing"
      @report["status"].should == "success"
      @report["total_res_count"].should == "1"
    end

    context "while running in whyrun mode" do
      before (:all) do
        Chef::Config[:why_run] = true
      end
      after (:all) do
        Chef::Config[:why_run] = @current_whyrun
      end

      it "does not throw an exception if the keys do not exist but recursive is set to false" do
        @new_resource.key(reg_child + '\Zygons\Zygor')
        @new_resource.values([{:name=>"BriskWalk",:type=>:string,:data=>"is good for health"}])
        @new_resource.recursive(false)
        lambda{@new_resource.run_action(:create_if_missing)}.should_not raise_error
        @registry.key_exists?(reg_child + '\Zygons').should == false
        @registry.key_exists?(reg_child + '\Zygons\Zygor').should == false
      end
      it "does nothing if the action is create_if_missing" do
        @new_resource.key(reg_child + '\Zygons')
        @new_resource.values([{:name=>"BriskWalk",:type=>:string,:data=>"is good for health"}])
        @new_resource.recursive(false)
        @new_resource.run_action(:create_if_missing)
        @registry.key_exists?(reg_child + '\Zygons').should == false
      end
    end
  end

  context "when the action is delete" do
    before(:all) do
      reset_registry
      create_deletable_keys
    end

    it "takes no action if the specified key path does not exist in the system" do
      @registry.key_exists?(reg_parent + '\Osirian').should == false

      @new_resource.key(reg_parent+ '\Osirian')
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      @registry.key_exists?(reg_parent + '\Osirian').should == false
    end

    it "takes no action if the key exists but the value does not" do
      @registry.data_exists?(reg_parent + '\Opscode', {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true

      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.values([{:name=>"LooksLike", :type=>:multi_string, :data=>["SeattleGrey", "OCOrange"]}])
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      @registry.data_exists?(reg_parent + '\Opscode', {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
    end

    it "deletes only specified values under a key path" do
      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.values([{:name=>"Opscode", :type=>:multi_string, :data=>["Seattle", "Washington"]}, {:name=>"AKA", :type=>:string, :data=>"OC"}])
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      @registry.data_exists?(reg_parent + '\Opscode', {:name=>"Color", :type=>:string, :data=>"Orange"}).should == true
      @registry.value_exists?(reg_parent + '\Opscode', {:name=>"AKA", :type=>:string, :data=>"OC"}).should == false
      @registry.value_exists?(reg_parent + '\Opscode', {:name=>"Opscode", :type=>:multi_string, :data=>["Seattle", "Washington"]}).should == false
    end

    it "it deletes the values with the same name irrespective of it type and data" do
      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.values([{:name=>"Color", :type=>:multi_string, :data=>["Black", "Orange"]}])
      @new_resource.recursive(false)
      @new_resource.run_action(:delete)

      @registry.value_exists?(reg_parent + '\Opscode', {:name=>"Color", :type=>:string, :data=>"Orange"}).should == false
    end

    it "prepares the reporting data for action :delete" do
      @new_resource.key(reg_parent + '\ReportKey')
      @new_resource.values([{:name=>"ReportVal4", :type=>:string, :data=>"report4"},{:name=>"ReportVal5", :type=>:string, :data=>"report5"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:delete)

      @report = @resource_reporter.prepare_run_data

      @registry.value_exists?(reg_parent + '\ReportKey', [{:name=>"ReportVal4", :type=>:string, :data=>"report4"},{:name=>"ReportVal5", :type=>:string, :data=>"report5"}]).should == false

      @report["action"].should == "end"
      @report["resources"].count.should == 1
      @report["resources"][0]["type"].should == "registry_key"
      @report["resources"][0]["name"].should == resource_name
      @report["resources"][0]["id"].should == reg_parent + '\ReportKey'
      @report["resources"][0]["before"][:values].should == [{:name=>"ReportVal4", :type=>:string, :data=>"report4"},
                                                            {:name=>"ReportVal5", :type=>:string, :data=>"report5"}]
      #Not testing for after values to match since after -> new_resource values.
      @report["resources"][0]["result"].should == "delete"
      @report["status"].should == "success"
      @report["total_res_count"].should == "1"
    end

    context "while running in whyrun mode" do
      before (:all) do
        Chef::Config[:why_run] = true
      end
      after (:all) do
        Chef::Config[:why_run] = @current_whyrun
      end
      it "does nothing if the action is delete" do
        @new_resource.key(reg_parent + '\OpscodeWhyRun')
        @new_resource.values([{:name=>"BriskWalk",:type=>:string,:data=>"is good for health"}])
        @new_resource.recursive(false)
        @new_resource.run_action(:delete)

        @registry.key_exists?(reg_parent + '\OpscodeWhyRun').should == true
      end
    end
  end

  context "when the action is delete_key" do
    before (:all) do
      reset_registry
      create_deletable_keys
    end

    it "takes no action if the specified key path does not exist in the system" do
      @registry.key_exists?(reg_parent + '\Osirian').should == false

      @new_resource.key(reg_parent + '\Osirian')
      @new_resource.recursive(false)
      @new_resource.run_action(:delete_key)

      @registry.key_exists?(reg_parent + '\Osirian').should == false
    end

    it "deletes key if it has no subkeys and recursive == false" do
      @new_resource.key(reg_parent + '\OpscodeTest')
      @new_resource.recursive(false)
      @new_resource.run_action(:delete_key)

      @registry.key_exists?(reg_parent + '\OpscodeTest').should == false
    end

    it "raises an exception if the the key has subkeys and recursive == false" do
      @new_resource.key(reg_parent)
      @new_resource.recursive(false)
      lambda{@new_resource.run_action(:delete_key)}.should raise_error(Chef::Exceptions::Win32RegNoRecursive)
    end

    it "ignores the values under a key" do
      @new_resource.key(reg_parent + '\OpscodeIgnoredValues')
      #@new_resource.values([{:name=>"DontExist", :type=>:string, :data=>"These will be ignored anyways"}])
      @new_resource.recursive(true)
      @new_resource.run_action(:delete_key)
    end

    it "deletes the key if it has subkeys and recursive == true" do
      @new_resource.key(reg_parent + '\Opscode')
      @new_resource.recursive(true)
      @new_resource.run_action(:delete_key)

      @registry.key_exists?(reg_parent + '\Opscode').should == false
    end

    it "prepares the reporting data for action :delete_key" do
      @new_resource.key(reg_parent + '\ReportKey')
      @new_resource.recursive(true)
      @new_resource.run_action(:delete_key)

      @report = @resource_reporter.prepare_run_data
      @report["action"].should == "end"
      @report["resources"][0]["type"].should == "registry_key"
      @report["resources"][0]["name"].should == resource_name
      @report["resources"][0]["id"].should == reg_parent + '\ReportKey'
      #Not testing for before or after values to match since 
      #after -> new_resource.values and
      #before -> current_resource.values
      @report["resources"][0]["result"].should == "delete_key"
      @report["status"].should == "success"
      @report["total_res_count"].should == "1"
    end
    context "while running in whyrun mode" do
      before (:all) do
        Chef::Config[:why_run] = true
      end
      after (:all) do
        Chef::Config[:why_run] = @current_whyrun
      end

      it "does not throw an exception if the key has subkeys but recursive is set to false" do
        @new_resource.key(reg_parent + '\OpscodeWhyRun')
        @new_resource.values([{:name=>"BriskWalk",:type=>:string,:data=>"is good for health"}])
        @new_resource.recursive(false)
        @new_resource.run_action(:delete_key)
        @new_resource.should_not raise_error(ArgumentError)
      end
      it "does nothing if the action is delete_key" do
        @new_resource.key(reg_parent + '\OpscodeWhyRun')
        @new_resource.values([{:name=>"BriskWalk",:type=>:string,:data=>"is good for health"}])
        @new_resource.recursive(false)
        @new_resource.run_action(:delete_key)

        @registry.key_exists?(reg_parent + '\OpscodeWhyRun').should == true
      end
    end
  end
end
