require "spec_helper"
require "chef/org"
require "chef/org/group_operations"
require "chef/knife/opc_org_user_add"

describe Opc::OpcOrgUserAdd do
  context "with --admin" do
    subject(:knife) { Chef::Knife::OpcOrgUserAdd.new }
    let(:org) { double("Chef::Org") }

    it "adds the user to admins and billing-admins groups" do
      allow(Chef::Org).to receive(:new).and_return(org)

      knife.config[:admin] = true
      knife.name_args = %w{testorg testuser}

      expect(org).to receive(:associate_user).with("testuser")
      expect(org).to receive(:add_user_to_group).with("admins", "testuser")
      expect(org).to receive(:add_user_to_group).with("billing-admins", "testuser")

      knife.run
    end
  end
end
