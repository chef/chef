#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::Resource::Link do

  before(:each) do
    expect_any_instance_of(Chef::Resource::Link).to receive(:verify_links_supported!).and_return(true)
    @resource = Chef::Resource::Link.new("fakey_fakerton")
  end

  it "should create a new Chef::Resource::Link" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Link)
  end

  it "should have a name" do
    expect(@resource.name).to eql("fakey_fakerton")
  end

  it "should have a default action of 'create'" do
    expect(@resource.action).to eql([:create])
  end

  { :create => false, :delete => false, :blues => true }.each do |action, bad_value|
    it "should #{bad_value ? 'not' : ''} accept #{action}" do
      if bad_value
        expect { @resource.action action }.to raise_error(ArgumentError)
      else
        expect { @resource.action action }.not_to raise_error
      end
    end
  end

  it "should use the object name as the target_file by default" do
    expect(@resource.target_file).to eql("fakey_fakerton")
  end

  it "should accept a delayed evaluator as the target path" do
    @resource.target_file Chef::DelayedEvaluator.new { "my_lazy_name" }
    expect(@resource.target_file).to eql("my_lazy_name")
  end

  it "should accept a delayed evaluator when accessing via 'path'" do
    @resource.target_file Chef::DelayedEvaluator.new { "my_lazy_name" }
    expect(@resource.path).to eql("my_lazy_name")
  end

  it "should accept a delayed evaluator via 'to'" do
    @resource.to Chef::DelayedEvaluator.new { "my_lazy_name" }
    expect(@resource.to).to eql("my_lazy_name")
  end

  it "should accept a string as the link source via 'to'" do
    expect { @resource.to "/tmp" }.not_to raise_error
  end

  it "should not accept a Hash for the link source via 'to'" do
    expect { @resource.to Hash.new }.to raise_error(ArgumentError)
  end

  it "should allow you to set a link source via 'to'" do
    @resource.to "/tmp/foo"
    expect(@resource.to).to eql("/tmp/foo")
  end

  it "should allow you to specify the link type" do
    @resource.link_type "symbolic"
    expect(@resource.link_type).to eql(:symbolic)
  end

  it "should default to a symbolic link" do
    expect(@resource.link_type).to eql(:symbolic)
  end

  it "should accept a hard link_type" do
    @resource.link_type :hard
    expect(@resource.link_type).to eql(:hard)
  end

  it "should reject any other link_type but :hard and :symbolic" do
    expect { @resource.link_type "x-men" }.to raise_error(ArgumentError)
  end

  it "should accept a group name or id for group" do
    expect { @resource.group "root" }.not_to raise_error
    expect { @resource.group 123 }.not_to raise_error
    expect { @resource.group "root:goo" }.to raise_error(ArgumentError)
  end

  it "should accept a user name or id for owner" do
    expect { @resource.owner "root" }.not_to raise_error
    expect { @resource.owner 123 }.not_to raise_error
    expect { @resource.owner "root:goo" }.to raise_error(ArgumentError)
  end

  describe "when it has to, link_type, owner, and group" do
    before do
      @resource.target_file("/var/target.tar")
      @resource.to("/to/dir/file.tar")
      @resource.link_type(:symbolic)
      @resource.owner("root")
      @resource.group("0664")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:to]).to eq("/to/dir/file.tar")
      expect(state[:owner]).to eq("root")
      expect(state[:group]).to eq("0664")
    end

    it "returns the target file as its identity" do
      expect(@resource.identity).to eq("/var/target.tar")
    end
  end
end
