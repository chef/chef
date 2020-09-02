#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2011-2016 Chef Software, Inc.
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
require "chef/org"

describe Chef::Knife::UserShow do
  let(:knife) { Chef::Knife::UserShow.new }
  let(:user_mock) { double("user_mock") }

  let(:rest) do
    Chef::Config[:chef_server_root] = "http://www.example.com"
    root_rest = double("rest")
    allow(Chef::ServerAPI).to receive(:new).and_return(root_rest)
  end

  describe "withot organisation argument" do
    before do
      knife.name_args = [ "my_user" ]
      allow(user_mock).to receive(:username).and_return("my_user")
    end

    it "should load the user" do
      allow(knife).to receive(:root_rest).and_return(rest)
      expect(rest).to receive(:get).with("users/my_user")
      knife.run
    end

    it "loads and displays the user" do
      allow(knife).to receive(:root_rest).and_return(rest)
      expect(rest).to receive(:get).with("users/my_user")
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

      allow(knife).to receive(:root_rest).and_return(rest)
      allow(@org).to receive(:[]).with("organization").and_return({ "name" => "test" })
      expect(rest).to receive(:get).with("users/#{@user_name}").and_return(result)
      expect(rest).to receive(:get).with("users/#{@user_name}/organizations").and_return(orgs)
      knife.run
    end
  end
end
