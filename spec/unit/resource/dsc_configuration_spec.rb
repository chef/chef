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

describe Chef::Resource::DscConfiguration do
  let(:dsc_test_run_context) {
    node = Chef::Node.new
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  }
  let(:dsc_test_resource_name) { 'DSCTest' }
  let(:dsc_test_resource) {
    Chef::Resource::DscConfiguration.new(dsc_test_resource_name, dsc_test_run_context) 
  }
  let(:configuration_code) {'echo "This is supposed to create a configuration document."'}
  let(:configuration_path) {'c:/myconfigs/formatc.ps1'}
  let(:configuration_name) { 'formatme' }

  it "allows the configuration attribute to be set" do
    dsc_test_resource.configuration(configuration_code)
    expect(dsc_test_resource.configuration).to eq(configuration_code)
  end

  it "allows the path attribute to be set" do
    dsc_test_resource.path(configuration_path)
    expect(dsc_test_resource.path).to eq(configuration_path)
  end

  it "allows the configuration_name attribute to be set" do
    dsc_test_resource.configuration_name(configuration_name)
    expect(dsc_test_resource.configuration_name).to eq(configuration_name)
  end

  it "raises an ArgumentError exception if an attempt is made to set the configuration attribute when the path attribute is already set" do
    dsc_test_resource.path(configuration_path)
    expect { dsc_test_resource.configuration(configuration_code) }.to raise_error(ArgumentError)
  end

  it "raises an ArgumentError exception if an attempt is made to set the path attribute when the configuration attribute is already set" do
    dsc_test_resource.configuration(configuration_code)
    expect { dsc_test_resource.path(configuration_path) }.to raise_error(ArgumentError)
  end

  it "raises an ArgumentError exception if an attempt is made to set the configuration_name attribute when the configuration attribute is already set" do
    dsc_test_resource.configuration(configuration_code)
    expect { dsc_test_resource.configuration_name(configuration_name) }.to raise_error(ArgumentError)
  end

  it "raises an ArgumentError exception if an attempt is made to set the configuration attribute when the configuration_name attribute is already set" do
    dsc_test_resource.configuration_name(configuration_name)
    expect { dsc_test_resource.configuration(configuration_code) }.to raise_error(ArgumentError)
  end
end
