require "spec_helper"
require "chef/compliance/fetcher/automate"

describe Chef::Compliance::Fetcher::Automate do
  describe ".resolve" do
    before do
      Chef::Config[:data_collector] = {
        server_url: "https://automate.test/data_collector",
        token: token,
      }
    end

    let(:token) { "fake_token" }

    context "when target is a string" do
      it "should resolve a compliance URL" do
        res = Chef::Compliance::Fetcher::Automate.resolve("compliance://namespace/profile_name")

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://automate.test/compliance/profiles/namespace/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "should resolve a compliance URL with a @ in the namespace" do
        res = Chef::Compliance::Fetcher::Automate.resolve("compliance://name@space/profile_name")

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://automate.test/compliance/profiles/name@space/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "includes the data collector token" do
        expect(Chef::Compliance::Fetcher::Automate).to receive(:new).with(
          "https://automate.test/compliance/profiles/namespace/profile_name/tar",
          hash_including("token" => token)
        ).and_call_original

        res = Chef::Compliance::Fetcher::Automate.resolve("compliance://namespace/profile_name")

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://automate.test/compliance/profiles/namespace/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "returns nil with a non-compliance URL" do
        res = Chef::Compliance::Fetcher::Automate.resolve("http://github.com/chef-cookbooks/audit")

        expect(res).to eq(nil)
      end
    end

    context "when target is a hash" do
      it "should resolve a target with a version" do
        res = Chef::Compliance::Fetcher::Automate.resolve(
          compliance: "namespace/profile_name",
          version: "1.2.3"
        )

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://automate.test/compliance/profiles/namespace/profile_name/version/1.2.3/tar"
        expect(res.target).to eq(expected)
      end

      it "should resolve a target without a version" do
        res = Chef::Compliance::Fetcher::Automate.resolve(
          compliance: "namespace/profile_name"
        )

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://automate.test/compliance/profiles/namespace/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "uses url key when present" do
        res = Chef::Compliance::Fetcher::Automate.resolve(
          compliance: "namespace/profile_name",
          version: "1.2.3",
          url: "https://profile.server.test/profiles/profile_name/1.2.3"
        )

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://profile.server.test/profiles/profile_name/1.2.3"
        expect(res.target).to eq(expected)
      end

      it "does not include token in the config when url key is present" do
        expect(Chef::Compliance::Fetcher::Automate).to receive(:new).with(
          "https://profile.server.test/profiles/profile_name/1.2.3",
          hash_including("token" => nil)
        ).and_call_original

        res = Chef::Compliance::Fetcher::Automate.resolve(
          compliance: "namespace/profile_name",
          version: "1.2.3",
          url: "https://profile.server.test/profiles/profile_name/1.2.3"
        )

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://profile.server.test/profiles/profile_name/1.2.3"
        expect(res.target).to eq(expected)
      end

      it "includes the data collector token" do
        expect(Chef::Compliance::Fetcher::Automate).to receive(:new).with(
          "https://automate.test/compliance/profiles/namespace/profile_name/tar",
          hash_including("token" => token)
        ).and_call_original

        res = Chef::Compliance::Fetcher::Automate.resolve(compliance: "namespace/profile_name")

        expect(res).to be_kind_of(Chef::Compliance::Fetcher::Automate)
        expected = "https://automate.test/compliance/profiles/namespace/profile_name/tar"
        expect(res.target).to eq(expected)
      end

      it "returns nil with a non-profile Hash" do
        res = Chef::Compliance::Fetcher::Automate.resolve(
          profile: "namespace/profile_name",
          version: "1.2.3"
        )

        expect(res).to eq(nil)
      end
    end
  end
end
