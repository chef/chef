require "spec_helper"
require "chef/org"
require "chef/org/group_operations"
require "chef/knife/opc_org_create"

describe Opc::OpcOrgCreate do
  before :each do
    Chef::Knife::OpcOrgCreate.load_deps
    @knife = Chef::Knife::OpcOrgCreate.new
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
