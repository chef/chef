#
# Author:: Matt Wrock (<matt@mattwrock.com>)
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
require "chef/mixin/powershell_exec"

describe Chef::Resource::PowershellPackageSource, :windows_only do
  include Chef::Mixin::PowershellExec

  let(:source_name) { "fake" }
  let(:url) { "https://www.nuget.org/api/v2" }
  let(:trusted) { true }

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::PowershellPackageSource.new("test powershell package source", run_context)
    new_resource.source_name source_name
    new_resource.url url
    new_resource.trusted trusted
    new_resource.provider_name provider_name
    new_resource
  end

  let(:provider) do
    provider = subject.provider_for_action(subject.action)
    provider
  end

  shared_examples "package_source" do
    context "register a package source" do
      after { remove_package_source }

      it "registers the package source" do
        subject.run_action(:register)
        expect(get_installed_package_source_name).to eq(source_name)
      end

      it "does not register the package source if already installed" do
        subject.run_action(:register)
        subject.run_action(:register)
        expect(subject).not_to be_updated_by_last_action
      end

      it "updates an existing package source if changed" do
        subject.run_action(:register)
        subject.trusted !trusted
        subject.run_action(:register)
        expect(subject).to be_updated_by_last_action
      end
    end

    context "unregister a package source" do
      it "unregisters the package source" do
        subject.run_action(:register)
        subject.run_action(:unregister)
        expect(get_installed_package_source_name).to be_empty
      end

      it "does not unregister the package source if not already installed" do
        subject.run_action(:unregister)
        expect(subject).not_to be_updated_by_last_action
      end
    end
  end

  context "with NuGet provider" do
    let(:provider_name) { "NuGet" }

    it_behaves_like "package_source"
  end

  context "with PowerShellGet provider" do
    let(:provider_name) { "PowerShellGet" }

    it_behaves_like "package_source"
  end

  def get_installed_package_source_name
    powershell_exec!("(Get-PackageSource -Name #{source_name} -ErrorAction SilentlyContinue).Name").result
  end

  def remove_package_source
    pkg_to_remove = Chef::Resource::PowershellPackageSource.new(source_name, run_context)
    pkg_to_remove.run_action(:unregister)
  end
end