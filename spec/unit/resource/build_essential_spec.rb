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

describe Chef::Resource::BuildEssential do

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::BuildEssential.new("foo", run_context) }
  let(:provider) { resource.provider_for_action(:install) }

  let(:softwareupdate_catalina_and_later) do
    double("shell_out", exitstatus: 0, error!: nil, stdout: "Software Update Tool\n\nFinding available software\nSoftware Update found the following new or updated software:\n* Label: Command Line Tools for Xcode-11.0\n\tTitle: Command Line Tools for Xcode, Version: 11.0, Size: 224868K, Recommended: YES, \n")
  end

  let(:softwareupdate_catalina_and_later_no_cli) do
    double("shell_out", exitstatus: 0, error!: nil, stdout: "Software Update Tool\n\nFinding available software\nSoftware Update found the following new or updated software:\n* Label: Chef Infra Client\n\tTitle: Chef Infra Client, Version: 17.0.208, Size: 224868K, Recommended: YES, \n")
  end

  let(:softwareupdate_pre_catalina) do
    double("shell_out", exitstatus: 0, error!: nil, stdout: "Software Update Tool\n\nFinding available software\nSoftware Update found the following new or updated software:\n   * Command Line Tools (macOS High Sierra version 10.13) for Xcode-10.0\n")
  end

  it "has a resource name of :build_essential" do
    expect(resource.resource_name).to eql(:build_essential)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install action" do
    expect { resource.action :install }.not_to raise_error
  end

  context "when not settting a resource name" do
    let(:resource) { Chef::Resource::BuildEssential.new(nil) }

    it "the name defaults to an empty string" do
      expect(resource.name).to eql("")
    end
  end

  describe "#xcode_cli_package_label" do
    it "returns a package name on macOS < 10.15" do
      allow(provider).to receive(:shell_out).with("softwareupdate", "--list").and_return(softwareupdate_pre_catalina)
      expect(provider.xcode_cli_package_label).to eql("Command Line Tools (macOS High Sierra version 10.13) for Xcode-10.0")
    end

    it "returns a package name on macOS 10.15+" do
      allow(provider).to receive(:shell_out).with("softwareupdate", "--list").and_return(softwareupdate_catalina_and_later)
      expect(provider.xcode_cli_package_label).to eql("Command Line Tools for Xcode-11.0")
    end

    it "returns nil if no update is listed" do
      allow(provider).to receive(:shell_out).with("softwareupdate", "--list").and_return(softwareupdate_catalina_and_later_no_cli)
      expect(provider.xcode_cli_package_label).to be_nil
    end

  end
end
