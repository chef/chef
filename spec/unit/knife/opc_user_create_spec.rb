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

describe Opc::OpcUserCreate do

  before :each do
    @knife = Chef::Knife::OpcUserCreate.new
    @user_name = "foobar"
    @first_name = "foo"
    @last_name = "bar"
    @email = "abc@test.com"
    @password = "t123"
    @knife.config[:yes] = true
  end

  let(:rest) do
    Chef::Config[:chef_server_root] = "http://www.example.com"
    root_rest = double("rest")
    allow(Chef::ServerAPI).to receive(:new).and_return(root_rest)
  end

  describe "with no user_name and user_fullname" do

    before :each do
      @knife.config[:orgname] = "ramsay"
    end

    it "fails with an informative message" do
      expect(@knife.ui).to receive(:fatal).with("Wrong number of arguments")
      expect(@knife).to receive(:show_usage)
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end

  describe "with user_name, first_name, last_name, email and password" do
    before :each do
      @user = double("Chef::User")
      allow(Chef::User).to receive(:new).and_return(@user)
      @key = "You don't come into cooking to get rich - Ramsay"
      allow(@user).to receive(:[]).with("private_key").and_return(@key)
      @knife.name_args << @user_name << @first_name << @last_name << @email << @password
    end

    it "creates an user" do
      allow(@knife).to receive(:root_rest).and_return(rest)
      expect(rest).to receive(:post).and_return(@user)
      expect(@knife.ui).to receive(:msg).with(@key)
      @knife.run
    end

    context "with --orgname" do
      before :each do
        @knife.config[:orgname] = "ramsay"
        @uri = "http://www.example.com/1"
        allow(@user).to receive(:[]).with("uri").and_return(@uri)
      end

      let(:request_body) {
        { user: @user_name }
      }

      it "creates an user, associates a user, and adds it to the admins group" do
        allow(@knife).to receive(:root_rest).and_return(rest)
        expect(rest).to receive(:post).and_return(@user)
        expect(rest).to receive(:post).with("organizations/ramsay/association_requests", request_body).and_return(@user)
        expect(rest).to receive(:put).with("users/foobar/association_requests/1", { response: "accept" })
        @knife.run
      end
    end
  end

  describe "with prompt password" do
    before :each do
      @user = double("Chef::User")
      allow(Chef::User).to receive(:new).and_return(@user)
      @key = "You don't come into cooking to get rich - Ramsay"
      allow(@user).to receive(:[]).with("private_key").and_return(@key)
      @knife.config[:passwordprompt] = true
      @knife.name_args << @user_name << @first_name << @last_name << @email
    end

    it "creates an user" do
      allow(@knife).to receive(:root_rest).and_return(rest)
      expect(rest).to receive(:post).and_return(@user)
      expect(@knife.ui).to receive(:msg).with(@key)
      @knife.run
    end
  end

  describe "should raise prompt password error" do
    before :each do
      @user = double("Chef::User")
      allow(Chef::User).to receive(:new).and_return(@user)
      @key = "You don't come into cooking to get rich - Ramsay"
      allow(@user).to receive(:[]).with("private_key").and_return(@key)
      @knife.name_args << @user_name << @first_name << @last_name << @email
    end

    it "fails with an informative message" do
      expect(@knife.ui).to receive(:fatal).with("You must either provide a password or use the --prompt-for-password (-p) option")
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end
end
