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
require "chef/org"

describe Chef::Knife::OpcUserShow do

  before :each do
    @knife = Chef::Knife::OpcUserShow.new
    @user_name = "foobar"
    @knife.name_args << @user_name
    @org = double("Chef::Org")
    allow(Chef::Org).to receive(:new).and_return(@org)
    @key = "You don't come into cooking to get rich - Ramsay"
  end

  let(:rest) do
    Chef::Config[:chef_server_root] = "http://www.example.com"
    root_rest = double("rest")
    allow(Chef::ServerAPI).to receive(:new).and_return(root_rest)
  end

  let(:orgs) do
    [@org]
  end

  it "should load the user" do
    allow(@knife).to receive(:root_rest).and_return(rest)
    expect(rest).to receive(:get).with("users/#{@user_name}")
    @knife.run
  end

  it "should pretty print the output user" do
    allow(@knife).to receive(:root_rest).and_return(rest)
    expect(rest).to receive(:get).with("users/#{@user_name}")
    expect(@knife.ui).to receive(:output)
    @knife.run
  end

  it "should load the user with organisation" do
    @org_name = "abc_org"
    @knife.name_args << @user_name << @org_name
    result = { "organizations" => [] }
    @knife.config[:with_orgs] = true

    allow(@knife).to receive(:root_rest).and_return(rest)
    allow(@org).to receive(:[]).with("organization").and_return({ "name" => "test" })
    expect(rest).to receive(:get).with("users/#{@user_name}").and_return(result)
    expect(rest).to receive(:get).with("users/#{@user_name}/organizations").and_return(orgs)
    @knife.run
  end
end
