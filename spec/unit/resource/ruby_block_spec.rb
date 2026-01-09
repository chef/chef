#
# Author:: AJ Christensen (<aj@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

  let(:resource) { Chef::Resource::RubyBlock.new("fakey_fakerton") }

  it "has a resource name of :ruby_block" do
    expect(resource.resource_name).to eql(:ruby_block)
  end

  it "the block_name property is the name_property" do
    expect(resource.block_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :run" do
    expect(resource.action).to eql([:run])
  end

  it "supports :create, :run actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :run }.not_to raise_error
  end

  it "accepts a ruby block/proc/.. for the 'block' parameter" do
    expect(resource.block do
      "foo"
    end.call).to eql("foo")
  end

  describe "when it has been initialized with block code" do
    before do
      resource.block_name("puts 'harrrr'")
    end

    it "returns the block as its identity" do
      expect(resource.identity).to eq("puts 'harrrr'")
    end
  end
end
