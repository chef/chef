#
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

describe Chef::Resource::RhsmRepo do

  let(:resource) { Chef::Resource::RhsmRepo.new("fakey_fakerton") }
  let(:provider) { resource.provider_for_action(:enable) }

  it "has a resource name of :rhsm_repo" do
    expect(resource.resource_name).to eql(:rhsm_repo)
  end

  it "the repo_name property is the name_property" do
    expect(resource.repo_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :enable" do
    expect(resource.action).to eql([:enable])
  end

  it "supports :disable, :enable actions" do
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
  end

  describe "#repo_enabled?" do
    let(:cmd)    { double("cmd") }
    let(:output) { "Repo ID:    repo123" }

    before do
      allow(Mixlib::ShellOut).to receive(:new).and_return(cmd)
      allow(cmd).to receive(:run_command)
      allow(cmd).to receive(:live_stream).and_return(output)
      allow(cmd).to receive(:stdout).and_return(output)
    end

    context "when the repo provided matches the output" do
      it "returns true" do
        expect(provider.repo_enabled?("repo123")).to eq(true)
      end
    end

    context "when the repo provided does not match the output" do
      it "returns false" do
        expect(provider.repo_enabled?("differentrepo")).to eq(false)
      end
    end

    context "when user pass wildcard" do
      it "returns true" do
        expect(provider.repo_enabled?("*")).to eq(true)
      end
    end
  end
end
