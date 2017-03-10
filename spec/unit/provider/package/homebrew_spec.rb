#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Copyright 2014-2016, Chef Software, Inc. <legal@chef.io>
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

describe Chef::Provider::Package::Homebrew do
  let(:node) { Chef::Node.new }
  let(:events) { double("Chef::Events").as_null_object }
  let(:run_context) { double("Chef::RunContext", node: node, events: events) }
  let(:new_resource) { Chef::Resource::HomebrewPackage.new("emacs") }
  let(:current_resource) { Chef::Resource::HomebrewPackage.new("emacs") }

  let(:provider) do
    Chef::Provider::Package::Homebrew.new(new_resource, run_context)
  end

  let(:homebrew_uid) { 1001 }

  let(:uninstalled_brew_info) do
    {
      "name" => "emacs",
      "homepage" => "http://www.gnu.org/software/emacs",
      "versions" => {
        "stable" => "24.3",
        "bottle" => false,
        "devel" => nil,
        "head" => nil,
      },
      "revision" => 0,
      "installed" => [],
      "linked_keg" => nil,
      "keg_only" => nil,
      "dependencies" => [],
      "conflicts_with" => [],
      "caveats" => nil,
      "options" => [],
    }
  end

  let(:installed_brew_info) do
    {
      "name" => "emacs",
      "homepage" => "http://www.gnu.org/software/emacs/",
      "versions" => {
        "stable" => "24.3",
        "bottle" => false,
        "devel" => nil,
        "head" => "HEAD",
      },
      "revision" => 0,
      "installed" => [{ "version" => "24.3" }],
      "linked_keg" => "24.3",
      "keg_only" => nil,
      "dependencies" => [],
      "conflicts_with" => [],
      "caveats" => "",
      "options" => [],
    }
  end

  let(:keg_only_brew_info) do
    {
      "name" => "emacs-kegger",
      "homepage" => "http://www.gnu.org/software/emacs/",
      "versions" => {
        "stable" => "24.3-keggy",
        "bottle" => false,
        "devel" => nil,
        "head" => "HEAD",
      },
      "revision" => 0,
      "installed" => [{ "version" => "24.3-keggy" }],
      "linked_keg" => nil,
      "keg_only" => true,
      "dependencies" => [],
      "conflicts_with" => [],
      "caveats" => "",
      "options" => [],
    }
  end

  let(:keg_only_uninstalled_brew_info) do
    {
      "name" => "emacs-kegger",
      "homepage" => "http://www.gnu.org/software/emacs/",
      "versions" => {
        "stable" => "24.3-keggy",
        "bottle" => false,
        "devel" => nil,
        "head" => "HEAD",
      },
      "revision" => 0,
      "installed" => [],
      "linked_keg" => nil,
      "keg_only" => true,
      "dependencies" => [],
      "conflicts_with" => [],
      "caveats" => "",
      "options" => [],
    }
  end

  before(:each) do

  end

  describe "load_current_resource" do
    before(:each) do
      allow(provider).to receive(:current_installed_version).and_return(nil)
      allow(provider).to receive(:candidate_version).and_return("24.3")
    end

    it "creates a current resource with the name of the new resource" do
      provider.load_current_resource
      expect(provider.current_resource).to be_a(Chef::Resource::Package)
      expect(provider.current_resource.name).to eql("emacs")
    end

    it "creates a current resource with the version if the package is installed" do
      expect(provider).to receive(:current_installed_version).and_return("24.3")
      provider.load_current_resource
      expect(provider.current_resource.version).to eql("24.3")
    end

    it "creates a current resource with a nil version if the package is not installed" do
      provider.load_current_resource
      expect(provider.current_resource.version).to be_nil
    end

    it "sets a candidate version if one exists" do
      provider.load_current_resource
      expect(provider.candidate_version).to eql("24.3")
    end
  end

  describe "current_installed_version" do
    it "returns the latest version from brew info if the package is keg only" do
      allow(provider).to receive(:brew_info).and_return(keg_only_brew_info)
      expect(provider.current_installed_version).to eql("24.3-keggy")
    end

    it "returns the linked keg version if the package is not keg only" do
      allow(provider).to receive(:brew_info).and_return(installed_brew_info)
      expect(provider.current_installed_version).to eql("24.3")
    end

    it "returns nil if the package is not installed" do
      allow(provider).to receive(:brew_info).and_return(uninstalled_brew_info)
      expect(provider.current_installed_version).to be_nil
    end

    it "returns nil if the package is keg only and not installed" do
      allow(provider).to receive(:brew_info).and_return(keg_only_uninstalled_brew_info)
      expect(provider.current_installed_version).to be_nil
    end
  end

  describe "brew" do
    before do
      expect(provider).to receive(:find_homebrew_uid).and_return(homebrew_uid)
      expect(Etc).to receive(:getpwuid).with(homebrew_uid).and_return(OpenStruct.new(:name => "name", :dir => "/"))
    end

    it "passes a single to the brew command and return stdout" do
      allow(provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "zombo"))
      expect(provider.brew).to eql("zombo")
    end

    it "takes multiple arguments as an array" do
      allow(provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "homestarrunner"))
      expect(provider.brew("info", "opts", "bananas")).to eql("homestarrunner")
    end

    context "when new_resource is Package" do
      let(:new_resource) { Chef::Resource::Package.new("emacs") }

      it "does not try to read homebrew_user from Package, which does not have it" do
        allow(provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "zombo"))
        expect(provider.brew).to eql("zombo")
      end
    end
  end

  context "when testing actions" do
    before(:each) do
      provider.current_resource = current_resource
    end

    describe "install_package" do
      before(:each) do
        allow(provider).to receive(:candidate_version).and_return("24.3")
      end

      it "installs the named package with brew install" do
        allow(provider.new_resource).to receive(:version).and_return("24.3")
        allow(provider.current_resource).to receive(:version).and_return(nil)
        allow(provider).to receive(:brew_info).and_return(uninstalled_brew_info)
        expect(provider).to receive(:get_response_from_command).with("brew", "install", nil, "emacs")
        provider.install_package("emacs", "24.3")
      end

      it "does not do anything if the package is installed" do
        allow(provider.current_resource).to receive(:version).and_return("24.3")
        allow(provider).to receive(:brew_info).and_return(installed_brew_info)
        expect(provider).not_to receive(:get_response_from_command)
        provider.install_package("emacs", "24.3")
      end

      it "uses options to the brew command if specified" do
        new_resource.options "--cocoa"
        allow(provider.current_resource).to receive(:version).and_return("24.3")
        allow(provider).to receive(:get_response_from_command).with("brew", "install", "--cocoa", "emacs")
        provider.install_package("emacs", "24.3")
      end
    end

    describe "upgrade_package" do
      it "uses brew upgrade to upgrade the package if it is installed" do
        allow(provider.current_resource).to receive(:version).and_return("24")
        allow(provider).to receive(:brew_info).and_return(installed_brew_info)
        expect(provider).to receive(:get_response_from_command).with("brew", "upgrade", nil, "emacs")
        provider.upgrade_package("emacs", "24.3")
      end

      it "does not do anything if the package version is already installed" do
        allow(provider.current_resource).to receive(:version).and_return("24.3")
        allow(provider).to receive(:brew_info).and_return(installed_brew_info)
        expect(provider).not_to receive(:get_response_from_command)
        provider.install_package("emacs", "24.3")
      end

      it "uses brew install to install the package if it is not installed" do
        allow(provider.current_resource).to receive(:version).and_return(nil)
        allow(provider).to receive(:brew_info).and_return(uninstalled_brew_info)
        expect(provider).to receive(:get_response_from_command).with("brew", "install", nil, "emacs")
        provider.upgrade_package("emacs", "24.3")
      end

      it "uses options to the brew command if specified" do
        allow(provider.current_resource).to receive(:version).and_return("24")
        allow(provider).to receive(:brew_info).and_return(installed_brew_info)
        new_resource.options "--cocoa"
        expect(provider).to receive(:get_response_from_command).with("brew", "upgrade", [ "--cocoa" ], "emacs")
        provider.upgrade_package("emacs", "24.3")
      end
    end

    describe "remove_package" do
      it "uninstalls the package with brew uninstall" do
        allow(provider.current_resource).to receive(:version).and_return("24.3")
        allow(provider).to receive(:brew_info).and_return(installed_brew_info)
        expect(provider).to receive(:get_response_from_command).with("brew", "uninstall", nil, "emacs")
        provider.remove_package("emacs", "24.3")
      end

      it "does not do anything if the package is not installed" do
        allow(provider).to receive(:brew_info).and_return(uninstalled_brew_info)
        expect(provider).not_to receive(:get_response_from_command)
        provider.remove_package("emacs", "24.3")
      end
    end

    describe "purge_package" do
      it "uninstalls the package with brew uninstall --force" do
        allow(provider.current_resource).to receive(:version).and_return("24.3")
        allow(provider).to receive(:brew_info).and_return(installed_brew_info)
        expect(provider).to receive(:get_response_from_command).with("brew", "uninstall", "--force", nil, "emacs")
        provider.purge_package("emacs", "24.3")
      end

      it "does not do anything if the package is not installed" do
        allow(provider).to receive(:brew_info).and_return(uninstalled_brew_info)
        expect(provider).not_to receive(:get_response_from_command)
        provider.purge_package("emacs", "24.3")
      end
    end
  end
end
