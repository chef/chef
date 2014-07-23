#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Chef::Resource::SolarisPackage, 'initialize' do

  before(:each) do
    @resource = Chef::Resource::SolarisPackage.new('foo')
  end

  it 'should return a Chef::Resource::SolarisPackage object' do
    @resource.should be_a_kind_of(Chef::Resource::SolarisPackage)
  end

  it 'should not raise any Error when valid number of arguments are provided' do
    expect { Chef::Resource::SolarisPackage.new('foo') }.to_not raise_error
  end

  it 'should raise ArgumentError when incorrect number of arguments are provided' do
    expect { Chef::Resource::SolarisPackage.new }.to raise_error(ArgumentError)
  end

  it 'should set the package_name to the name provided' do
    @resource.package_name.should eql('foo')
  end

  it 'should set the resource_name to :solaris_package' do
    @resource.resource_name.should eql(:solaris_package)
  end

  it 'should set the run_context to the run_context provided' do
    @run_context = double
    @run_context.stub(:node)
    resource = Chef::Resource::SolarisPackage.new('foo', @run_context)
    resource.run_context.should eql(@run_context)
  end

  it 'should set the provider to Chef::Provider::Package::Solaris' do
    @resource.provider.should eql(Chef::Provider::Package::Solaris)
  end
end
