#
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

describe Chef::TargetModeConfig do
  describe ".apply!" do
    context "when config[:target] and Chef::Config.target are both unset" do
      it "does not enable target mode" do
        Chef::TargetModeConfig.apply!({})
        expect(Chef::Config.target_mode.enabled).to be false
      end
    end

    context "when config[:target] is given" do
      let(:config) { { target: "target.example.com" } }

      it "enables target_mode" do
        Chef::TargetModeConfig.apply!(config)
        expect(Chef::Config.target_mode.enabled).to be true
      end

      it "sets target_mode.host to the target" do
        Chef::TargetModeConfig.apply!(config)
        expect(Chef::Config.target_mode.host).to eq("target.example.com")
      end

      it "sets node_name to the target host" do
        Chef::TargetModeConfig.apply!(config)
        expect(Chef::Config[:node_name]).to eq("target.example.com")
      end
    end

    context "when node_name is already set before target mode is applied" do
      let(:config) { { target: "target.example.com" } }

      before do
        Chef::Config[:node_name] = "my-workstation"
        Chef::Config[:client_key] = "/etc/chef/client.pem"
      end

      it "overrides node_name with the target host" do
        Chef::TargetModeConfig.apply!(config)
        expect(Chef::Config[:node_name]).to eq("target.example.com")
      end

      it "preserves the original identity as api_client_name/api_client_key" do
        Chef::TargetModeConfig.apply!(config)
        expect(Chef::Config[:api_client_name]).to eq("my-workstation")
        expect(Chef::Config[:api_client_key]).to eq("/etc/chef/client.pem")
      end
    end

    context "when config[:target] is a Train URI" do
      let(:config) { { target: "ssh://bob@target.example.com" } }

      before do
        allow(Train).to receive(:unpack_target_from_uri).with("ssh://bob@target.example.com").and_return(
          { host: "target.example.com", user: "bob", protocol: "ssh" }
        )
      end

      it "parses the URI via Train and enables target_mode" do
        Chef::TargetModeConfig.apply!(config)
        expect(Chef::Config.target_mode.enabled).to be true
        expect(Chef::Config[:node_name]).to eq("target.example.com")
      end
    end

    context "when Chef::Config.target is set instead of config[:target]" do
      before do
        Chef::Config.target = "target.example.com"
      end

      it "still enables target mode" do
        Chef::TargetModeConfig.apply!({})
        expect(Chef::Config.target_mode.enabled).to be true
        expect(Chef::Config.target_mode.host).to eq("target.example.com")
      end
    end
  end
end
