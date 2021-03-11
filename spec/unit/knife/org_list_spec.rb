#
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

describe Chef::Knife::OrgList do

  let(:root_rest) { double("Chef::ServerAPI") }

  let(:orgs) do
    {
      "org1" => "first",
      "org2" => "second",
      "hiddenhiddenhiddenhi" => "hidden",
    }
  end

  before :each do
    @org = double("Chef::Org")
    @knife = Chef::Knife::OrgList.new
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
    allow(root_rest).to receive(:get).with("organizations").and_return(orgs)
  end

  describe "with no arguments" do
    it "lists all non hidden orgs" do
      expect(@knife.ui).to receive(:output).with(%w{org1 org2})
      @knife.run
    end

  end

  describe "with all_orgs argument" do
    before do
      @knife.config[:all_orgs] = true
    end

    it "lists all orgs including hidden orgs" do
      expect(@knife.ui).to receive(:output).with(%w{hiddenhiddenhiddenhi org1 org2})
      @knife.run
    end
  end
end
