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
    @n = mock("Chef::Node", :null_object => true)
    @nr = mock("Chef::Resource::RubyBlock", :null_object => true)
  end

  it "should return a Chef::Provider::RubyBlock object" do
    provider = Chef::Provider::RubyBlock.new(@n, @nr)
    provider.should be_a_kind_of(Chef::Provider::RubyBlock)
  end
end

describe Chef::Provider::RubyBlock, "action_create" do  
  before(:each) do
    @n = mock("Chef::Node", :null_object => true)
    @nr = mock("Chef::Resource::RubyBlock",
               :null_object => true,
               :block => Proc.new {"lol"}
              )
    @p = Chef::Provider::RubyBlock.new(@n, @nr)
  end

  it "should call the block" do
    @nr.block.should_receive(:call).and_return("lol")
    @p.action_create
  end
end

