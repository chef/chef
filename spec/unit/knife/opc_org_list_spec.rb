require "spec_helper"
require "chef/knife/opc_org_list"

describe Opc::OpcOrgList do

  let(:orgs) do
    {
      "org1" => "first",
      "org2" => "second",
      "hiddenhiddenhiddenhi" => "hidden",
    }
  end

  before :each do
    @rest = double("Chef::ServerAPI")
    allow(Chef::ServerAPI).to receive(:new).and_return(@rest)
    allow(@rest).to receive(:get).with("organizations").and_return(orgs)
    @knife = Chef::Knife::OpcOrgList.new
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
