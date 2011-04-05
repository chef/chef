#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Package do
  before do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Package.new('emacs')
    @current_resource = Chef::Resource::Package.new('emacs')
    @provider = Chef::Provider::Package.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource

    @provider.candidate_version = "1.0"
  end

  describe "when installing a package" do
    before(:each) do
      @provider.current_resource = @current_resource
      @provider.stub!(:install_package).and_return(true)
    end

    it "should raise a Chef::Exceptions::Package if no version is specified, and no candidate is available" do
      @provider.candidate_version = nil
      lambda { @provider.action_install }.should raise_error(Chef::Exceptions::Package)
    end

    it "should call preseed_package if a response_file is given" do
      @new_resource.stub!(:response_file).and_return("foo")
      @provider.should_receive(:preseed_package).with(
        @new_resource.name,
        @provider.candidate_version
      ).and_return(true)
      @provider.action_install
    end

    it "should not call preseed_package if a response_file is not given" do
      @provider.should_not_receive(:preseed_package)
      @provider.action_install
    end

    it "should install the package at the candidate_version if it is not already installed" do
      @provider.should_receive(:install_package).with(
        @new_resource.name,
        @provider.candidate_version
      ).and_return(true)
      @provider.action_install
    end

    it "should install the package at the version specified if it is not already installed" do
      @new_resource.stub!(:version).and_return("1.0")
      @provider.should_receive(:install_package).with(
        @new_resource.name,
        @new_resource.version
      ).and_return(true)
      @provider.action_install
    end

    it "should install the package at the version specified if a different version is installed" do
      @new_resource.stub!(:version).and_return("1.0")
      @current_resource.stub!(:version).and_return("0.99")
      @provider.should_receive(:install_package).with(
        @new_resource.name,
        @new_resource.version
      ).and_return(true)
      @provider.action_install
    end

    it "should not install the package if it is already installed and no version is specified" do
      @current_resource.stub!(:version).and_return("1.0")
      @provider.should_not_receive(:install_package)
      @provider.action_install
    end

    it "should not install the package if it is already installed at the version specified" do
      @current_resource.stub!(:version).and_return("1.0")
      @new_resource.stub!(:version).and_return("1.0")
      @provider.should_not_receive(:install_package)
      @provider.action_install
    end

    it "should call the candidate_version accessor if the package is not currently installed" do
      @provider.should_receive(:candidate_version).and_return(true)
      @provider.action_install
    end

    it "should not call the candidate_version accessor if the package is already installed and no version is specified" do
      @current_resource.stub!(:version).and_return("1.0")
      @provider.should_not_receive(:candidate_version)
      @provider.action_install
    end

    it "should not call the candidate_version accessor if the package is already installed at the version specified" do
      @current_resource.stub!(:version).and_return("1.0")
      @new_resource.stub!(:version).and_return("1.0")
      @provider.should_not_receive(:candidate_version)
      @provider.action_install
    end

    it "should not call the candidate_version accessor if the package is not installed new package's version is specified" do
      @new_resource.stub!(:version).and_return("1.0")
      @provider.should_not_receive(:candidate_version)
      @provider.action_install
    end

    it "should not call the candidate_version accessor if the package at the version specified is a different version than installed" do
      @new_resource.stub!(:version).and_return("1.0")
      @current_resource.stub!(:version).and_return("0.99")
      @provider.should_not_receive(:candidate_version)
      @provider.action_install
    end

    it "should set the resource to updated if it installs the package" do
      @provider.action_install
      @new_resource.should be_updated
    end

  end

  describe "when upgrading the package" do
    before(:each) do
      @provider.stub!(:upgrade_package).and_return(true)
    end

    it "should upgrade the package if the current version is not the candidate version" do
      @provider.should_receive(:upgrade_package).with(
        @new_resource.name,
        @provider.candidate_version
      ).and_return(true)
      @provider.action_upgrade
    end

    it "should set the resource to updated if it installs the package" do
      @provider.action_upgrade
      @new_resource.should be_updated
    end

    it "should not install the package if the current version is the candidate version" do
      @current_resource.version "1.0"
      @provider.should_not_receive(:upgrade_package)
      @provider.action_upgrade
    end

    it "should print the word 'uninstalled' if there was no original version" do
      @current_resource.stub!(:version).and_return(nil)
      Chef::Log.should_receive(:info).with("package[emacs] upgraded from uninstalled to 1.0")
      @provider.action_upgrade
    end
  end

  describe "When removing the package" do
    before(:each) do
      @provider.stub!(:remove_package).and_return(true)
      @current_resource.version '1.4.2'
    end

    it "should remove the package if it is installed" do
      @provider.should be_removing_package
      @provider.should_receive(:remove_package).with('emacs', nil)
      @provider.action_remove
      @new_resource.should be_updated
    end

    it "should remove the package at a specific version if it is installed at that version" do
      @new_resource.version "1.4.2"
      @provider.should be_removing_package
      @provider.should_receive(:remove_package).with('emacs', '1.4.2')
      @provider.action_remove
    end

    it "should not remove the package at a specific version if it is not installed at that version" do
      @new_resource.version "1.0"
      @provider.should_not be_removing_package
      @provider.should_not_receive(:remove_package)
      @provider.action_remove
    end

    it "should not remove the package if it is not installed" do
      @provider.should_not_receive(:remove_package)
      @current_resource.stub!(:version).and_return(nil)
      @provider.action_remove
    end

    it "should set the resource to updated if it removes the package" do
      @provider.action_remove
      @new_resource.should be_updated
    end

  end

  describe "When purging the package" do
    before(:each) do
      @provider.stub!(:purge_package).and_return(true)
      @current_resource.version '1.4.2'
    end

    it "should purge the package if it is installed" do
      @provider.should be_removing_package
      @provider.should_receive(:purge_package).with('emacs', nil)
      @provider.action_purge
      @new_resource.should be_updated
    end

    it "should purge the package at a specific version if it is installed at that version" do
      @new_resource.version "1.4.2"
      @provider.should be_removing_package
      @provider.should_receive(:purge_package).with('emacs', '1.4.2')
      @provider.action_purge
    end

    it "should not purge the package at a specific version if it is not installed at that version" do
      @new_resource.version "1.0"
      @provider.should_not be_removing_package
      @provider.should_not_receive(:purge_package)
      @provider.action_purge
    end

    it "should not purge the package if it is not installed" do
      @current_resource.instance_variable_set(:@version, nil)
      @provider.should_not be_removing_package

      @provider.should_not_receive(:purge_package)
      @provider.action_purge
    end

    it "should set the resource to updated if it purges the package" do
      @provider.action_purge
      @new_resource.should be_updated
    end

  end

  describe "when running commands to be implemented by subclasses" do
    it "should raises UnsupportedAction for install" do
      lambda { @provider.install_package('emacs', '1.4.2') }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raises UnsupportedAction for upgrade" do
      lambda { @provider.upgrade_package('emacs', '1.4.2') }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raises UnsupportedAction for remove" do
      lambda { @provider.remove_package('emacs', '1.4.2') }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raises UnsupportedAction for purge" do
      lambda { @provider.purge_package('emacs', '1.4.2') }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should raise UnsupportedAction for preseed_package" do
      # 42 is the version of java that will support lambdas
      lambda { @provider.preseed_package('sun-jdk', '42') }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end
  end

  describe "when given a response file" do
    before(:each) do
      @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
      Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, @cookbook_repo) }

      @node = Chef::Node.new
      @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new(@cookbook_repo))
      @run_context = Chef::RunContext.new(@node, @cookbook_collection)

      @node[:platform] = 'PLATFORM: just testing'
      @node[:platform_version] = 'PLATFORM VERSION: just testing'

      @new_resource.response_file('java.response')
      @new_resource.cookbook_name = 'java'
    end

    describe "creating the cookbook file resource to fetch the response file" do
      before do
        Chef::FileCache.should_receive(:create_cache_path).with('preseed/java').and_return("/tmp/preseed/java")
      end
      it "sets the preseed resource's runcontext to its own run context" do
        Chef::FileCache.rspec_reset
        Chef::FileCache.stub!(:create_cache_path).and_return("/tmp/preseed/java")
        @provider.preseed_resource('java', '6').run_context.should_not be_nil
        @provider.preseed_resource('java', '6').run_context.should equal(@provider.run_context)
      end

      it "should set the cookbook name of the remote file to the new resources cookbook name" do
        @provider.preseed_resource('java', '6').cookbook_name.should == 'java'
      end

      it "should set remote files source to the new resources response file" do
        @provider.preseed_resource('java', '6').source.should == 'java.response'
      end

      it "should never back up the cached response file" do
        @provider.preseed_resource('java', '6').backup.should be_false
      end

      it "sets the install path of the resource to $file_cache/$cookbook/$pkg_name-$pkg_version.seed" do
        @provider.preseed_resource('java', '6').path.should == '/tmp/preseed/java/java-6.seed'
      end
    end

    describe "when installing the preseed file to the cache location" do
      before do
        @node[:platform] = :just_testing
        @node[:platform_version] = :just_testing

        @response_file_destination = Dir.tmpdir + '/preseed--java--java-6.seed'

        @response_file_resource = Chef::Resource::CookbookFile.new(@response_file_destination, @run_context)
        @response_file_resource.cookbook_name = 'java'
        @response_file_resource.backup(false)
        @response_file_resource.source('java.response')


        @provider.should_receive(:preseed_resource).with('java', '6').and_return(@response_file_resource)
      end

      after do
        FileUtils.rm(@response_file_destination) if ::File.exist?(@response_file_destination)
      end

      it "creates the preseed file in the cache" do
        @response_file_resource.should_receive(:run_action).with('create')
        @provider.get_preseed_file("java", "6")
      end

      it "returns the path to the response file if the response file was updated" do
        @provider.get_preseed_file("java", "6").should == @response_file_destination
      end

      it "should return false if the response file has not been updated" do
        @response_file_resource.updated_by_last_action(false)
        @response_file_resource.should_not be_updated_by_last_action
        # don't let the response_file_resource set updated to true
        @response_file_resource.should_receive(:run_action).with("create")
        @provider.get_preseed_file("java", "6").should be(false)
      end

    end

  end
end
