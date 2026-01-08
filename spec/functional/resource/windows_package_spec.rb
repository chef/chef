#
# Author:: Matt Wrock (<matt@mattwrock.com>)
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

describe Chef::Resource::WindowsPackage, :windows_only, :volatile do
  let(:pkg_name) { nil }
  let(:pkg_path) { nil }
  let(:pkg_checksum) { nil }
  let(:pkg_version) { nil }
  let(:pkg_type) { nil }
  let(:pkg_options) { nil }
  let(:remote_file_attributes) { nil }
  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::WindowsPackage.new(pkg_name, run_context)
    new_resource.source pkg_path if pkg_path
    new_resource.version pkg_version
    new_resource.installer_type pkg_type
    new_resource.options pkg_options
    new_resource.checksum pkg_checksum
    new_resource.remote_file_attributes
    new_resource
  end

  describe "install package" do
    let(:pkg_name) { "Microsoft Visual C++ 2005 Redistributable" }
    let(:pkg_checksum) { "4ee4da0fe62d5fa1b5e80c6e6d88a4a2f8b3b140c35da51053d0d7b72a381d29" }
    let(:pkg_path) { "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE" }
    let(:pkg_checksum) { nil }
    let(:pkg_type) { :custom }
    let(:pkg_options) { "/Q" }

    it "updates resource on first install" do
      subject.run_action(:install)
      expect(subject).to be_updated_by_last_action
    end

    it "does not update resource when already installed" do
      subject.run_action(:install)
      expect(subject).not_to be_updated_by_last_action
    end

    context "installing additional version" do
      let(:pkg_path) { "https://download.microsoft.com/download/6/B/B/6BB661D6-A8AE-4819-B79F-236472F6070C/vcredist_x86.exe" }
      let(:pkg_checksum) { "d6832398e3bc9156a660745f427dc1c2392ce4e9a872e04f41f62d0c6bae07a8" }
      let(:pkg_version) { "8.0.59193" }

      it "installs older version" do
        subject.run_action(:install)
        expect(subject).to be_updated_by_last_action
      end
    end

    describe "removing package" do
      subject { Chef::Resource::WindowsPackage.new(pkg_name, run_context) }

      context "multiple versions and a version given to remove" do
        before { subject.version("8.0.59193") }

        it "removes specified version" do
          subject.run_action(:remove)
          expect(subject).to be_updated_by_last_action
          prov = subject.provider_for_action(:remove)
          prov.load_current_resource
          expect(prov.current_version_array).to eq([["8.0.61001"]])
        end
      end

      context "single version installed and no version given to remove" do
        it "removes last remaining version" do
          subject.run_action(:remove)
          expect(subject).to be_updated_by_last_action
          prov = subject.provider_for_action(:remove)
          prov.load_current_resource
          expect(prov.current_version_array).to eq([nil])
        end
      end

      describe "removing multiple versions at once" do
        let(:pkg_version) { nil }
        before do
          install1 = Chef::Resource::WindowsPackage.new(pkg_name, run_context)
          install1.source pkg_path
          install1.version pkg_version
          install1.installer_type pkg_type
          install1.options pkg_options
          install1.run_action(:install)

          install2 = Chef::Resource::WindowsPackage.new(pkg_name, run_context)
          install2.source "https://download.microsoft.com/download/6/B/B/6BB661D6-A8AE-4819-B79F-236472F6070C/vcredist_x86.exe"
          install2.version "8.0.59193"
          install2.installer_type pkg_type
          install2.options pkg_options
          install2.run_action(:install)
        end

        it "removes all versions" do
          subject.run_action(:remove)
          expect(subject).to be_updated_by_last_action
          prov = subject.provider_for_action(:remove)
          prov.load_current_resource
          expect(prov.current_version_array).to eq([nil])
        end
      end
    end
  end

  describe "package version and installer type" do
    after { subject.run_action(:remove) }

    context "null soft" do
      let(:pkg_name) { "Ultra Defragmenter" }
      let(:pkg_path) { "http://iweb.dl.sourceforge.net/project/ultradefrag/stable-release/6.1.1/ultradefrag-6.1.1.bin.amd64.exe" }
      let(:pkg_checksum) { "11d53ed4c426c8c867ad43f142b7904226ffd9938c02e37086913620d79e3c09" }

      it "finds the correct installer type" do
        subject.run_action(:install)
        expect(subject.provider_for_action(:install).installer_type).to eq(:nsis)
      end
    end

    context "inno" do
      let(:pkg_name) { "Mercurial 3.6.1 (64-bit)" }
      let(:pkg_path) { "https://www.mercurial-scm.org/release/windows/Mercurial-3.6.1-x64.exe" }
      let(:pkg_checksum) { "febd29578cb6736163d232708b834a2ddd119aa40abc536b2c313fc5e1b5831d" }

      it "finds the correct installer type" do
        subject.run_action(:install)
        expect(subject.provider_for_action(:install).installer_type).to eq(:inno)
      end
    end
  end

  describe "install from local file" do
    let(:pkg_name) { "Mercurial 3.6.1 (64-bit)" }
    let(:pkg_path) { ::File.join(Chef::Config[:file_cache_path], "package", "Mercurial-3.6.1-x64.exe") }
    let(:pkg_checksum) { "febd29578cb6736163d232708b834a2ddd119aa40abc536b2c313fc5e1b5831d" }

    it "installs the app" do
      subject.run_action(:install)
      expect(subject).to be_updated_by_last_action
    end
  end

  describe "uninstall exe without source" do
    let(:pkg_name) { "Mercurial 3.6.1 (64-bit)" }

    it "uninstalls the app" do
      subject.run_action(:remove)
      expect(subject).to be_updated_by_last_action
    end
  end

  describe "install package with remote_file_attributes" do
    let(:pkg_name) { "7zip" }
    let(:pkg_path) { "http://www.7-zip.org/a/7z938-x64.msi" }
    let(:remote_file_attributes) {
      {
        path: ::File.join(Chef::Config[:file_cache_path], "7zip.msi"),
        checksum: "7c8e873991c82ad9cfcdbdf45254ea6101e9a645e12977dcd518979e50fdedf3",
      }
    }

    it "installs the package" do
      subject.run_action(:install)
      expect(subject).to be_updated_by_last_action
    end

    it "uninstalls the package" do
      subject.run_action(:remove)
      expect(subject).to be_updated_by_last_action
    end
  end
end
