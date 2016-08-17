#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "chef/mixin/shell_out"

describe Chef::Resource::DpkgPackage, :requires_root, :debian_family_only, arch: "x86_64" do
  include Chef::Mixin::ShellOut

  let(:apt_data) { File.join(CHEF_SPEC_DATA, "apt") }

  let(:test1_0) { File.join(apt_data, "chef-integration-test_1.0-1_amd64.deb") }
  let(:test1_1) { File.join(apt_data, "chef-integration-test_1.1-1_amd64.deb") }
  let(:test2_0) { File.join(apt_data, "chef-integration-test2_1.0-1_amd64.deb") }

  let(:run_context) do
    node = TEST_NODE.dup
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end

  let(:dpkg_package) { Chef::Resource::DpkgPackage.new(test1_0, run_context) }

  before(:each) do
    shell_out("dpkg -P chef-integration-test chef-integration-test2")
  end

  # handles setting the name property after the initializer runs
  def set_dpkg_package_name(name)
    dpkg_package.name name
    dpkg_package.package_name name
  end

  def should_be_purged_or_removed(package, action = nil)
    status = shell_out("dpkg -s #{package}")
    output = status.stdout + status.stderr
    if action.nil? || action == :purge
      expect(output).to match(/no info|not-installed|not installed/)
    elsif action == :remove
      expect(output).to match(/deinstall ok config-files/)
    else
      raise "Unknown action"
    end
  end

  shared_examples_for "common behavior for upgrade or install" do
    it "installs a package when given only the filename as a name argument (no source)" do
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
    end

    it "installs a package when given the name and a source argument" do
      set_dpkg_package_name "chef-integration-test"
      dpkg_package.source test1_0
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
    end

    it "installs a package when given a different name and a source argument" do
      set_dpkg_package_name "some other name"
      dpkg_package.source test1_0
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
    end

    it "installs a package when given a path as a package_name and no source" do
      set_dpkg_package_name "chef-integration-test"
      dpkg_package.package_name test1_0
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
    end

    it "raises an error when the name is not a path and the source is not given" do
      set_dpkg_package_name "chef-integration-test"
      dpkg_package.package_name "chef-integration-test"
      expect { dpkg_package.run_action(action) }.to raise_error(Chef::Exceptions::Package)
    end

    it "raises an error when passed a package_name that does not exist" do
      set_dpkg_package_name File.join(test1_0, "make.it.fail")
      expect { dpkg_package.run_action(action) }.to raise_error(Chef::Exceptions::Package)
    end

    it "raises an error when passed a source that does not exist" do
      set_dpkg_package_name "chef-integration-test"
      dpkg_package.source File.join(test1_0, "make.it.fail")
      expect { dpkg_package.run_action(action) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should not install an already installed package" do
      shell_out!("dpkg -i #{test1_0}")
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
    end

    it "should handle a multipackage install" do
      set_dpkg_package_name [ test1_0, test2_0 ]
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
      shell_out!("dpkg -s chef-integration-test2")
    end

    it "should not update multipackages that are up-to-date" do
      shell_out!("dpkg -i #{test1_0} #{test2_0}")
      set_dpkg_package_name [ test1_0, test2_0 ]
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
      shell_out!("dpkg -s chef-integration-test2")
    end

    it "should install the second if the first is installed" do
      shell_out!("dpkg -i #{test1_0}")
      set_dpkg_package_name [ test1_0, test2_0 ]
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
      shell_out!("dpkg -s chef-integration-test2")
    end

    it "should install the first if the second is installed" do
      shell_out!("dpkg -i #{test2_0}")
      set_dpkg_package_name [ test1_0, test2_0 ]
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test")
      shell_out!("dpkg -s chef-integration-test2")
    end
  end

  context "action :install" do
    let(:action) { :install }
    it_behaves_like "common behavior for upgrade or install"

    it "should not upgrade a package" do
      shell_out!("dpkg -i #{test1_0}")
      set_dpkg_package_name test1_1
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
    end

    it "should not upgrade on a multipackage install" do
      shell_out!("dpkg -i #{test1_0} #{test2_0}")
      set_dpkg_package_name [ test1_1, test2_0 ]
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
    end
  end

  context "action :upgrade" do
    let(:action) { :upgrade }
    it_behaves_like "common behavior for upgrade or install"

    it "should upgrade a package" do
      shell_out!("dpkg -i #{test1_0}")
      set_dpkg_package_name test1_1
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
    end

    it "should upgrade on a multipackage install" do
      shell_out!("dpkg -i #{test1_0} #{test2_0}")
      set_dpkg_package_name [ test1_1, test2_0 ]
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
    end
  end

  shared_examples_for "common behavior for remove or purge" do
    it "should remove a package that is installed when the name is a source" do
      shell_out!("dpkg -i #{test1_0}")
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should do nothing if the package is not installed when the name is a source" do
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should remove a package that is installed when the name is the package name and source is nil" do
      shell_out!("dpkg -i #{test1_0}")
      set_dpkg_package_name "chef-integration-test"
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should do nothing if the package is not installed when the name is the package name and the source is nil" do
      set_dpkg_package_name "chef-integration-test"
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should remove a package that is installed when the name is changed but the source is a package" do
      shell_out!("dpkg -i #{test1_0}")
      set_dpkg_package_name "some other name"
      dpkg_package.source test1_0
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should do nothing if the package is not installed when the name is changed but the source is a package" do
      set_dpkg_package_name "some other name"
      dpkg_package.source test1_0
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should remove a package if the name is a file that does not exist, but the source exists" do
      shell_out!("dpkg -i #{test1_0}")
      dpkg_package.name "whatever"
      dpkg_package.package_name File.join(test1_0, "make.it.fail")
      dpkg_package.source test1_0
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should do nothing if the package is not installed when the name is a file that does not exist, but the source exists" do
      set_dpkg_package_name "some other name"
      dpkg_package.name "whatever"
      dpkg_package.package_name File.join(test1_0, "make.it.fail")
      dpkg_package.source test1_0
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should remove a package if the package_name is correct, but the source does not exist" do
      shell_out!("dpkg -i #{test1_0}")
      dpkg_package.name "whatever"
      dpkg_package.package_name "chef-integration-test"
      dpkg_package.source File.join(test1_0, "make.it.fail")
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should do nothing if the package_name is correct, but the source does not exist, and the package is not installed" do
      dpkg_package.name "whatever"
      dpkg_package.package_name "chef-integration-test"
      dpkg_package.source File.join(test1_0, "make.it.fail")
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
    end

    it "should remove both packages when called with two" do
      shell_out!("dpkg -i #{test1_0} #{test2_0}")
      set_dpkg_package_name [ "chef-integration-test", "chef-integration-test2" ]
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
      should_be_purged_or_removed("chef-integration-test2", action)
    end

    it "should remove a package when only the first one is installed" do
      shell_out!("dpkg -i #{test1_0}")
      set_dpkg_package_name [ "chef-integration-test", "chef-integration-test2" ]
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
      should_be_purged_or_removed("chef-integration-test2")
    end

    it "should remove a package when only the second one is installed" do
      shell_out!("dpkg -i #{test2_0}")
      set_dpkg_package_name [ "chef-integration-test", "chef-integration-test2" ]
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
      should_be_purged_or_removed("chef-integration-test2", action)
    end

    it "should do nothing when both packages are not installed" do
      set_dpkg_package_name [ "chef-integration-test", "chef-integration-test2" ]
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test")
      should_be_purged_or_removed("chef-integration-test2")
    end
  end

  context "action :remove" do
    let(:action) { :remove }
    it_behaves_like "common behavior for remove or purge"

    it "should not remove a removed package when the name is a source" do
      # the "test2" file has a conffile declared in it
      shell_out!("dpkg -i #{test2_0}")
      shell_out!("dpkg -r chef-integration-test2")
      set_dpkg_package_name "chef-integration-test2"
      dpkg_package.run_action(action)
      expect(dpkg_package).not_to be_updated_by_last_action
      shell_out!("dpkg -s chef-integration-test2") # its still 'installed'
    end
  end

  context "action :purge" do
    let(:action) { :purge }
    it_behaves_like "common behavior for remove or purge"

    it "should purge a removed package when the name is a source" do
      # the "test2" file has a conffile declared in it
      shell_out!("dpkg -i #{test2_0}")
      shell_out!("dpkg -r chef-integration-test2")
      set_dpkg_package_name "chef-integration-test2"
      dpkg_package.run_action(action)
      expect(dpkg_package).to be_updated_by_last_action
      should_be_purged_or_removed("chef-integration-test2", action)
    end
  end
end
