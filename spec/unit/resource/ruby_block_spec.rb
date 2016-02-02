#
# Author:: AJ Christensen (<aj@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "spec_helper"

describe Chef::Resource::RubyBlock do

  before(:each) do
    @resource = Chef::Resource::RubyBlock.new("fakey_fakerton")
  end

  it "should create a new Chef::Resource::RubyBlock" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::RubyBlock)
  end

  it "should have a default action of 'run'" do
    expect(@resource.action).to eql([:run])
  end

  it "should have a resource name of :ruby_block" do
    expect(@resource.resource_name).to eql(:ruby_block)
  end

  it "should accept a ruby block/proc/.. for the 'block' parameter" do
    expect(@resource.block do
      "foo"
    end.call).to eql("foo")
  end

  it "allows the action to be 'create'" do
    @resource.action :create
    expect(@resource.action).to eq([:create])
  end

  describe "when it has been initialized with block code" do
    before do
      @resource.block_name("puts 'harrrr'")
    end

    it "returns the block as its identity" do
      expect(@resource.identity).to eq("puts 'harrrr'")
    end
  end
end
