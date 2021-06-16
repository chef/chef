#
# Author:: Tim Smith (<tsmith@chef.io>)
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

describe Chef::Provider::ZypperRepository do
  # Output of the command:
  # => rpm -qa gpg-pubkey*
  ZYPPER_RPM_KEYS = <<~EOF.freeze
    gpg-pubkey-307e3d54-4be01a65
    gpg-pubkey-3dbdc284-53674dd4
  EOF

  # Output of the command:
  # => gpg --with-fingerprint [FILE]
  ZYPPER_GPG_20 = <<~EOF.freeze
    pub  2048R/3DBDC284 2011-08-19 [expires: 2024-06-14]
          Key fingerprint = 573B FD6B 3D8F BC64 1079  A6AB ABF5 BD82 7BD9 BF62
    uid                            nginx signing key <signing-key@nginx.com>
  EOF

  # Output of the command:
  # => gpg --import-options import-show --dry-run --import --with-colons [FILE]
  ZYPPER_GPG_22 = <<~EOF.freeze
    pub:-:2048:1:ABF5BD827BD9BF62:1313747554:1718374819::-:::scSC::::::23::0:
    fpr:::::::::573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62:
    uid:-::::1466086904::F18C4DBBFCB45099ABB59088DB6B252FA7E9FB41::nginx signing key <signing-key@nginx.com>::::::::::0:
    gpg: Total number processed: 1
  EOF

  # Output of the command:
  # -> gpg --version
  ZYPPER_GPG_VERSION = <<~EOF.freeze
    gpg (GnuPG) 2.2.20
    libgcrypt 1.8.5
    Copyright (C) 2020 Free Software Foundation, Inc.
    License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

    Home: /Users/tsmith/.gnupg
    Supported algorithms:
    Pubkey: RSA, ELG, DSA, ECDH, ECDSA, EDDSA
    Cipher: IDEA, 3DES, CAST5, BLOWFISH, AES, AES192, AES256, TWOFISH,
            CAMELLIA128, CAMELLIA192, CAMELLIA256
    Hash: SHA1, RIPEMD160, SHA256, SHA384, SHA512, SHA224
    Compression: Uncompressed, ZIP, ZLIB, BZIP2
  EOF

  let(:new_resource) { Chef::Resource::ZypperRepository.new("Nginx Repository") }
  let(:logger) { double("Mixlib::Log::Child").as_null_object }
  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    allow(run_context).to receive(:logger).and_return(logger)
    Chef::Provider::ZypperRepository.new(new_resource, run_context)
  end

  let(:rpm_key_finger) do
    double("shell_out", stdout: ZYPPER_RPM_KEYS, exitstatus: 0, error?: false)
  end

  let(:gpg_20) do
    double("shell_out", stdout: ZYPPER_GPG_20, exitstatus: 0, error?: false)
  end

  let(:gpg_22) do
    double("shell_out", stdout: ZYPPER_GPG_22, exitstatus: 0, error?: false)
  end

  let(:gpg_ver) do
    double("shell_out", stdout: ZYPPER_GPG_VERSION, exitstatus: 0, error?: false)
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end

  describe "#action_create" do
    it "skips key import if gpgautoimportkeys is false" do
      new_resource.gpgautoimportkeys(false)
      expect(provider).to receive(:declare_resource)
      expect(logger).to receive(:debug)
      provider.run_action(:create)
    end
  end

  describe "#escaped_repo_name" do
    it "returns an escaped repo name" do
      expect(provider.escaped_repo_name).to eq('Nginx\\ Repository')
    end
  end

  describe "#key_type" do
    it "returns :remote_file with an http URL" do
      expect(provider.key_type("https://www.chef.io/key")).to eq(:remote_file)
    end

    it "returns :cookbook_file with a chef managed file" do
      expect(provider).to receive(:has_cookbook_file?).and_return(true)
      expect(provider.key_type("/foo/nginx.key")).to eq(:cookbook_file)
    end

    it "throws exception if an unknown file specified" do
      expect(provider).to receive(:has_cookbook_file?).and_return(false)
      expect { provider.key_type("/foo/nginx.key") }.to raise_error(Chef::Exceptions::FileNotFound)
    end
  end

  describe "#key_installed?" do
    before do
      expect(provider).to receive(:shell_out).with("/bin/rpm -qa gpg-pubkey*").and_return(rpm_key_finger)
    end

    it "returns true if the key is installed" do
      expect(provider).to receive(:short_key_id).and_return("3dbdc284")
      expect(provider.key_installed?("/foo/nginx.key")).to be_truthy
    end

    it "returns false if the key is not installed" do
      expect(provider).to receive(:short_key_id).and_return("BOGUS")
      expect(provider.key_installed?("/foo/nginx.key")).to be_falsey
    end
  end

  describe "#gpg_version" do
    it "returns the gpg version by shelling out to gpg" do
      expect(provider).to receive(:shell_out!).with("gpg --version").and_return(gpg_ver)
      expect(provider.gpg_version).to eq(Gem::Version.new("2.2.20"))
    end
  end

  describe "#short_key_id" do
    it "returns the short key ID via running a dry-run import on gpg 2.2+" do
      expect(provider).to receive(:gpg_version).and_return(Gem::Version.new("2.2"))
      expect(provider).to receive(:shell_out!).with("gpg --import-options import-show --dry-run --import --with-colons /foo/nginx.key").and_return(gpg_22)
      expect(provider.short_key_id("/foo/nginx.key")).to eq("7bd9bf62")
    end

    it "returns the short key ID via --with-fingerpint on gpg < 2.2" do
      expect(provider).to receive(:gpg_version).and_return(Gem::Version.new("2.0"))
      expect(provider).to receive(:shell_out!).with("gpg --with-fingerprint /foo/nginx.key").and_return(gpg_20)
      expect(provider.short_key_id("/foo/nginx.key")).to eq("3dbdc284")
    end
  end

  describe "#install_gpg_keys" do
    it "skips installing the key if an empty array for key URL is passed" do
      expect(logger).to receive(:debug)
      provider.install_gpg_keys([])
    end
  end
end
