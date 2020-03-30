#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

  let(:pkgutil_cli_exists) do
    double("shell_out", stdout: "com.apple.pkg.CLTools_Executables", exitstatus: 0, error?: false)
  end

  let(:pkgutil_cli_doesnt_exist) do
    double("shell_out", exitstatus: 1, error?: true)
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

  describe "#xcode_cli_installed?" do
    it "returns true if the pkgutil lists the package" do
      allow(provider).to receive(:shell_out).with("pkgutil", "--pkgs=com.apple.pkg.CLTools_Executables").and_return(pkgutil_cli_exists)
      expect(provider.xcode_cli_installed?).to eql(true)
    end

    it "returns false if the pkgutil doesn't list the package" do
      allow(provider).to receive(:shell_out).with("pkgutil", "--pkgs=com.apple.pkg.CLTools_Executables").and_return(pkgutil_cli_doesnt_exist)
      expect(provider.xcode_cli_installed?).to eql(false)
    end
  end
end
