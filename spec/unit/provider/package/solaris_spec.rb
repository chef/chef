#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

describe Chef::Provider::Package::Solaris do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Package.new("SUNWbash")
    @new_resource.source("/tmp/bash.pkg")

    @provider = Chef::Provider::Package::Solaris.new(@new_resource, @run_context)
    allow(::File).to receive(:exist?).and_return(true)
  end

  describe "assessing the current package status" do
    before do
      @pkginfo = <<-PKGINFO
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

      @status = double("Status", :stdout => "", :exitstatus => 0)
    end

    it "should create a current resource with the name of new_resource" do
      allow(@provider).to receive(:shell_out).and_return(@status)
      @provider.load_current_resource
      expect(@provider.current_resource.name).to eq("SUNWbash")
    end

    it "should set the current reource package name to the new resource package name" do
      allow(@provider).to receive(:shell_out).and_return(@status)
      @provider.load_current_resource
      expect(@provider.current_resource.package_name).to eq("SUNWbash")
    end

    it "should raise an exception if a source is supplied but not found" do
      allow(@provider).to receive(:shell_out).and_return(@status)
      allow(::File).to receive(:exist?).and_return(false)
      @provider.load_current_resource
      @provider.define_resource_requirements
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Package)
    end

    it "should get the source package version from pkginfo if provided" do
      status = double(:stdout => @pkginfo, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("pkginfo", "-l", "-d", "/tmp/bash.pkg", "SUNWbash", { timeout: 900 }).and_return(status)
      expect(@provider).to receive(:shell_out).with("pkginfo", "-l", "SUNWbash", { timeout: 900 }).and_return(@status)
      @provider.load_current_resource

      expect(@provider.current_resource.package_name).to eq("SUNWbash")
      expect(@new_resource.version).to eq("11.10.0,REV=2005.01.08.05.16")
    end

    it "should return the current version installed if found by pkginfo" do
      status = double(:stdout => @pkginfo, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).with("pkginfo", "-l", "-d", "/tmp/bash.pkg", "SUNWbash", { timeout: 900 }).and_return(@status)
      expect(@provider).to receive(:shell_out).with("pkginfo", "-l", "SUNWbash", { timeout: 900 }).and_return(status)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq("11.10.0,REV=2005.01.08.05.16")
    end

    it "should raise an exception if the source is not set but we are installing" do
      @new_resource = Chef::Resource::Package.new("SUNWbash")
      @provider = Chef::Provider::Package::Solaris.new(@new_resource, @run_context)
      allow(@provider).to receive(:shell_out).and_return(@status)
      expect { @provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if pkginfo fails to run" do
      status = double(:stdout => "", :exitstatus => -1)
      allow(@provider).to receive(:shell_out).and_return(status)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end

    it "should return a current resource with a nil version if the package is not found" do
      expect(@provider).to receive(:shell_out).with("pkginfo", "-l", "-d", "/tmp/bash.pkg", "SUNWbash", { timeout: 900 }).and_return(@status)
      expect(@provider).to receive(:shell_out).with("pkginfo", "-l", "SUNWbash", { timeout: 900 }).and_return(@status)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to be_nil
    end
  end

  describe "candidate_version" do
    it "should return the candidate_version variable if already setup" do
      @provider.candidate_version = "11.10.0,REV=2005.01.08.05.16"
      expect(@provider).not_to receive(:shell_out)
      @provider.candidate_version
    end

    it "should lookup the candidate_version if the variable is not already set" do
      status = double(:stdout => "", :exitstatus => 0)
      allow(@provider).to receive(:shell_out).and_return(status)
      expect(@provider).to receive(:shell_out)
      @provider.candidate_version
    end

    it "should throw and exception if the exitstatus is not 0" do
      status = double(:stdout => "", :exitstatus => 1)
      allow(@provider).to receive(:shell_out).and_return(status)
      expect { @provider.candidate_version }.to raise_error(Chef::Exceptions::Package)
    end

  end

  describe "install and upgrade" do
    it "should run pkgadd -n -d with the package source to install" do
      expect(@provider).to receive(:shell_out!).with("pkgadd", "-n", "-d", "/tmp/bash.pkg", "all", { timeout: 900 })
      @provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgadd -n -d when the package is a path to install" do
      @new_resource = Chef::Resource::Package.new("/tmp/bash.pkg")
      @provider = Chef::Provider::Package::Solaris.new(@new_resource, @run_context)
      expect(@new_resource.source).to eq("/tmp/bash.pkg")
      expect(@provider).to receive(:shell_out!).with("pkgadd", "-n", "-d", "/tmp/bash.pkg", "all", { timeout: 900 })
      @provider.install_package("/tmp/bash.pkg", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgadd -n -a /tmp/myadmin -d with the package options -a /tmp/myadmin" do
      @new_resource.options "-a /tmp/myadmin"
      expect(@provider).to receive(:shell_out!).with("pkgadd", "-n", "-a", "/tmp/myadmin", "-d", "/tmp/bash.pkg", "all", { timeout: 900 })
      @provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end
  end

  describe "remove" do
    it "should run pkgrm -n to remove the package" do
      expect(@provider).to receive(:shell_out!).with("pkgrm", "-n", "SUNWbash", { timeout: 900 })
      @provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgrm -n -a /tmp/myadmin with options -a /tmp/myadmin" do
      @new_resource.options "-a /tmp/myadmin"
      expect(@provider).to receive(:shell_out!).with("pkgrm", "-n", "-a", "/tmp/myadmin", "SUNWbash", { timeout: 900 })
      @provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

  end
end
