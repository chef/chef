#
# Author:: Snehal Dwivedi (<sdwivedi@msystechnologies.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef/knife/opc_user_list"

describe Opc::OpcUserList do

  let(:users) do
    {
      "user1" => "first",
      "user2" => "second",
    }
  end

  before :each do
    @rest = double("Chef::ServerAPI")
    allow(Chef::ServerAPI).to receive(:new).and_return(@rest)
    allow(@rest).to receive(:get).with("users").and_return(users)
    @knife = Chef::Knife::OpcUserList.new
  end

  describe "with no arguments" do
    it "lists all non users" do
      expect(@knife.ui).to receive(:output).with(%w{user1 user2})
      @knife.run
    end

  end

  describe "with all_users argument" do
    before do
      @knife.config[:all_users] = true
    end

    it "lists all users including hidden users" do
      expect(@knife.ui).to receive(:output).with(%w{user1 user2})
      @knife.run
    end
  end
end
