#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2017-2018, Chef Software Inc.
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

# Output of the command:
# => rpm -qa gpg-pubkey*
RPM_KEYS = <<~EOF.freeze
  gpg-pubkey-307e3d54-4be01a65
  gpg-pubkey-3dbdc284-53674dd4
EOF

# Output of the command:
# => gpg --with-fingerprint [FILE]
GPG_FINGER = <<~EOF.freeze
  pub  2048R/3DBDC284 2011-08-19 [expires: 2024-06-14]
        Key fingerprint = 573B FD6B 3D8F BC64 1079  A6AB ABF5 BD82 7BD9 BF62
  uid                            nginx signing key <signing-key@nginx.com>
EOF

describe Chef::Provider::ZypperRepository do
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
    double("shell_out", stdout: RPM_KEYS, exitstatus: 0, error?: false)
  end

  let(:gpg_finger) do
    double("shell_out", stdout: GPG_FINGER, exitstatus: 0, error?: false)
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end

  describe "#action_create" do
    it "skips key import if gpgautoimportkeys is false" do
      new_resource.gpgautoimportkeys(false)
      expect(provider).to receive(:declare_resource)
      expect(logger).to receive(:trace)
      provider.run_action(:create)
    end
  end

  describe "#escaped_repo_name" do
    it "returns an escaped repo name" do
      expect(provider.escaped_repo_name).to eq('Nginx\\ Repository')
    end
  end

  describe "#cookbook_name" do
    it "returns 'test' when the cookbook property is set" do
      new_resource.cookbook("test")
      expect(provider.cookbook_name).to eq("test")
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
      expect(provider).to receive(:shell_out).with("rpm -qa gpg-pubkey*").and_return(rpm_key_finger)
    end

    it "returns true if the key is installed" do
      expect(provider).to receive(:key_fingerprint).and_return("3dbdc284")
      expect(provider.key_installed?("/foo/nginx.key")).to be_truthy
    end

    it "returns false if the key is not installed" do
      expect(provider).to receive(:key_fingerprint).and_return("BOGUS")
      expect(provider.key_installed?("/foo/nginx.key")).to be_falsey
    end
  end

  describe "#key_fingerprint" do
    it "returns the key's fingerprint" do
      expect(provider).to receive(:shell_out!).with("gpg --with-fingerprint /foo/nginx.key").and_return(gpg_finger)
      expect(provider.key_fingerprint("/foo/nginx.key")).to eq("3dbdc284")
    end
  end

  describe "#install_gpg_key" do
    it "skips installing the key if a nil value for key is passed" do
      expect(logger).to receive(:trace)
      provider.install_gpg_key(nil)
    end
  end
end
