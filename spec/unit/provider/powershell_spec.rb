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
describe Chef::Provider::PowershellScript, "action_run" do

  before(:each) do
    @node = Chef::Node.new

    @node.default["kernel"] = Hash.new
    @node.default["kernel"][:machine] = :x86_64.to_s
    
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::PowershellScript.new('run some powershell code', @run_context)

    @provider = Chef::Provider::PowershellScript.new(@new_resource, @run_context)
  end

  it "should set the -File flag as the last flag" do
    @provider.flags.split(' ').pop.should == "-File"
  end

end
