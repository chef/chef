#
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Copyright:: Copyright 2019, Chef Software Inc.
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

describe Chef::TrainTransport do
  describe "load_credentials" do
    let(:transport) { Chef::TrainTransport.new }
    let(:good_credentials) { { "switch.cisco.com" => { "user" => "cisco", "password" => "cisco", "enable_password" => "secret" } } }

    before do
      allow(Chef::TrainTransport).to receive(:parse_credentials_file).and_return(good_credentials)
    end

    it "matches credentials when they exist" do
      expect(Chef::TrainTransport.load_credentials("switch.cisco.com")[:user]).to eq("cisco")
      expect(Chef::TrainTransport.load_credentials("switch.cisco.com")[:password]).to eq("cisco")
      expect(Chef::TrainTransport.load_credentials("switch.cisco.com")[:enable_password]).to eq("secret")
    end

    it "returns nil if there is no match" do
      expect(Chef::TrainTransport.load_credentials("router.unicorns.com")).to be_nil
    end

    # [foo.example.org]   => {"foo"=>{"example"=>{"org"=>{}}}}
    # ['foo.example.org'] => {"foo.example.org"=>{}}
    it "warns if the host has been split by toml" do
      allow(Chef::TrainTransport).to receive(:parse_credentials_file).and_return({ "foo" => { "example" => { "org" => {} } } })
      expect(Chef::Log).to receive(:warn).with(/as a Hash/)
      expect(Chef::Log).to receive(:warn).with(/Hostnames must be surrounded by single quotes/)
      expect(Chef::TrainTransport.load_credentials("foo.example.org")).to be_nil
    end
  end

  describe "credentials_file_path" do

    context "when a file path is specified by a config" do
      let(:cred_file_path) { "/somewhere/credentials" }

      before do
        tm_config = double("Config Context", host: "foo.example.org", credentials_file: cred_file_path)
        allow(Chef::Config).to receive(:target_mode).and_return(tm_config)
      end

      it "returns the path if it exists" do
        allow(File).to receive(:exists?).with(cred_file_path).and_return(true)
        expect(Chef::TrainTransport.credentials_file_path).to eq(cred_file_path)
      end

      it "raises an error if it does not exist" do
        allow(File).to receive(:exists?).with(cred_file_path).and_return(false)
        expect { Chef::TrainTransport.credentials_file_path }.to raise_error(ArgumentError, /does not exist/)
      end
    end

    it "returns the path to the default config file if it exists" do
      cred_file_path = Chef::Config.platform_specific_path("/etc/chef/foo.example.org/credentials")
      tm_config = double("Config Context", host: "foo.example.org", credentials_file: nil)
      allow(Chef::Config).to receive(:target_mode).and_return(tm_config)
      allow(File).to receive(:exists?).with(cred_file_path).and_return(true)
      expect(Chef::TrainTransport.credentials_file_path).to eq(cred_file_path)
    end
  end
end
