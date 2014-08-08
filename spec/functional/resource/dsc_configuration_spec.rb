#
# Author:: Adam Edwards (<adamed@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'spec_helper'
require 'chef/mixin/windows_architecture_helper'

describe Chef::Resource::DscConfiguration, :windows_only do
  include Chef::Mixin::WindowsArchitectureHelper
  before(:all) do
    @temp_dir = ::Dir.mktmpdir("dsc-functional-test")
  end

  after(:all) do
    ::FileUtils.rm_rf(@temp_dir) if ::Dir.exist?(@temp_dir)
  end

  def create_config_script_from_code(code, configuration_name)
    script_code = "Configuration '#{configuration_name}'\n{\n\t#{code}\n}\n"
    script_path = "#{@temp_dir}/dsc_functional_test.ps1"
    ::File.open(script_path, 'wt') do | script |
      script.write(script_code)
    end
    script_path
  end

  let(:dsc_env_variable) { 'chefenvtest' }
  let(:dsc_env_value1) { 'value1' }
  let(:env_value2) { 'value2' }
  let(:dsc_test_run_context) {
    node = Chef::Node.new
    node.default['platform'] = 'windows'
    node.default['platform_version'] = '6.1'
    node.default['kernel'][:machine] =
      is_i386_process_on_x86_64_windows? ? :x86_64 : :i386
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  }
  let(:dsc_test_resource_name) { 'DSCTest' }
  let(:dsc_test_resource_base) {
    Chef::Resource::DscConfiguration.new(dsc_test_resource_name, dsc_test_run_context) 
  }
  let(:test_registry_key) { 'HKEY_LOCAL_MACHINE\Software\Chef\Spec\Functional\Resource\dsc_configuration_spec' }
  let(:test_registry_value) { 'Registration' }
  let(:test_registry_data1) { 'LL927' }
  let(:test_registry_data2) { 'LL928' }
  let(:dsc_code) { <<-EOH
  Registry "ChefRegKey"
  { 
     Key = '#{test_registry_key}'
     ValueName = '#{test_registry_value}'
     ValueData = '#{test_registry_data}'
     Ensure = 'Present'
  }
EOH
  }
  let(:dsc_config_name) {
    dsc_test_resource_base.name
  }
  let(:dsc_resource_from_code) {
    dsc_test_resource_base.configuration(dsc_code)
    dsc_test_resource_base
  }
  let(:dsc_resource_from_path) {
    dsc_test_resource_base.path(create_config_script_from_code(dsc_code, dsc_test_resource_base.name))
    dsc_test_resource_base
  }

  before(:each) do
    test_key_resource = Chef::Resource::RegistryKey.new(test_registry_key, dsc_test_run_context)
    test_key_resource.recursive(true)
    test_key_resource.run_action(:delete_key)
  end

  after(:each) do
    test_key_resource = Chef::Resource::RegistryKey.new(test_registry_key, dsc_test_run_context)
    test_key_resource.recursive(true)
    test_key_resource.run_action(:delete_key)
  end

  shared_examples_for 'a dsc_configuration resource with specified PowerShell configuration code' do
    let(:test_registry_data) { test_registry_data1 }
    it 'should create a registry key with a specific registry value and data' do
      expect(dsc_test_resource.registry_key_exists?(test_registry_key)).to eq(false)
      dsc_test_resource.run_action(:set)
      expect(dsc_test_resource.registry_key_exists?(test_registry_key)).to eq(true)
      expect(dsc_test_resource.registry_value_exists?(test_registry_key, {:name => test_registry_value, :type => :string, :data => test_registry_data})).to eq(true)
    end
  end

  context 'when supplying configuration through the configuration attribute' do
    let(:dsc_test_resource) { dsc_resource_from_code }
    it_behaves_like 'a dsc_configuration resource with specified PowerShell configuration code'
  end
  
  context 'when supplying configuration using the path attribute' do
    let(:dsc_test_resource) { dsc_resource_from_path }
    it_behaves_like 'a dsc_configuration resource with specified PowerShell configuration code'
  end

end
