#
# Author:: Steven Danna
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

require "knife_spec_helper"

Chef::Knife::UserList.load_deps

describe Chef::Knife::UserList do

  let(:knife) { Chef::Knife::UserList.new }
  let(:users) do
    {
      "user1" => "http//test/users/user1",
      "user2" => "http//test/users/user2",
    }
  end

  before :each do
    @rest = double("Chef::ServerAPI")
    allow(Chef::ServerAPI).to receive(:new).and_return(@rest)
    allow(@rest).to receive(:get).with("users").and_return(users)
    allow(Chef::UserV1).to receive(:list).with(nil).and_return(users)
  end

  describe "with no arguments" do
    it "lists all users" do
      expect(knife.ui).to receive(:output).with(%w{user1 user2})
      knife.run
    end
  end

  describe "with all_users argument" do
    let(:user1_object) do
      u = Chef::UserV1.new
      u.username "user1"
      u.email "user1@example.com"
      u.display_name "User One"
      u
    end

    let(:user2_object) do
      u = Chef::UserV1.new
      u.username "user2"
      u.email "user2@example.com"
      u.display_name "User Two"
      u
    end

    let(:inflated_users) do
      {
        "user1" => user1_object,
        "user2" => user2_object,
      }
    end

    before do
      knife.config[:all_users] = true
      allow(Chef::UserV1).to receive(:list).with(true).and_return(inflated_users)
    end

    it "lists all users with full details" do
      expect(knife.ui).to receive(:output) do |arg|
        expect(arg).to be_a(Hash)
        expect(arg.keys).to contain_exactly("user1", "user2")
        expect(arg["user1"]["username"]).to eq("user1")
        expect(arg["user1"]["email"]).to eq("user1@example.com")
        expect(arg["user2"]["username"]).to eq("user2")
      end
      knife.run
    end
  end

  it "lists the users" do
    expect(knife).to receive(:format_list_for_display)
    knife.run
  end

  describe "with options with_uri argument" do
    before do
      knife.config[:with_uri] = true
    end

    it "lists all users including hidden users" do
      expect(knife.ui).to receive(:output).with(users)
      knife.run
    end
  end
end
