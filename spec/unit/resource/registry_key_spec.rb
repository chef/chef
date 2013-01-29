#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2012 OpsCode, Inc.
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

describe Chef::Resource::RegistryKey, "initialize" do
  before(:each) do
    @resource = Chef::Resource::RegistryKey.new('HKCU\Software\Raxicoricofallapatorius')
  end

  it "should create a new Chef::Resource::RegistryKey" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::RegistryKey)
  end

  it "should set the resource_name to :registry_key" do
    @resource.resource_name.should eql(:registry_key)
  end

  it "should set the key equal to the argument to initialize" do
    @resource.key.should eql('HKCU\Software\Raxicoricofallapatorius')
  end

  it "should default recursive to false" do
    @resource.recursive.should eql(false)
  end

  it "should default architecture to :machine" do
    @resource.architecture.should eql(:machine)
  end

  it "should set action to :create" do
    @resource.action.should eql(:create)
  end

  %w{create create_if_missing delete delete_key}.each do |action|
    it "should allow action #{action}" do
      @resource.allowed_actions.detect { |a| a == action.to_sym }.should eql(action.to_sym)
    end
  end
end

describe Chef::Resource::RegistryKey, "key" do
  before(:each) do
    @resource = Chef::Resource::RegistryKey.new('HKCU\Software\Raxicoricofallapatorius')
  end

  it "should allow a string" do
    @resource.key 'HKCU\Software\Poosh'
    @resource.key.should eql('HKCU\Software\Poosh')
  end

  it "should not allow an integer" do
    lambda { @resource.send(:key, 100) }.should raise_error(ArgumentError)
  end

  it "should not allow a hash" do
    lambda { @resource.send(:key, { :sonic => "screwdriver" }) }.should raise_error(ArgumentError)
  end
end

describe Chef::Resource::RegistryKey, "values" do
  before(:each) do
    @resource = Chef::Resource::RegistryKey.new('HKCU\Software\Raxicoricofallapatorius')
  end

  it "should allow a single proper hash of registry values" do
    @resource.values( { :name => 'poosh', :type => :string, :data => 'carmen' } )
    @resource.values.should eql([ { :name => 'poosh', :type => :string, :data => 'carmen' } ])
  end

  it "should allow an array of proper hashes of registry values" do
    @resource.values [ { :name => 'poosh', :type => :string, :data => 'carmen' } ]
    @resource.values.should eql([ { :name => 'poosh', :type => :string, :data => 'carmen' } ])
  end

  it "should throw an exception if the name field is missing" do
    lambda { @resource.values [ { :type => :string, :data => 'carmen' } ] }.should raise_error(ArgumentError)
  end

  it "should throw an exception if the type field is missing" do
    lambda { @resource.values [ { :name => 'poosh', :data => 'carmen' } ] }.should raise_error(ArgumentError)
  end

  it "should throw an exception if the data field is missing" do
    lambda { @resource.values [ { :name => 'poosh', :type => :string } ] }.should raise_error(ArgumentError)
  end

  it "should throw an exception if extra fields are present" do
    lambda { @resource.values [ { :name => 'poosh', :type => :string, :data => 'carmen', :screwdriver => 'sonic' } ] }.should raise_error(ArgumentError)
  end

  it "should not allow a string" do
    lambda { @resource.send(:values, 'souffle') }.should raise_error(ArgumentError)
  end

  it "should not allow an integer" do
    lambda { @resource.send(:values, 100) }.should raise_error(ArgumentError)
  end
end

describe Chef::Resource::RegistryKey, "recursive" do
  before(:each) do
    @resource = Chef::Resource::RegistryKey.new('HKCU\Software\Raxicoricofallapatorius')
  end

  it "should allow a boolean" do
    @resource.recursive(true)
    @resource.recursive.should eql(true)
  end

  it "should not allow a hash" do
    lambda { @resource.recursive({:sonic => :screwdriver}) }.should raise_error(ArgumentError)
  end

  it "should not allow an array" do
    lambda { @resource.recursive([:nose, :chin]) }.should raise_error(ArgumentError)
  end

  it "should not allow a string" do
    lambda { @resource.recursive('souffle') }.should raise_error(ArgumentError)
  end

  it "should not allow an integer" do
    lambda { @resource.recursive(100) }.should raise_error(ArgumentError)
  end
end

describe Chef::Resource::RegistryKey, "architecture" do
  before(:each) do
    @resource = Chef::Resource::RegistryKey.new('HKCU\Software\Raxicoricofallapatorius')
  end

  [ :i386, :x86_64, :machine ].each do |arch|
    it "should allow #{arch} as a symbol" do
      @resource.architecture(arch)
      @resource.architecture.should eql(arch)
    end
  end

  it "should not allow a hash" do
    lambda { @resource.architecture({:sonic => :screwdriver}) }.should raise_error(ArgumentError)
  end

  it "should not allow an array" do
    lambda { @resource.architecture([:nose, :chin]) }.should raise_error(ArgumentError)
  end

  it "should not allow a string" do
    lambda { @resource.architecture('souffle') }.should raise_error(ArgumentError)
  end

  it "should not allow an integer" do
    lambda { @resource.architecture(100) }.should raise_error(ArgumentError)
  end
end
