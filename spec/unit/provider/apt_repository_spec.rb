#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe "Chef::Provider::AptRepository" do
  # Now we are using the option --with-colons that works across old os versions
  # as well as the latest (16.10). This for both `apt-key` and `gpg` commands
  #
  # Output of the command:
  # => apt-key adv --list-public-keys --with-fingerprint --with-colons
  APT_KEY_FINGER = <<~EOF.freeze
    tru:t:1:1488924856:0:3:1:5
    pub:-:1024:17:40976EAF437D05B5:2004-09-12:::-:Ubuntu Archive Automatic Signing Key <ftpmaster@ubuntu.com>::scESC:
    fpr:::::::::630239CC130E1A7FD81A27B140976EAF437D05B5:
    sub:-:2048:16:251BEFF479164387:2004-09-12::::::e:
    pub:-:1024:17:46181433FBB75451:2004-12-30:::-:Ubuntu CD Image Automatic Signing Key <cdimage@ubuntu.com>::scSC:
    fpr:::::::::C5986B4F1257FFA86632CBA746181433FBB75451:
    pub:-:4096:1:3B4FE6ACC0B21F32:2012-05-11:::-:Ubuntu Archive Automatic Signing Key (2012) <ftpmaster@ubuntu.com>::scSC:
    fpr:::::::::790BC7277767219C42C86F933B4FE6ACC0B21F32:
    pub:-:4096:1:D94AA3F0EFE21092:2012-05-11:::-:Ubuntu CD Image Automatic Signing Key (2012) <cdimage@ubuntu.com>::scSC:
    fpr:::::::::843938DF228D22F7B3742BC0D94AA3F0EFE21092:
  EOF

  # Output of the command:
  # => gpg --with-fingerprint --with-colons [FILE]
  APG_GPG_FINGER = <<~EOF.freeze
    pub:-:1024:17:327574EE02A818DD:2009-04-22:::-:Cloudera Apt Repository:
    fpr:::::::::F36A89E33CC1BD0F71079007327574EE02A818DD:
    sub:-:2048:16:84080586D1CA74A1:2009-04-22::::
  EOF

  # Output of the command:
  # gpg --no-default-keyring --keyring ${keyring} --list-public-keys ${key}
  APG_GPG_KEYS_EXPIRED = <<~EOF.freeze
    pub   dsa1024 2009-04-22 [SC] [expired: 2018-02-22]
          F36A89E33CC1BD0F71079007327574EE02A818DD
    uid                      Cloudera Apt Repository
    sub   elg2048 2009-04-22 [E] [expired: 2018-02-22]
  EOF

  # Output of the command:
  # gpg --no-default-keyring --keyring ${keyring} --list-public-keys ${key}
  APG_GPG_KEYS_REVOKED = <<~EOF.freeze
    pub   dsa1024 2009-04-22 [SC] [revoked: 2018-02-22]
          F36A89E33CC1BD0F71079007327574EE02A818DD
    uid                      Cloudera Apt Repository
    sub   elg2048 2009-04-22 [E] [revoked: 2018-02-22]
  EOF

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:collection) { double("resource collection") }
  let(:new_resource) { Chef::Resource::AptRepository.new("multiverse", run_context) }
  let(:provider) { new_resource.provider_for_action(:add) }
  let(:keyring) { "/etc/apt/keyrings/ring.gpg" }
  let(:key) { "ASDF1234" }
  let(:keyserver) { "keyserver.ubuntu.com" }

  let(:apt_key_finger_cmd) do
    %w{apt-key adv --list-public-keys --with-fingerprint --with-colons}
  end

  let(:apt_key_finger) do
    double("shell_out", stdout: APT_KEY_FINGER, exitstatus: 0, error?: false)
  end

  let(:gpg_finger) do
    double("shell_out", stdout: APG_GPG_FINGER, exitstatus: 0, error?: false)
  end

  let(:gpg_shell_out_success) do
    double("shell_out", stdout: "pub  2048R/7BD9BF62 2011-08-19 nginx signing key <signing-key@nginx.com>",
                        exitstatus: 0, error?: false)
  end

  let(:gpg_shell_out_failure) do
    double("shell_out", stderr: "gpg: keybox '/etc/apt/keyrings/ring.gpg' created\ngpg: error reading key: No public key\n",
                        stdout: "",
                        exitstatus: 2, error?: true)
  end

  let(:gpg_shell_out_expired) do
    double("shell_out", stdout: APG_GPG_KEYS_EXPIRED, exitstatus: 0, error?: false)
  end

  let(:gpg_shell_out_revoked) do
    double("shell_out", stdout: APG_GPG_KEYS_REVOKED, exitstatus: 0, error?: false)
  end

  let(:apt_fingerprints) do
    %w{630239CC130E1A7FD81A27B140976EAF437D05B5
C5986B4F1257FFA86632CBA746181433FBB75451
790BC7277767219C42C86F933B4FE6ACC0B21F32
843938DF228D22F7B3742BC0D94AA3F0EFE21092}
  end

  let(:apt_public_keys) do
    %w{
      pub:-:1024:17:40976EAF437D05B5:2004-09-12
      pub:-:1024:17:46181433FBB75451:2004-12-30
      pub:-:4096:1:3B4FE6ACC0B21F32:2012-05-11
      pub:-:4096:1:D94AA3F0EFE21092:2012-05-11
    }
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end

  describe "#is_key_id?" do
    it "detects a key" do
      expect(provider.is_key_id?("A4FF2279")).to be_truthy
    end
    it "detects a key with a hex signifier" do
      expect(provider.is_key_id?("0xA4FF2279")).to be_truthy
    end
    it "rejects a key with the wrong length" do
      expect(provider.is_key_id?("4FF2279")).to be_falsey
    end
    it "rejects a key with non-hex characters" do
      expect(provider.is_key_id?("A4KF2279")).to be_falsey
    end
  end

  describe "#extract_fingerprints_from_cmd" do
    it "runs the desired command" do
      expect(provider).to receive(:shell_out).and_return(apt_key_finger)
      provider.extract_fingerprints_from_cmd(*apt_key_finger_cmd)
    end

    it "returns a list of key fingerprints" do
      expect(provider).to receive(:shell_out).and_return(apt_key_finger)
      expect(provider.extract_fingerprints_from_cmd(*apt_key_finger_cmd)).to eql(apt_fingerprints)
    end
  end

  describe "#extract_public_keys_from_cmd" do
    it "runs the desired command" do
      expect(provider).to receive(:shell_out).and_return(apt_key_finger)
      provider.extract_public_keys_from_cmd(*apt_key_finger_cmd)
    end

    it "returns a list of key fingerprints" do
      expect(provider).to receive(:shell_out).and_return(apt_key_finger)
      expect(provider.extract_public_keys_from_cmd(*apt_key_finger_cmd)).to eql(apt_public_keys)
    end
  end

  describe "#cookbook_name" do
    it "returns 'test' when the cookbook property is set" do
      new_resource.cookbook("test")
      expect(provider.cookbook_name).to eq("test")
    end
  end

  describe "#keyring_key_is_valid?" do
    it "returns true for a valid key" do
      expect(provider).to receive(:shell_out).and_return(gpg_shell_out_success)
      expect(provider.keyring_key_is_valid?(keyring, key)).to eql(true)
    end

    it "returns false when the key does not exist" do
      expect(provider).to receive(:shell_out).and_return(gpg_shell_out_failure)
      expect(provider.keyring_key_is_valid?(keyring, key)).to eql(false)
    end

    it "returns false when the key is expired" do
      expect(provider).to receive(:shell_out).and_return(gpg_shell_out_expired)
      expect(provider.keyring_key_is_valid?(keyring, key)).to eql(false)
    end

    it "returns false when the key has been revoked" do
      expect(provider).to receive(:shell_out).and_return(gpg_shell_out_revoked)
      expect(provider.keyring_key_is_valid?(keyring, key)).to eql(false)
    end
  end

  describe "#keyring_key_is_present?" do
    it "returns true for a key that exists" do
      expect(provider).to receive(:shell_out).and_return(gpg_shell_out_success)
      expect(provider.keyring_key_is_present?(keyring, key)).to eql(true)
    end

    it "returns false when the key is not present in the keyring" do
      expect(provider).to receive(:shell_out).and_return(gpg_shell_out_failure)
      expect(provider.keyring_key_is_present?(keyring, key)).to eql(false)
    end
  end

  describe "#no_new_keys?" do
    before do
      allow(provider).to receive(:extract_public_keys_from_cmd).with(*apt_key_finger_cmd).and_return(apt_public_keys)
    end

    let(:file) { "/tmp/remote-gpg-keyfile" }

    it "matches a set of keys" do
      allow(provider).to receive(:extract_public_keys_from_cmd)
        .with("gpg", "--with-fingerprint", "--with-colons", file)
        .and_return([apt_public_keys.first])
      expect(provider.no_new_keys?(file)).to be_truthy
    end

    it "notices missing keys" do
      allow(provider).to receive(:extract_public_keys_from_cmd)
        .with("gpg", "--with-fingerprint", "--with-colons", file)
        .and_return(%w{pub:-:4096:1:871920D1991BC93C:1537196506})
      expect(provider.no_new_keys?(file)).to be_falsey
    end
  end

  describe "#key_type" do
    it "returns :remote_file with an http URL" do
      expect(provider.key_resource_type("https://www.chef.io/key")).to eq(:remote_file)
    end

    it "returns :cookbook_file with a chef managed file" do
      expect(provider).to receive(:has_cookbook_file?).and_return(true)
      expect(provider.key_resource_type("/foo/bar.key")).to eq(:cookbook_file)
    end

    it "throws exception if an unknown file specified" do
      expect(provider).to receive(:has_cookbook_file?).and_return(false)
      expect { provider.key_resource_type("/foo/bar.key") }.to raise_error(Chef::Exceptions::FileNotFound)
    end
  end

  describe "#keyserver_install_cmd" do
    it "returns keyserver install command" do
      expect(provider.keyserver_install_cmd("ABC", "gpg.mit.edu")).to eq("apt-key adv --no-tty --recv --keyserver hkp://gpg.mit.edu:80 ABC")
    end

    it "uses proxy if key_proxy property is set" do
      new_resource.key_proxy("proxy.mycorp.dmz:3128")
      expect(provider.keyserver_install_cmd("ABC", "gpg.mit.edu")).to eq("apt-key adv --no-tty --recv --keyserver-options http-proxy=proxy.mycorp.dmz:3128 --keyserver hkp://gpg.mit.edu:80 ABC")
    end

    it "properly handles keyservers passed with hkp:// URIs" do
      expect(provider.keyserver_install_cmd("ABC", "hkp://gpg.mit.edu")).to eq("apt-key adv --no-tty --recv --keyserver hkp://gpg.mit.edu ABC")
    end
  end

  describe "#is_ppa_url" do
    it "returns true if the URL starts with ppa:" do
      expect(provider.is_ppa_url?("ppa://example.com")).to be_truthy
    end

    it "returns false if the URL does not start with ppa:" do
      expect(provider.is_ppa_url?("example.com")).to be_falsey
    end
  end

  describe "#repo_components" do
    it "returns 'main' if a PPA and components property not set" do
      expect(provider).to receive(:is_ppa_url?).and_return(true)
      expect(provider.repo_components).to eq("main")
    end

    it "returns components property if a PPA and components is set" do
      new_resource.components(["foo"])
      expect(provider).to receive(:is_ppa_url?).and_return(true)
      expect(provider.repo_components).to eq(["foo"])
    end

    it "returns components property if not a PPA" do
      new_resource.components(["foo"])
      expect(provider).to receive(:is_ppa_url?).and_return(false)
      expect(provider.repo_components).to eq(["foo"])
    end
  end

  describe "#install_key_from_keyserver_to_keyring" do
    it "does not raise an error when the key is valid" do
      expect(provider).to receive(:execute).and_return(nil)
      expect(provider).to receive(:keyring_key_is_valid?).and_return(true)
      expect { provider.install_key_from_keyserver_to_keyring(key, keyserver, keyring) }.not_to raise_error
    end

    it "raises an error with the key is invalid" do
      expect(provider).to receive(:execute).and_return(nil)
      expect(provider).to receive(:keyring_key_is_valid?).and_return(false)
      expect { provider.install_key_from_keyserver_to_keyring(key, keyserver, keyring) }.to raise_error(RuntimeError)
    end
  end

  describe "#install_ppa_key" do
    let(:url) { "https://launchpad.net/api/1.0/~chef/+archive/main" }
    let(:key) { "C5986B4F1257FFA86632CBA746181433FBB75451" }

    it "gets a key" do
      simples = double("HTTP")
      allow(simples).to receive(:get).and_return("\"#{key}\"")
      expect(Chef::HTTP::Simple).to receive(:new).with(url, {}).and_return(simples)
      expect(provider).to receive(:install_key_from_keyserver).with(key, keyserver)
      provider.install_ppa_key("chef", "main")
    end
  end

  describe "#make_ppa_url" do
    it "creates a URL" do
      expect(provider).to receive(:install_ppa_key).with("chef", "main").and_return(true)
      expect(provider.make_ppa_url("ppa:chef/main")).to eql("http://ppa.launchpad.net/chef/main/ubuntu")
    end
  end

  describe "#build_repo" do
    it "creates a repository string" do
      target = "deb      http://test/uri unstable main\n"
      expect(provider.build_repo("http://test/uri", "unstable", "main", false, nil, nil, [])).to eql(target)
    end

    it "creates a repository string with spaces" do
      target = "deb      http://test/uri%20with%20spaces unstable main\n"
      expect(provider.build_repo("http://test/uri with spaces", "unstable", "main", false, nil, nil, [])).to eql(target)
    end

    it "creates a repository string with no distribution" do
      target = "deb      http://test/uri main\n"
      expect(provider.build_repo("http://test/uri", nil, "main", false, nil, nil, [])).to eql(target)
    end

    it "creates a repository string with source" do
      target = "deb      http://test/uri unstable main\ndeb-src  http://test/uri unstable main\n"
      expect(provider.build_repo("http://test/uri", "unstable", "main", false, nil, nil, [], true)).to eql(target)
    end

    it "creates a repository string with trusted" do
      target = "deb      [trusted=yes] http://test/uri unstable main\n"
      expect(provider.build_repo("http://test/uri", "unstable", "main", true, nil, nil, [])).to eql(target)
    end

    it "creates a repository string with signed-by" do
      target = "deb      [signed-by=/etc/apt/keyrings/test.gpg] http://test/uri unstable main\n"
      expect(provider.build_repo("http://test/uri", "unstable", "main", false, nil, "/etc/apt/keyrings/test.gpg", [])).to eql(target)
    end

    it "creates a repository string with custom options" do
      target = "deb      [by-hash=no] http://test/uri unstable main\n"
      expect(provider.build_repo("http://test/uri", "unstable", "main", false, nil, nil, ["by-hash=no"])).to eql(target)
    end

    it "creates a repository string with trusted, arch, and custom options" do
      target = "deb      [arch=amd64 trusted=yes by-hash=no] http://test/uri unstable main\n"
      expect(provider.build_repo("http://test/uri", "unstable", "main", true, "amd64", nil, ["by-hash=no"])).to eql(target)
    end

    it "handles a ppa repo" do
      target = "deb      http://ppa.launchpad.net/chef/main/ubuntu unstable main\n"
      expect(provider).to receive(:make_ppa_url).with("ppa:chef/main").and_return("http://ppa.launchpad.net/chef/main/ubuntu")
      expect(provider.build_repo("ppa:chef/main", "unstable", "main", false, nil, nil, [])).to eql(target)
    end
  end
end
