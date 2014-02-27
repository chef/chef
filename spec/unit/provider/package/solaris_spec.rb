#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'spec_helper'

describe Chef::Provider::Package::Solaris do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Package.new("SUNWbash")
    @new_resource.source("/tmp/bash.pkg")

    @provider = Chef::Provider::Package::Solaris.new(@new_resource, @run_context)
    ::File.stub(:exists?).and_return(true)
  end

  describe "assessing the current package status" do
    before do
      @pkginfo =<<-PKGINFO
PKGINST:  SUNWbash
NAME:  GNU Bourne-Again shell (bash)
CATEGORY:  system
ARCH:  sparc
VERSION:  11.10.0,REV=2005.01.08.05.16
BASEDIR:  /
VENDOR:  Sun Microsystems, Inc.
DESC:  GNU Bourne-Again shell (bash) version 3.0
PSTAMP:  sfw10-patch20070430084444
INSTDATE:  Nov 04 2009 01:02
HOTLINE:  Please contact your local service provider
PKGINFO

      @status = double("Status", :exitstatus => 0)
    end

    it "should create a current resource with the name of new_resource" do
      @provider.stub(:popen4).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.name.should == "SUNWbash"
    end

    it "should set the current reource package name to the new resource package name" do
      @provider.stub(:popen4).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.package_name.should == "SUNWbash"
    end

    it "should raise an exception if a source is supplied but not found" do
      @provider.stub(:popen4).and_return(@status)
      ::File.stub(:exists?).and_return(false)
      @provider.define_resource_requirements
      @provider.load_current_resource
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Package)
    end


    it "should get the source package version from pkginfo if provided" do
      @stdout = StringIO.new(@pkginfo)
      @stdin, @stderr = StringIO.new, StringIO.new
      @provider.should_receive(:popen4).with("pkginfo -l -d /tmp/bash.pkg SUNWbash").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.should_receive(:popen4).with("pkginfo -l SUNWbash").and_return(@status)
      @provider.load_current_resource

      @provider.current_resource.package_name.should == "SUNWbash"
      @new_resource.version.should == "11.10.0,REV=2005.01.08.05.16"
    end

    it "should return the current version installed if found by pkginfo" do
      @stdout = StringIO.new(@pkginfo)
      @stdin, @stderr = StringIO.new, StringIO.new
      @provider.should_receive(:popen4).with("pkginfo -l -d /tmp/bash.pkg SUNWbash").and_return(@status)
      @provider.should_receive(:popen4).with("pkginfo -l SUNWbash").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.version.should == "11.10.0,REV=2005.01.08.05.16"
    end

    it "should raise an exception if the source is not set but we are installing" do
      @new_resource = Chef::Resource::Package.new("SUNWbash")
      @provider = Chef::Provider::Package::Solaris.new(@new_resource, @run_context)
      @provider.stub(:popen4).and_return(@status)
      lambda { @provider.run_action(:install) }.should raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if pkginfo fails to run" do
      @status = double("Status", :exitstatus => -1)
      @provider.stub(:popen4).and_return(@status)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end

    it "should return a current resource with a nil version if the package is not found" do
      @stdout = StringIO.new
      @provider.should_receive(:popen4).with("pkginfo -l -d /tmp/bash.pkg SUNWbash").and_return(@status)
      @provider.should_receive(:popen4).with("pkginfo -l SUNWbash").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.version.should be_nil
    end
  end

  describe "candidate_version" do
    it "should return the candidate_version variable if already setup" do
      @provider.candidate_version = "11.10.0,REV=2005.01.08.05.16"
      @provider.should_not_receive(:popen4)
      @provider.candidate_version
    end

    it "should lookup the candidate_version if the variable is not already set" do
      @status = double("Status", :exitstatus => 0)
      @provider.stub(:popen4).and_return(@status)
      @provider.should_receive(:popen4)
      @provider.candidate_version
    end

    it "should throw and exception if the exitstatus is not 0" do
      @status = double("Status", :exitstatus => 1)
      @provider.stub(:popen4).and_return(@status)
      lambda { @provider.candidate_version }.should raise_error(Chef::Exceptions::Package)
    end

  end

  describe "install and upgrade" do
    it "should run pkgadd -n -d with the package source to install" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pkgadd -n -d /tmp/bash.pkg all"
      })
      @provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgadd -n -d when the package is a path to install" do
      @new_resource = Chef::Resource::Package.new("/tmp/bash.pkg")
      @provider = Chef::Provider::Package::Solaris.new(@new_resource, @run_context)
      @new_resource.source.should == "/tmp/bash.pkg"
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pkgadd -n -d /tmp/bash.pkg all"
      })
      @provider.install_package("/tmp/bash.pkg", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgadd -n -a /tmp/myadmin -d with the package options -a /tmp/myadmin" do
      @new_resource.stub(:options).and_return("-a /tmp/myadmin")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pkgadd -n -a /tmp/myadmin -d /tmp/bash.pkg all"
      })
      @provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end
  end

  describe "remove" do
    it "should run pkgrm -n to remove the package" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pkgrm -n SUNWbash"
      })
      @provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgrm -n -a /tmp/myadmin with options -a /tmp/myadmin" do
      @new_resource.stub(:options).and_return("-a /tmp/myadmin")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pkgrm -n -a /tmp/myadmin SUNWbash"
      })
      @provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

  end
end
