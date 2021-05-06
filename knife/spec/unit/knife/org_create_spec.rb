#
# Copyright:: Copyright 2014-2016 Chef Software, Inc.
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

describe Chef::Knife::OrgCreate do
  before :each do
    Chef::Knife::OrgCreate.load_deps
    @knife = Chef::Knife::OrgCreate.new
    @org = double("Chef::Org")
    allow(Chef::Org).to receive(:new).and_return(@org)
    @key = "You don't come into cooking to get rich - Ramsay"
    allow(@org).to receive(:private_key).and_return(@key)
    @org_name = "ss"
    @org_full_name = "secretsauce"
  end

  let(:org_args) do
    {
      name: @org_name,
      full_name: @org_full_name,
    }
  end

  describe "with no org_name and org_fullname" do
    it "fails with an informative message" do
      expect(@knife.ui).to receive(:fatal).with("You must specify an ORG_NAME and an ORG_FULL_NAME")
      expect(@knife).to receive(:show_usage)
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end

  describe "with org_name and org_fullname" do
    before :each do
      @knife.name_args << @org_name << @org_full_name
    end

    it "creates an org" do
      expect(@org).to receive(:create).and_return(@org)
      expect(@org).to receive(:full_name).with("secretsauce")
      expect(@knife.ui).to receive(:msg).with(@key)
      @knife.run
    end

    context "with --assocation-user" do
      before :each do
        @knife.config[:association_user] = "ramsay"
      end

      it "creates an org, associates a user, and adds it to the admins group" do
        expect(@org).to receive(:full_name).with("secretsauce")
        expect(@org).to receive(:create).and_return(@org)
        expect(@org).to receive(:associate_user).with("ramsay")
        expect(@org).to receive(:add_user_to_group).with("admins", "ramsay")
        expect(@org).to receive(:add_user_to_group).with("billing-admins", "ramsay")
        expect(@knife.ui).to receive(:msg).with(@key)
        @knife.run
      end
    end
  end
end
