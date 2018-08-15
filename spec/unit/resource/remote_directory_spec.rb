#
# Author:: Adam Jacob (<adam@chef.io>)
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

describe Chef::Resource::RemoteDirectory do

  let(:resource) { Chef::Resource::RemoteDirectory.new("/etc/dunk") }

  it "the path property is the name_property" do
    expect(resource.path).to eql("/etc/dunk")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :create_if_missing, :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :create_if_missing }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "accepts a string for the remote directory source" do
    resource.source "foo"
    expect(resource.source).to eql("foo")
  end

  it "has the basename of the remote directory resource as the default source" do
    resource.path "/foo/bar"
    expect(resource.source).to eql("bar")
  end

  it "accepts a number for the remote files backup" do
    resource.files_backup 1
    expect(resource.files_backup).to eql(1)
  end

  it "accepts false for the remote files backup" do
    resource.files_backup false
    expect(resource.files_backup).to eql(false)
  end

  it "accepts 3 or 4 digits for the files_mode" do
    resource.files_mode 100
    expect(resource.files_mode).to eql(100)
    resource.files_mode 1000
    expect(resource.files_mode).to eql(1000)
  end

  it "accepts a string or number for the files group" do
    resource.files_group "heart"
    expect(resource.files_group).to eql("heart")
    resource.files_group 1000
    expect(resource.files_group).to eql(1000)
  end

  it "accepts a string or number for the files owner" do
    resource.files_owner "heart"
    expect(resource.files_owner).to eql("heart")
    resource.files_owner 1000
    expect(resource.files_owner).to eql(1000)
  end

  it "overwrites by default" do
    expect(resource.overwrite).to be true
  end

  describe "when it has cookbook, files owner, files mode, and source" do
    before do
      resource.path("/var/path/")
      resource.cookbook("pokemon.rb")
      resource.files_owner("root")
      resource.files_group("supergroup")
      resource.files_mode("0664")
      resource.source("/var/source/")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:files_owner]).to eq("root")
      expect(state[:files_group]).to eq("supergroup")
      expect(state[:files_mode]).to eq("0664")
    end

    it "returns the path  as its identity" do
      expect(resource.identity).to eq("/var/path/")
    end
  end
end
