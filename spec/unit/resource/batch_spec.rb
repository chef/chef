#
# Author:: Adam Edwards (<adamed@opscode.com>)
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

describe Chef::Resource::Batch do

  before(:each) do
    node = Chef::Node.new

    node.default["kernel"] = Hash.new
    node.default["kernel"][:machine] = :x86_64.to_s

    run_context = Chef::RunContext.new(node, nil, nil)
    
    @resource = Chef::Resource::Batch.new("batch_unit_test", run_context)

  end  

  it "should create a new Chef::Resource::Batch" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Batch)
  end
  
  it "should have a resource name of :batch" do
    @resource.resource_name.should eql(:batch)
  end
  
  it "should have an interpreter with a file name of cmd.exe" do


    # When rspec-mocks 2.11 is released, switch to constant_stubbing
    # with const_stub below
    # stub_const("::File::ALT_SEPARATOR",::File::SEPARATOR).
    # For now, stub out a method that exists just for this purpose
#    @resource.respond_to?(:windows_separator).should == true
#    @resource.stub(:windows_separator) { ::File::SEPARATOR }
    
    @resource.interpreter.split('\\').pop.casecmp('cmd.exe').should == 0
  end

end
