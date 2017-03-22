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

  before(:each) do
    @resource = Chef::Resource::RemoteDirectory.new("/etc/dunk")
  end

  it "should create a new Chef::Resource::RemoteDirectory" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::RemoteDirectory)
  end

  it "should set the path to the first argument to new" do
    expect(@resource.path).to eql("/etc/dunk")
  end

  it "should accept a string for the remote directory source" do
    @resource.source "foo"
    expect(@resource.source).to eql("foo")
  end

  it "should have the basename of the remote directory resource as the default source" do
    expect(@resource.source).to eql("dunk")
  end

  it "should accept a number for the remote files backup" do
    @resource.files_backup 1
    expect(@resource.files_backup).to eql(1)
  end

  it "should accept false for the remote files backup" do
    @resource.files_backup false
    expect(@resource.files_backup).to eql(false)
  end

  it "should accept 3 or 4 digets for the files_mode" do
    @resource.files_mode 100
    expect(@resource.files_mode).to eql(100)
    @resource.files_mode 1000
    expect(@resource.files_mode).to eql(1000)
  end

  it "should accept a string or number for the files group" do
    @resource.files_group "heart"
    expect(@resource.files_group).to eql("heart")
    @resource.files_group 1000
    expect(@resource.files_group).to eql(1000)
  end

  it "should accept a string or number for the files owner" do
    @resource.files_owner "heart"
    expect(@resource.files_owner).to eql("heart")
    @resource.files_owner 1000
    expect(@resource.files_owner).to eql(1000)
  end

  describe "when it has cookbook, files owner, files mode, and source" do
    before do
      @resource.path("/var/path/")
      @resource.cookbook("pokemon.rb")
      @resource.files_owner("root")
      @resource.files_group("supergroup")
      @resource.files_mode("0664")
      @resource.source("/var/source/")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:files_owner]).to eq("root")
      expect(state[:files_group]).to eq("supergroup")
      expect(state[:files_mode]).to eq("0664")
    end

    it "returns the path  as its identity" do
      expect(@resource.identity).to eq("/var/path/")
    end
  end
end
