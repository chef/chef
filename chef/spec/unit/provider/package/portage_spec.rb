#
# Author:: Caleb Tennis (<caleb.tennis@gmail.com>)
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
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Package::Portage, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Package.new("dev-util/git")
    @current_resource = Chef::Resource::Package.new("dev-util/git")
    
    @provider = Chef::Provider::Package::Portage.new(@new_resource, @run_context)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    
    ::File.stub!(:exists?).and_return(true)
  end
  
  describe "when determining the current state of the package" do
  
    it "should create a current resource with the name of new_resource" do
      ::Dir.stub!(:entries).and_return(["git-1.0.0"])
      Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end
  
    it "should set the current resource package name to the new resource package name" do
      ::Dir.stub!(:entries).and_return(["git-1.0.0"])
      @current_resource.should_receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end
  
    it "should return a current resource with the correct version if the package is found" do
      ::Dir.stub!(:entries).and_return(["git-foobar-0.9", "git-1.0.0"])
      @provider.load_current_resource
      @provider.current_resource.version.should == "1.0.0"
    end

    it "should return a current resource with the correct version if the package is found with revision" do
      ::Dir.stub!(:entries).and_return(["git-1.0.0-r1"])
      @provider.load_current_resource
      @provider.current_resource.version.should == "1.0.0-r1"
    end
  
    it "should return a current resource with a nil version if the package is not found" do
      ::Dir.stub!(:entries).and_return(["notgit-1.0.0"])
      @provider.load_current_resource
      @provider.current_resource.version.should be_nil
    end

  end
  
  describe "once the state of the package is known" do

    describe Chef::Provider::Package::Portage, "candidate_version" do
      it "should return the candidate_version variable if already setup" do
        @provider.candidate_version = "1.0.0"
        @provider.should_not_receive(:popen4)
        @provider.candidate_version
      end

      it "should lookup the candidate_version if the variable is not already set" do
        @status = mock("Status", :exitstatus => 0)
        @provider.stub!(:popen4).and_return(@status)
        @provider.should_receive(:popen4)
        @provider.candidate_version
      end

      it "should throw and exception if the exitstatus is not 0" do
        @status = mock("Status", :exitstatus => 1)
        @provider.stub!(:popen4).and_return(@status)
        lambda { @provider.candidate_version }.should raise_error(Chef::Exceptions::Package)
      end
  
    end

    describe Chef::Provider::Package::Portage, "install_package" do
      it "should install a normally versioned package using portage" do
        @provider.should_receive(:run_command_with_systems_locale).with({
          :command => "emerge -g --color n --nospinner --quiet =dev-util/git-1.0.0"
        })
        @provider.install_package("dev-util/git", "1.0.0")
      end

      it "should install a tilde versioned package using portage" do
        @provider.should_receive(:run_command_with_systems_locale).with({
          :command => "emerge -g --color n --nospinner --quiet ~dev-util/git-1.0.0"
        })
        @provider.install_package("dev-util/git", "~1.0.0")
      end

      it "should add options to the emerge command when specified" do
        @provider.should_receive(:run_command_with_systems_locale).with({
          :command => "emerge -g --color n --nospinner --quiet --oneshot =dev-util/git-1.0.0"
        })
        @new_resource.stub!(:options).and_return("--oneshot")
    
        @provider.install_package("dev-util/git", "1.0.0")
      end
    end

    describe Chef::Provider::Package::Portage, "remove_package" do
      it "should un-emerge the package with no version specified" do
        @provider.should_receive(:run_command_with_systems_locale).with({
          :command => "emerge --unmerge --color n --nospinner --quiet dev-util/git"
        })
        @provider.remove_package("dev-util/git", nil)
      end

      it "should un-emerge the package with a version specified" do
        @provider.should_receive(:run_command_with_systems_locale).with({
          :command => "emerge --unmerge --color n --nospinner --quiet =dev-util/git-1.0.0"
        })
        @provider.remove_package("dev-util/git", "1.0.0")
      end
    end
  end
end
