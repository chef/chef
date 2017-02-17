#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

describe Chef::Provider::Package do
  let(:node) do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = :just_testing
    node.automatic_attrs[:platform_version] = :just_testing
    node
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::Package.new("emacs") }
  let(:current_resource) { Chef::Resource::Package.new("emacs") }
  let(:candidate_version) { "1.0" }
  let(:provider) do
    provider = Chef::Provider::Package.new(new_resource, run_context)
    provider.current_resource = current_resource
    provider.candidate_version = candidate_version
    provider
  end

  describe "when installing a package" do
    before(:each) do
      provider.current_resource = current_resource
      allow(provider).to receive(:install_package).and_return(true)
    end

    it "raises a Chef::Exceptions::InvalidResourceSpecification if both multipackage and source are provided" do
      new_resource.package_name(%w{a b})
      new_resource.source("foo")
      expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
    end

    it "should raise a Chef::Exceptions::Package if no version is specified, and no candidate is available" do
      provider.candidate_version = nil
      expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should call preseed_package if a response_file is given" do
      new_resource.response_file("foo")
      expect(provider).to receive(:get_preseed_file).with(
        new_resource.name,
        provider.candidate_version
      ).and_return("/var/cache/preseed-test")

      expect(provider).to receive(:preseed_package).with(
        "/var/cache/preseed-test"
      ).and_return(true)
      provider.run_action(:install)
    end

    it "should not call preseed_package if a response_file is not given" do
      expect(provider).not_to receive(:preseed_package)
      provider.run_action(:install)
    end

    it "should install the package at the candidate_version if it is not already installed" do
      expect(provider).to receive(:install_package).with(
        new_resource.name,
        provider.candidate_version
      ).and_return(true)
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should install the package at the version specified if it is not already installed" do
      new_resource.version("1.0")
      expect(provider).to receive(:install_package).with(
        new_resource.name,
        new_resource.version
      ).and_return(true)
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should install the package at the version specified if a different version is installed" do
      new_resource.version("1.0")
      allow(current_resource).to receive(:version).and_return("0.99")
      expect(provider).to receive(:install_package).with(
        new_resource.name,
        new_resource.version
      ).and_return(true)
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not install the package if it is already installed and no version is specified" do
      current_resource.version("1.0")
      expect(provider).not_to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should not install the package if it is already installed at the version specified" do
      current_resource.version("1.0")
      new_resource.version("1.0")
      expect(provider).not_to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should call the candidate_version accessor only once if the package is already installed and no version is specified" do
      current_resource.version("1.0")
      allow(provider).to receive(:candidate_version).and_return("1.0")
      provider.run_action(:install)
    end

    it "should call the candidate_version accessor only once if the package is already installed at the version specified" do
      current_resource.version("1.0")
      new_resource.version("1.0")
      provider.run_action(:install)
    end

    it "should set the resource to updated if it installs the package" do
      provider.run_action(:install)
      expect(new_resource).to be_updated
    end

  end

  describe "when upgrading the package" do
    before(:each) do
      allow(provider).to receive(:upgrade_package).and_return(true)
    end

    it "should upgrade the package if the current version is not the candidate version" do
      expect(provider).to receive(:upgrade_package).with(
        new_resource.name,
        provider.candidate_version
      ).and_return(true)
      provider.run_action(:upgrade)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should set the resource to updated if it installs the package" do
      provider.run_action(:upgrade)
      expect(new_resource).to be_updated
    end

    it "should not install the package if the current version is the candidate version" do
      current_resource.version "1.0"
      expect(provider).not_to receive(:upgrade_package)
      provider.run_action(:upgrade)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should print the word 'uninstalled' if there was no original version" do
      allow(current_resource).to receive(:version).and_return(nil)
      expect(Chef::Log).to receive(:info).with("package[emacs] upgraded emacs to 1.0")
      provider.run_action(:upgrade)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should raise a Chef::Exceptions::Package if current version and candidate are nil" do
      allow(current_resource).to receive(:version).and_return(nil)
      provider.candidate_version = nil
      expect { provider.run_action(:upgrade) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should not install the package if candidate version is nil" do
      current_resource.version "1.0"
      provider.candidate_version = nil
      expect(provider).not_to receive(:upgrade_package)
      provider.run_action(:upgrade)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "When removing the package" do
    before(:each) do
      allow(provider).to receive(:remove_package).and_return(true)
      current_resource.version "1.4.2"
    end

    it "should remove the package if it is installed" do
      expect(provider).to be_removing_package
      expect(provider).to receive(:remove_package).with("emacs", nil)
      provider.run_action(:remove)
      expect(new_resource).to be_updated
      expect(new_resource).to be_updated_by_last_action
    end

    it "should remove the package at a specific version if it is installed at that version" do
      new_resource.version "1.4.2"
      expect(provider).to be_removing_package
      expect(provider).to receive(:remove_package).with("emacs", "1.4.2")
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not remove the package at a specific version if it is not installed at that version" do
      new_resource.version "1.0"
      expect(provider).not_to be_removing_package
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should not remove the package if it is not installed" do
      expect(provider).not_to receive(:remove_package)
      allow(current_resource).to receive(:version).and_return(nil)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should set the resource to updated if it removes the package" do
      provider.run_action(:remove)
      expect(new_resource).to be_updated
    end

  end

  describe "When purging the package" do
    before(:each) do
      allow(provider).to receive(:purge_package).and_return(true)
      current_resource.version "1.4.2"
    end

    it "should purge the package if it is installed" do
      expect(provider).to be_removing_package
      expect(provider).to receive(:purge_package).with("emacs", nil)
      provider.run_action(:purge)
      expect(new_resource).to be_updated
      expect(new_resource).to be_updated_by_last_action
    end

    it "should purge the package at a specific version if it is installed at that version" do
      new_resource.version "1.4.2"
      expect(provider).to be_removing_package
      expect(provider).to receive(:purge_package).with("emacs", "1.4.2")
      provider.run_action(:purge)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not purge the package at a specific version if it is not installed at that version" do
      new_resource.version "1.0"
      expect(provider).not_to be_removing_package
      expect(provider).not_to receive(:purge_package)
      provider.run_action(:purge)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should not purge the package if it is not installed" do
      current_resource.instance_variable_set(:@version, nil)
      expect(provider).not_to be_removing_package

      expect(provider).not_to receive(:purge_package)
      provider.run_action(:purge)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should set the resource to updated if it purges the package" do
      provider.run_action(:purge)
      expect(new_resource).to be_updated
    end

  end

  describe "when reconfiguring the package" do
    before(:each) do
      allow(provider).to receive(:reconfig_package).and_return(true)
    end

    it "should info log, reconfigure the package and update the resource" do
      allow(current_resource).to receive(:version).and_return("1.0")
      allow(new_resource).to receive(:response_file).and_return(true)
      expect(provider).to receive(:get_preseed_file).and_return("/var/cache/preseed-test")
      allow(provider).to receive(:preseed_package).and_return(true)
      allow(provider).to receive(:reconfig_package).and_return(true)
      expect(Chef::Log).to receive(:info).with("package[emacs] reconfigured")
      expect(provider).to receive(:reconfig_package)
      provider.run_action(:reconfig)
      expect(new_resource).to be_updated
      expect(new_resource).to be_updated_by_last_action
    end

    it "should debug log and not reconfigure the package if the package is not installed" do
      allow(current_resource).to receive(:version).and_return(nil)
      expect(Chef::Log).to receive(:debug).with("package[emacs] is NOT installed - nothing to do")
      expect(provider).not_to receive(:reconfig_package)
      provider.run_action(:reconfig)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should debug log and not reconfigure the package if no response_file is given" do
      allow(current_resource).to receive(:version).and_return("1.0")
      allow(new_resource).to receive(:response_file).and_return(nil)
      expect(Chef::Log).to receive(:debug).with("package[emacs] no response_file provided - nothing to do")
      expect(provider).not_to receive(:reconfig_package)
      provider.run_action(:reconfig)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should debug log and not reconfigure the package if the response_file has not changed" do
      allow(current_resource).to receive(:version).and_return("1.0")
      allow(new_resource).to receive(:response_file).and_return(true)
      expect(provider).to receive(:get_preseed_file).and_return(false)
      allow(provider).to receive(:preseed_package).and_return(false)
      expect(Chef::Log).to receive(:debug).with("package[emacs] preseeding has not changed - nothing to do")
      expect(provider).not_to receive(:reconfig_package)
      provider.run_action(:reconfig)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "When locking the package" do
    before(:each) do
      allow(provider).to receive(:lock_package).and_return(true)
    end

    it "should lock the package if it is unlocked" do
      allow(provider).to receive(:package_locked).and_return(false)
      expect(provider).to receive(:lock_package)
      provider.run_action(:lock)
    end

    it "should not lock the package if it is already locked" do
      allow(provider).to receive(:package_locked).and_return(true)
      expect(provider).not_to receive(:lock_package)
      provider.run_action(:lock)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should set the resource to updated if it locks the package" do
      allow(provider).to receive(:package_locked).and_return(false)
      provider.run_action(:lock)
      expect(new_resource).to be_updated
    end
  end

  describe "When unlocking the package" do
    before(:each) do
      allow(provider).to receive(:unlock_package).and_return(true)
    end

    it "should unlock the package if it is locked" do
      allow(provider).to receive(:package_locked).and_return(true)
      expect(provider).to receive(:unlock_package)
      provider.run_action(:unlock)
    end

    it "should not unlock the package if it is already unlocked" do
      allow(provider).to receive(:package_locked).and_return(false)
      expect(provider).not_to receive(:unlock_package)
      provider.run_action(:unlock)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should set the resource to updated if it unlocks the package" do
      allow(provider).to receive(:package_locked).and_return(true)
      provider.run_action(:unlock)
      expect(new_resource).to be_updated
    end
  end

  describe "when running commands to be implemented by subclasses" do
    it "should raises UnsupportedAction for install" do
      expect { provider.install_package("emacs", "1.4.2") }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raises UnsupportedAction for upgrade" do
      expect { provider.upgrade_package("emacs", "1.4.2") }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raises UnsupportedAction for remove" do
      expect { provider.remove_package("emacs", "1.4.2") }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raises UnsupportedAction for purge" do
      expect { provider.purge_package("emacs", "1.4.2") }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raise UnsupportedAction for preseed_package" do
      preseed_file = "/tmp/sun-jdk-package-preseed-file.seed"
      expect { provider.preseed_package(preseed_file) }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raise UnsupportedAction for reconfig" do
      expect { provider.reconfig_package("emacs", "1.4.2") }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raise UnsupportedAction for lock" do
      expect { provider.lock_package("emacs", nil) }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raise UnsupportedAction for unlock" do
      expect { provider.unlock_package("emacs", nil) }.to raise_error(Chef::Exceptions::UnsupportedAction)
    end
  end

  describe "when given a response file" do
    let(:cookbook_repo) { File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks")) }
    let(:cookbook_loader) do
      Chef::Cookbook::FileVendor.fetch_from_disk(cookbook_repo)
      Chef::CookbookLoader.new(cookbook_repo)
    end
    let(:cookbook_collection) do
      cookbook_loader.load_cookbooks
      Chef::CookbookCollection.new(cookbook_loader)
    end
    let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }
    let(:new_resource) do
      new_resource = Chef::Resource::Package.new("emacs")
      new_resource.response_file("java.response")
      new_resource.cookbook_name = "java"
      new_resource
    end

    describe "creating the cookbook file resource to fetch the response file" do
      before do
        expect(Chef::FileCache).to receive(:create_cache_path).with("preseed/java").and_return("/tmp/preseed/java")
      end

      it "sets the preseed resource's runcontext to its own run context" do
        allow(Chef::FileCache).to receive(:create_cache_path).and_return("/tmp/preseed/java")
        expect(provider.preseed_resource("java", "6").run_context).not_to be_nil
        expect(provider.preseed_resource("java", "6").run_context).to equal(provider.run_context)
      end

      it "should set the cookbook name of the remote file to the new resources cookbook name" do
        expect(provider.preseed_resource("java", "6").cookbook_name).to eq("java")
      end

      it "should set remote files source to the new resources response file" do
        expect(provider.preseed_resource("java", "6").source).to eq("java.response")
      end

      it "should never back up the cached response file" do
        expect(provider.preseed_resource("java", "6").backup).to be_falsey
      end

      it "sets the install path of the resource to $file_cache/$cookbook/$pkg_name-$pkg_version.seed" do
        expect(provider.preseed_resource("java", "6").path).to eq("/tmp/preseed/java/java-6.seed")
      end
    end

    describe "when installing the preseed file to the cache location" do
      let(:response_file_destination) { Dir.tmpdir + "/preseed--java--java-6.seed" }
      let(:response_file_resource) do
        response_file_resource = Chef::Resource::CookbookFile.new(response_file_destination, run_context)
        response_file_resource.cookbook_name = "java"
        response_file_resource.backup(false)
        response_file_resource.source("java.response")
        response_file_resource
      end

      before do
        expect(provider).to receive(:preseed_resource).with("java", "6").and_return(response_file_resource)
      end

      after do
        FileUtils.rm(response_file_destination) if ::File.exist?(response_file_destination)
      end

      it "creates the preseed file in the cache" do
        expect(response_file_resource).to receive(:run_action).with(:create)
        provider.get_preseed_file("java", "6")
      end

      it "returns the path to the response file if the response file was updated" do
        expect(provider.get_preseed_file("java", "6")).to eq(response_file_destination)
      end

      it "should return false if the response file has not been updated" do
        response_file_resource.updated_by_last_action(false)
        expect(response_file_resource).not_to be_updated_by_last_action
        # don't let the response_file_resource set updated to true
        expect(response_file_resource).to receive(:run_action).with(:create)
        expect(provider.get_preseed_file("java", "6")).to be(false)
      end

    end

  end
end

describe "Subclass with use_multipackage_api" do
  class MyPackageResource < Chef::Resource::Package
  end

  class MyPackageProvider < Chef::Provider::Package
    use_multipackage_api
  end

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { MyPackageResource.new("installs the packages") }
  let(:current_resource) { MyPackageResource.new("installs the packages") }
  let(:provider) do
    provider = MyPackageProvider.new(new_resource, run_context)
    provider.current_resource = current_resource
    provider
  end

  it "has use_multipackage_api? methods on the class and instance" do
    expect(MyPackageProvider.use_multipackage_api?).to be true
    expect(provider.use_multipackage_api?).to be true
  end

  context "#a_to_s utility for subclasses" do
    before(:each) do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
    end

    it "converts varargs of strings to a single string" do
      expect(provider.send(:a_to_s, "a", nil, "b", "", "c", " ", "d e", "f-g")).to eq("a b c   d e f-g")
    end

    it "converts an array of strings to a single string" do
      expect(provider.send(:a_to_s, ["a", nil, "b", "", "c", " ", "d e", "f-g"])).to eq("a b c   d e f-g")
    end

    it "converts a mishmash of array args to a single string" do
      expect(provider.send(:a_to_s, "a", [ nil, "b", "", [ "c" ] ], " ", [ "d e", "f-g" ])).to eq("a b c   d e f-g")
    end
  end

  it "when user passes string to package_name, passes arrays to install_package" do
    new_resource.package_name "vim"
    new_resource.version nil
    provider.candidate_version = [ "1.0" ]
    expect(provider).to receive(:install_package).with(
      [ "vim" ],
      [ "1.0" ]
    ).and_return(true)
    provider.run_action(:install)
    expect(new_resource).to be_updated_by_last_action
    expect(new_resource.version).to eql(nil)
  end

  it "when user pases string to package_name and version, passes arrays to install_package" do
    new_resource.package_name "vim"
    new_resource.version "1.0"
    provider.candidate_version = [ "1.0" ]
    expect(provider).to receive(:install_package).with(
      [ "vim" ],
      [ "1.0" ]
    ).and_return(true)
    provider.run_action(:install)
    expect(new_resource).to be_updated_by_last_action
    expect(new_resource.version).to eql("1.0")
  end

  it "when user passes string to package_name, passes arrays to upgrade_package" do
    new_resource.package_name "vim"
    new_resource.version nil
    provider.candidate_version = [ "1.0" ]
    expect(provider).to receive(:upgrade_package).with(
      [ "vim" ],
      [ "1.0" ]
    ).and_return(true)
    provider.run_action(:upgrade)
    expect(new_resource).to be_updated_by_last_action
    expect(new_resource.version).to eql(nil)
  end

  it "when user pases string to package_name and version, passes arrays to upgrade_package" do
    new_resource.package_name "vim"
    new_resource.version "1.0"
    provider.candidate_version = [ "1.0" ]
    expect(provider).to receive(:upgrade_package).with(
      [ "vim" ],
      [ "1.0" ]
    ).and_return(true)
    provider.run_action(:upgrade)
    expect(new_resource).to be_updated_by_last_action
    expect(new_resource.version).to eql("1.0")
  end

  it "when user passes string to package_name, passes arrays to remove_package" do
    new_resource.package_name "vim"
    current_resource.package_name "vim"
    current_resource.version [ "1.0" ]
    provider.candidate_version = [ "1.0" ]
    expect(provider).to receive(:remove_package).with(
      [ "vim" ],
      [ nil ]
    ).and_return(true)
    provider.run_action(:remove)
    expect(new_resource).to be_updated_by_last_action
    expect(new_resource.version).to eql(nil)
  end

  it "when user passes string to package_name, passes arrays to purge_package" do
    new_resource.package_name "vim"
    current_resource.package_name "vim"
    current_resource.version [ "1.0" ]
    provider.candidate_version = [ "1.0" ]
    expect(provider).to receive(:purge_package).with(
      [ "vim" ],
      [ nil ]
    ).and_return(true)
    provider.run_action(:purge)
    expect(new_resource).to be_updated_by_last_action
    expect(new_resource.version).to eql(nil)
  end

  it "when user passes string to package_name, passes arrays to reconfig_package" do
    new_resource.package_name "vim"
    current_resource.package_name "vim"
    current_resource.version [ "1.0" ]
    allow(new_resource).to receive(:response_file).and_return(true)
    expect(provider).to receive(:get_preseed_file).and_return("/var/cache/preseed-test")
    allow(provider).to receive(:preseed_package).and_return(true)
    allow(provider).to receive(:reconfig_package).and_return(true)
    expect(provider).to receive(:reconfig_package).with(
      [ "vim" ],
      [ "1.0" ]
    ).and_return(true)
    provider.run_action(:reconfig)
    expect(new_resource).to be_updated_by_last_action
  end
end

describe "Chef::Provider::Package - Multi" do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::Package.new(%w{emacs vi}) }
  let(:current_resource) { Chef::Resource::Package.new(%w{emacs vi}) }
  let(:candidate_version) { [ "1.0", "6.2" ] }
  class MyPackageProvider < Chef::Provider::Package
    use_multipackage_api
  end
  let(:provider) do
    provider = MyPackageProvider.new(new_resource, run_context)
    provider.current_resource = current_resource
    provider.candidate_version = candidate_version
    provider
  end

  describe "when installing multiple packages" do
    before(:each) do
      provider.current_resource = current_resource
      allow(provider).to receive(:install_package).and_return(true)
    end

    it "installs the candidate versions when none are installed" do
      expect(provider).to receive(:install_package).with(
        %w{emacs vi},
        ["1.0", "6.2"]
      ).and_return(true)
      provider.run_action(:install)
      expect(new_resource).to be_updated
    end

    it "installs the candidate versions when some are installed" do
      expect(provider).to receive(:install_package).with(
        [ "vi" ],
        [ "6.2" ]
      ).and_return(true)
      current_resource.version(["1.0", nil])
      provider.run_action(:install)
      expect(new_resource).to be_updated
    end

    it "installs the specified version when some are out of date" do
      current_resource.version(["1.0", "6.2"])
      new_resource.version(["1.0", "6.1"])
      provider.run_action(:install)
      expect(new_resource).to be_updated
    end

    it "does not install any version if all are installed at the right version" do
      current_resource.version(["1.0", "6.2"])
      new_resource.version(["1.0", "6.2"])
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "does not install any version if all are installed, and no version was specified" do
      current_resource.version(["1.0", "6.2"])
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "raises an exception if both are not installed and no caondidates are available" do
      current_resource.version([nil, nil])
      provider.candidate_version = [nil, nil]
      expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "raises an exception if one is not installed and no candidates are available" do
      current_resource.version(["1.0", nil])
      provider.candidate_version = ["1.0", nil]
      expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "does not raise an exception if the packages are installed or have a candidate" do
      current_resource.version(["1.0", nil])
      provider.candidate_version = [nil, "6.2"]
      expect { provider.run_action(:install) }.not_to raise_error
    end

    it "raises an exception if an explicit version is asked for, an old version is installed, but no candidate" do
      new_resource.version ["1.0", "6.2"]
      current_resource.version(["1.0", "6.1"])
      provider.candidate_version = ["1.0", nil]
      expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "does not raise an exception if an explicit version is asked for, and is installed, but no candidate" do
      new_resource.version ["1.0", "6.2"]
      current_resource.version(["1.0", "6.2"])
      provider.candidate_version = ["1.0", nil]
      expect { provider.run_action(:install) }.not_to raise_error
    end

    it "raise an exception if an explicit version is asked for, and is not installed, and no candidate" do
      new_resource.version ["1.0", "6.2"]
      current_resource.version(["1.0", nil])
      provider.candidate_version = ["1.0", nil]
      expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "does not raise an exception if an explicit version is asked for, and is not installed, and there is a candidate" do
      new_resource.version ["1.0", "6.2"]
      current_resource.version(["1.0", nil])
      provider.candidate_version = ["1.0", "6.2"]
      expect { provider.run_action(:install) }.not_to raise_error
    end
  end

  describe "when upgrading multiple packages" do
    before(:each) do
      provider.current_resource = current_resource
      allow(provider).to receive(:upgrade_package).and_return(true)
    end

    it "should upgrade the package if the current versions are not the candidate version" do
      current_resource.version ["0.9", "6.1"]
      expect(provider).to receive(:upgrade_package).with(
        new_resource.package_name,
        provider.candidate_version
      ).and_return(true)
      provider.run_action(:upgrade)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should upgrade the package if some of current versions are not the candidate versions" do
      current_resource.version ["1.0", "6.1"]
      expect(provider).to receive(:upgrade_package).with(
        ["vi"],
        ["6.2"]
      ).and_return(true)
      provider.run_action(:upgrade)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not install the package if the current versions are the candidate version" do
      current_resource.version ["1.0", "6.2"]
      expect(provider).not_to receive(:upgrade_package)
      provider.run_action(:upgrade)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should raise an exception if both are not installed and no caondidates are available" do
      current_resource.version([nil, nil])
      provider.candidate_version = [nil, nil]
      expect { provider.run_action(:upgrade) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if one is not installed and no candidates are available" do
      current_resource.version(["1.0", nil])
      provider.candidate_version = ["1.0", nil]
      expect { provider.run_action(:upgrade) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should not raise an exception if the packages are installed or have a candidate" do
      current_resource.version(["1.0", nil])
      provider.candidate_version = [nil, "6.2"]
      expect { provider.run_action(:upgrade) }.not_to raise_error
    end

    it "should not raise an exception if the packages are installed or have a candidate" do
      current_resource.version(["1.0", nil])
      provider.candidate_version = [nil, "6.2"]
      expect { provider.run_action(:upgrade) }.not_to raise_error
    end
  end

  describe "When removing multiple packages " do
    before(:each) do
      allow(provider).to receive(:remove_package).and_return(true)
      current_resource.version ["1.0", "6.2"]
    end

    it "should remove the packages if all are installed" do
      expect(provider).to be_removing_package
      expect(provider).to receive(:remove_package).with(%w{emacs vi}, [nil])
      provider.run_action(:remove)
      expect(new_resource).to be_updated
      expect(new_resource).to be_updated_by_last_action
    end

    it "should remove the packages if some are installed" do
      current_resource.version ["1.0", nil]
      expect(provider).to be_removing_package
      expect(provider).to receive(:remove_package).with(%w{emacs vi}, [nil])
      provider.run_action(:remove)
      expect(new_resource).to be_updated
      expect(new_resource).to be_updated_by_last_action
    end

    it "should remove the packages at a specific version if they are installed at that version" do
      new_resource.version ["1.0", "6.2"]
      expect(provider).to be_removing_package
      expect(provider).to receive(:remove_package).with(%w{emacs vi}, ["1.0", "6.2"])
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should remove the packages at a specific version any are is installed at that version" do
      new_resource.version ["0.5", "6.2"]
      expect(provider).to be_removing_package
      expect(provider).to receive(:remove_package).with(%w{emacs vi}, ["0.5", "6.2"])
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not remove the packages at a specific version if they are not installed at that version" do
      new_resource.version ["0.5", "6.0"]
      expect(provider).not_to be_removing_package
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should not remove the packages if they are not installed" do
      expect(provider).not_to receive(:remove_package)
      allow(current_resource).to receive(:version).and_return(nil)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

  end

  describe "When purging multiple packages " do
    before(:each) do
      allow(provider).to receive(:purge_package).and_return(true)
      current_resource.version ["1.0", "6.2"]
    end

    it "should purge the packages if all are installed" do
      expect(provider).to be_removing_package
      expect(provider).to receive(:purge_package).with(%w{emacs vi}, [nil])
      provider.run_action(:purge)
      expect(new_resource).to be_updated
      expect(new_resource).to be_updated_by_last_action
    end

    it "should purge the packages if some are installed" do
      current_resource.version ["1.0", nil]
      expect(provider).to be_removing_package
      expect(provider).to receive(:purge_package).with(%w{emacs vi}, [nil])
      provider.run_action(:purge)
      expect(new_resource).to be_updated
      expect(new_resource).to be_updated_by_last_action
    end

    it "should purge the packages at a specific version if they are installed at that version" do
      new_resource.version ["1.0", "6.2"]
      expect(provider).to be_removing_package
      expect(provider).to receive(:purge_package).with(%w{emacs vi}, ["1.0", "6.2"])
      provider.run_action(:purge)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should purge the packages at a specific version any are is installed at that version" do
      new_resource.version ["0.5", "6.2"]
      expect(provider).to be_removing_package
      expect(provider).to receive(:purge_package).with(%w{emacs vi}, ["0.5", "6.2"])
      provider.run_action(:purge)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not purge the packages at a specific version if they are not installed at that version" do
      new_resource.version ["0.5", "6.0"]
      expect(provider).not_to be_removing_package
      expect(provider).not_to receive(:purge_package)
      provider.run_action(:purge)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should not purge the packages if they are not installed" do
      expect(provider).not_to receive(:purge_package)
      allow(current_resource).to receive(:version).and_return(nil)
      provider.run_action(:purge)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "shell_out helpers" do
    before(:each) do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
    end

    [ :shell_out_with_timeout, :shell_out_with_timeout! ].each do |method|
      stubbed_method = method == :shell_out_with_timeout! ? :shell_out! : :shell_out
      [ %w{command arg1 arg2}, "command arg1 arg2" ].each do |command|
        it "#{method} defaults to 900 seconds" do
          expect(provider).to receive(stubbed_method).with(*command, timeout: 900)
          provider.send(method, *command)
        end
        it "#{method} overrides the default timeout with its options" do
          expect(provider).to receive(stubbed_method).with(*command, timeout: 1)
          provider.send(method, *command, timeout: 1)
        end
        it "#{method} overrides both timeouts with the new_resource.timeout" do
          new_resource.timeout(99)
          expect(provider).to receive(stubbed_method).with(*command, timeout: 99)
          provider.send(method, *command, timeout: 1)
        end
        it "#{method} defaults to 900 seconds and preserves options" do
          expect(provider).to receive(stubbed_method).with(*command, env: nil, timeout: 900)
          provider.send(method, *command, env: nil)
        end
        it "#{method} overrides the default timeout with its options and preserves options" do
          expect(provider).to receive(stubbed_method).with(*command, timeout: 1, env: nil)
          provider.send(method, *command, timeout: 1, env: nil)
        end
        it "#{method} overrides both timeouts with the new_resource.timeout and preseves options" do
          new_resource.timeout(99)
          expect(provider).to receive(stubbed_method).with(*command, timeout: 99, env: nil)
          provider.send(method, *command, timeout: 1, env: nil)
        end
      end
    end
  end
end
