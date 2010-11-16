#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::RubyBlock, "initialize" do
  before(:each) do
    $evil_global_evil_laugh = :wahwah
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::RubyBlock.new("bloc party")
    @new_resource.block { $evil_global_evil_laugh = :mwahahaha}
    @provider = Chef::Provider::RubyBlock.new(@new_resource, @run_context)
  end

  it "should call the block and flag the resource as updated" do
    @provider.action_create
    $evil_global_evil_laugh.should == :mwahahaha
    @new_resource.should be_updated
  end
end

