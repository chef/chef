#
# Author:: Steven Danna (<steve@chef.io>)
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

require "knife_spec_helper"
require "chef/org"

Chef::Knife::UserShow.load_deps

describe Chef::Knife::UserShow do
  let(:knife) { Chef::Knife::UserShow.new }
  let(:user_mock) { double("user_mock") }
  let(:root_rest) { double("Chef::ServerAPI") }

  before :each do
    @user_name = "foobar"
    @password = "abc123"
    @user = double("Chef::User")
    allow(@user).to receive(:root_rest).and_return(root_rest)
    # allow(Chef::User).to receive(:new).and_return(@user)
    @key = "You don't come into cooking to get rich - Ramsay"
  end

  describe "withot organisation argument" do
    before do
      knife.name_args = [ "my_user" ]
      allow(user_mock).to receive(:username).and_return("my_user")
    end

    it "should load the user" do
      expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
      expect(@user.root_rest).to receive(:get).with("users/my_user")
      knife.run
    end

    it "loads and displays the user" do
      expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
      expect(@user.root_rest).to receive(:get).with("users/my_user")
      expect(knife).to receive(:format_for_display)
      knife.run
    end

    it "prints usage and exits when a user name is not provided" do
      knife.name_args = []
      expect(knife).to receive(:show_usage)
      expect(knife.ui).to receive(:fatal)
      expect { knife.run }.to raise_error(SystemExit)
    end
  end

  describe "with organisation argument" do
    before :each do
      @user_name = "foobar"
      @org_name = "abc_org"
      knife.name_args << @user_name << @org_name
      @org = double("Chef::Org")
      allow(Chef::Org).to receive(:new).and_return(@org)
      @key = "You don't come into cooking to get rich - Ramsay"
    end

    let(:orgs) do
      [@org]
    end

    it "should load the user with organisation" do

      result = { "organizations" => [] }
      knife.config[:with_orgs] = true

      expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
      allow(@org).to receive(:[]).with("organization").and_return({ "name" => "test" })
      expect(@user.root_rest).to receive(:get).with("users/#{@user_name}").and_return(result)
      expect(@user.root_rest).to receive(:get).with("users/#{@user_name}/organizations").and_return(orgs)
      knife.run
    end
  end
end
