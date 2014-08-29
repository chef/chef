#
# Author:: Jay Mundrawala (<jdm@getchef.com>)
#
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

require 'chef'
require 'chef/util/dsc/resource_info'
require 'spec_helper'

describe Chef::Provider::DscScript do

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @resource = Chef::Resource::DscScript.new("script", @run_context)
    @provider = Chef::Provider::DscScript.new(@resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe '#load_current_resource' do
    it "describes the resource as converged if there were 0 DSC resources" do
      @provider.stub(:run_configuration).with(:test).and_return([])
      @provider.load_current_resource
      @provider.instance_variable_get('@resource_converged').should be_true
    end

    it "describes the resource as not converged if there is 1 DSC resources that is converged" do
      dsc_resource_info = Chef::Util::DSC::ResourceInfo.new('resource', false, ['nothing will change something'])
      @provider.stub(:run_configuration).with(:test).and_return([dsc_resource_info])
      @provider.load_current_resource
      @provider.instance_variable_get('@resource_converged').should be_true
    end

    it "describes the resource as not converged if there is 1 DSC resources that is not converged" do
      dsc_resource_info = Chef::Util::DSC::ResourceInfo.new('resource', true, ['will change something'])
      @provider.stub(:run_configuration).with(:test).and_return([dsc_resource_info])
      @provider.load_current_resource
      @provider.instance_variable_get('@resource_converged').should be_false
    end

    it "describes the resource as not converged if there are any DSC resources that are not converged" do
      dsc_resource_info1 = Chef::Util::DSC::ResourceInfo.new('resource', true, ['will change something'])
      dsc_resource_info2 = Chef::Util::DSC::ResourceInfo.new('resource', false, ['nothing will change something'])

      @provider.stub(:run_configuration).with(:test).and_return([dsc_resource_info1, dsc_resource_info2])
      @provider.load_current_resource
      @provider.instance_variable_get('@resource_converged').should be_false
    end

    it "describes the resource as converged if all DSC resources that are converged" do
      dsc_resource_info1 = Chef::Util::DSC::ResourceInfo.new('resource', false, ['nothing will change something'])
      dsc_resource_info2 = Chef::Util::DSC::ResourceInfo.new('resource', false, ['nothing will change something'])

      @provider.stub(:run_configuration).with(:test).and_return([dsc_resource_info1, dsc_resource_info2])
      @provider.load_current_resource
      @provider.instance_variable_get('@resource_converged').should be_true
    end
  end

  describe '#generate_configuration_document' do
    # I think integration tests should cover these cases
    
    it 'uses configuration_document_from_script_path when a dsc script file is given' do
      @provider.stub(:load_current_resource)
      @resource.command("path_to_script")
      generator = double('Chef::Util::DSC::ConfigurationGenerator')
      generator.should_receive(:configuration_document_from_script_path)
      Chef::Util::DSC::ConfigurationGenerator.stub(:new).and_return(generator)
      @provider.send(:generate_configuration_document, 'tmp', nil)
    end

    it 'uses configuration_document_from_script_code when a the dsc resource is given' do
      @provider.stub(:load_current_resource)
      @resource.code("ImADSCResource{}")
      generator = double('Chef::Util::DSC::ConfigurationGenerator')
      generator.should_receive(:configuration_document_from_script_code)
      Chef::Util::DSC::ConfigurationGenerator.stub(:new).and_return(generator)
      @provider.send(:generate_configuration_document, 'tmp', nil)
    end

    it 'should noop if neither code or command are provided' do
      @provider.stub(:load_current_resource)
      generator = double('Chef::Util::DSC::ConfigurationGenerator')
      generator.should_receive(:configuration_document_from_script_code).with('', anything(), anything())
      Chef::Util::DSC::ConfigurationGenerator.stub(:new).and_return(generator)
      @provider.send(:generate_configuration_document, 'tmp', nil)
    end
  end

  describe 'action_run' do
    it 'should converge the script if it is not converged' do
      dsc_resource_info = Chef::Util::DSC::ResourceInfo.new('resource', true, ['will change something'])
      @provider.stub(:run_configuration).with(:test).and_return([dsc_resource_info])
      @provider.stub(:run_configuration).with(:set)
      
      @provider.run_action(:run)
      @resource.should be_updated

    end

    it 'should not converge if the script is already converged' do
      @provider.stub(:run_configuration).with(:test).and_return([])
      
      @provider.run_action(:run)
      @resource.should_not be_updated
    end
  end
end

