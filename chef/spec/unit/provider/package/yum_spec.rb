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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Package::Yum do
  before(:each) do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Package.new('cups')
    @status = mock("Status", :exitstatus => 0)
    @yum_cache = mock(
      'Chef::Provider::Yum::YumCache',
      :refresh => true,
      :reload => true,
      :flush => true,
      :installed_version => "1.2.4-11.18.el5",
      :candidate_version => "1.2.4-11.18.el5_2.3",
      :version_available? => true
    )
    Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
    @stderr = StringIO.new
    @pid = mock("PID")
  end

  describe "when loading the current system state" do

    it "should create a current resource with the name of the new_resource" do
      @provider.load_current_resource
      @provider.current_resource.name.should == "cups"
    end

    it "should set the current resources package name to the new resources package name" do
      @provider.load_current_resource
      @provider.current_resource.package_name.should == "cups"
    end

    it "should set the installed version to nil on the current resource if no installed package" do
      @yum_cache.stub!(:installed_version).and_return(nil)
      @provider.load_current_resource
      @provider.current_resource.version.should be_nil
    end

    it "should set the installed version if yum has one" do
      @provider.load_current_resource
      @provider.current_resource.version.should == "1.2.4-11.18.el5"
    end

    it "should set the candidate version if yum info has one" do
      @provider.load_current_resource
      @provider.candidate_version.should eql("1.2.4-11.18.el5_2.3")
    end

    it "should return the current resouce" do
      @provider.load_current_resource.should eql(@provider.current_resource)
    end
  end

  describe "when installing a package" do
    it "should run yum install with the package name and version" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install emacs-1.0"
      })
      @provider.install_package("emacs", "1.0")
    end

    it "should run yum localinstall if given a path to an rpm" do
      @new_resource.stub!(:source).and_return("/tmp/emacs-21.4-20.el5.i386.rpm")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
      })
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "should run yum install with the package name, version and arch" do
      @new_resource.stub!(:arch).and_return("i386")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install emacs-21.4-20.el5.i386"
      })
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "installs the package with the options given in the resource" do
      @provider.candidate_version = '11'
      @new_resource.stub!(:options).and_return("--disablerepo epmd")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y --disablerepo epmd install cups-11"
      })
      @provider.install_package(@new_resource.name, @provider.candidate_version)
    end

    it "should fail if the package is not available" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :refresh => true,
        :reload => true,
        :flush => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5_2.3",
        :version_available? => nil
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      lambda { @provider.install_package("lolcats", "0.99") }.should raise_error(ArgumentError)
    end
  end

  describe "when upgrading a package" do
    it "should run yum update if the package is installed and no version is given" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  update cups"
      })
      @provider.upgrade_package(@new_resource.name, nil)
    end

    it "should run yum update with arch if the package is installed and no version is given" do
      @new_resource.stub!(:arch).and_return("i386")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  update cups.i386"
      })
      @provider.upgrade_package(@new_resource.name, nil)
    end

    it "should run yum install if the package is installed and a version is given" do
      @provider.candidate_version = '11'
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should run yum install if the package is not installed" do
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end
  end

  describe "when removing a package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  remove emacs-1.0"
      })
      @provider.remove_package("emacs", "1.0")
    end

    it "should run yum remove with the package name and arch" do
      @new_resource.stub!(:arch).and_return("x86_64")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  remove emacs-1.0.x86_64"
      })
      @provider.remove_package("emacs", "1.0")
    end
  end

  describe "when purging a package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  remove emacs-1.0"
      })
      @provider.purge_package("emacs", "1.0")
    end
  end

end
