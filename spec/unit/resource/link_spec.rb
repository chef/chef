#
# Author:: Adam Jacob (<adam@chef.io>)
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

describe Chef::Resource::Link do
  let(:resource) { Chef::Resource::Link.new("fakey_fakerton") }

  it "the target_file property is the name_property" do
    expect(resource.target_file).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "uses the object name as the target_file by default" do
    expect(resource.target_file).to eql("fakey_fakerton")
  end

  it "accepts a delayed evaluator as the target path" do
    resource.target_file Chef::DelayedEvaluator.new { "my_lazy_name" }
    expect(resource.target_file).to eql("my_lazy_name")
  end

  it "accepts a delayed evaluator when accessing via 'path'" do
    resource.target_file Chef::DelayedEvaluator.new { "my_lazy_name" }
    expect(resource.path).to eql("my_lazy_name")
  end

  it "accepts a delayed evaluator via 'to'" do
    resource.to Chef::DelayedEvaluator.new { "my_lazy_name" }
    expect(resource.to).to eql("my_lazy_name")
  end

  it "accepts a string as the link source via 'to'" do
    expect { resource.to "/tmp" }.not_to raise_error
  end

  it "does not accept a Hash for the link source via 'to'" do
    expect { resource.to({}) }.to raise_error(ArgumentError)
  end

  it "allows you to set a link source via 'to'" do
    resource.to "/tmp/foo"
    expect(resource.to).to eql("/tmp/foo")
  end

  it "allows you to specify the link type" do
    resource.link_type "symbolic"
    expect(resource.link_type).to eql(:symbolic)
  end

  it "defaults to a symbolic link" do
    expect(resource.link_type).to eql(:symbolic)
  end

  it "accepts a hard link_type" do
    resource.link_type :hard
    expect(resource.link_type).to eql(:hard)
  end

  it "rejects any other link_type but :hard and :symbolic" do
    expect { resource.link_type "x-men" }.to raise_error(ArgumentError)
  end

  it "accepts a group name or id for group" do
    expect { resource.group "root" }.not_to raise_error
    expect { resource.group 123 }.not_to raise_error
    expect { resource.group "root:goo" }.to raise_error(ArgumentError)
  end

  it "accepts a user name or id for owner" do
    expect { resource.owner "root" }.not_to raise_error
    expect { resource.owner 123 }.not_to raise_error
    expect { resource.owner "root:goo" }.to raise_error(ArgumentError)
  end

  describe "when it has to, link_type, owner, and group" do
    before do
      resource.target_file("/var/target.tar")
      resource.to("/to/dir/file.tar")
      resource.link_type(:symbolic)
      resource.owner("root")
      resource.group("0664")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:to]).to eq("/to/dir/file.tar")
      expect(state[:owner]).to eq("root")
      expect(state[:group]).to eq("0664")
    end

    it "returns the target file as its identity" do
      expect(resource.identity).to eq("/var/target.tar")
    end
  end
end
