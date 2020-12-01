require "spec_helper"
require "chef/compliance/fetcher/chef_server"

describe Chef::Compliance::Fetcher::ChefServer do
  let(:node) do
    Chef::Node.new.tap do |n|
      n.default["audit"] = {}
    end
  end

  before :each do
    allow(Chef).to receive(:node).and_return(node)

    Chef::Config[:chef_server_url] = "http://127.0.0.1:8889/organizations/my_org"
  end

  describe ".resolve" do
    context "when target is a string" do
      it "should resolve a compliance URL" do
        res = Chef::Compliance::Fetcher::ChefServer.resolve("compliance://namespace/profile_name")

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::ChefServer)
        expected = "http://127.0.0.1:8889/organizations/my_org/owners/namespace/compliance/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "should add /compliance URL prefix if needed" do
        node.default["audit"]["fetcher"] = "chef-server"
        res = Chef::Compliance::Fetcher::ChefServer.resolve("compliance://namespace/profile_name")

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::ChefServer)
        expected = "http://127.0.0.1:8889/compliance/organizations/my_org/owners/namespace/compliance/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "includes user in the URL if present" do
        res = Chef::Compliance::Fetcher::ChefServer.resolve("compliance://username@namespace/profile_name")

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::ChefServer)
        expected = "http://127.0.0.1:8889/organizations/my_org/owners/username@namespace/compliance/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "returns nil with a non-compliance URL" do
        res = Chef::Compliance::Fetcher::ChefServer.resolve("http://github.com/chef-cookbooks/audit")

        expect(res).to eq(nil)
      end
    end

    context "when target is a hash" do
      it "should resolve a target with a version" do
        res = Chef::Compliance::Fetcher::ChefServer.resolve(
          compliance: "namespace/profile_name",
          version: "1.2.3"
        )

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::ChefServer)
        expected = "http://127.0.0.1:8889/organizations/my_org/owners/namespace/compliance/profile_name/version/1.2.3/tar"
        expect(res.target).to eq(expected)
      end

      it "should resolve a target without a version" do
        res = Chef::Compliance::Fetcher::ChefServer.resolve(
          compliance: "namespace/profile_name"
        )

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::ChefServer)
        expected = "http://127.0.0.1:8889/organizations/my_org/owners/namespace/compliance/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "includes user in the URL if present" do
        res = Chef::Compliance::Fetcher::ChefServer.resolve(
          compliance: "username@namespace/profile_name"
        )

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::ChefServer)
        expected = "http://127.0.0.1:8889/organizations/my_org/owners/username@namespace/compliance/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "returns nil with a non-profile Hash" do
        res = Chef::Compliance::Fetcher::ChefServer.resolve(
          profile: "namespace/profile_name",
          version: "1.2.3"
        )

        expect(res).to eq(nil)
      end
    end
  end
end
