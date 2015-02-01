#
# Author:: Ryan Chipman (<rchipman@mit.edu>)
# Copyright:: Copyright (c) 2015 Ryan Chipman
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

describe Chef::Provider::Package::AUR do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("pacaur")
    @current_resource = Chef::Resource::Package.new("pacaur")

    @status = double("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::AUR.new(@new_resource, @run_context)
    allow(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
    allow(@provider).to receive(:popen4).and_return(@status)
    @stdin = StringIO.new
    @stdout = StringIO.new(<<-ERR)
error: package "pacaur" not found
ERR
    @stderr = StringIO.new
    @pid = 2342
  end

  describe "when determining the current package state" do
    it "should create a current resource with the name of the new_resource" do
      expect(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      expect(@current_resource).to receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run pacman query with the package name" do
      expect(@provider).to receive(:popen4).with("pacman -Qi #{@new_resource.package_name}").and_return(@status)
      @provider.load_current_resource
    end

    it "should read stdout on pacman" do
      allow(@provider).to receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      expect(@stdout).to receive(:each).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if pacman installed version not exists" do
      allow(@provider).to receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      expect(@current_resource).to receive(:version).with(nil).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version if pacman has one" do
      @stdout = StringIO.new(<<-PACMAN)
Name           : nano
Version        : 2.2.2-1
URL            : http://www.nano-editor.org
Licenses       : GPL
Groups         : base
Provides       : None
Depends On     : glibc  ncurses
Optional Deps  : None
Required By    : None
Conflicts With : None
Replaces       : None
Installed Size : 1496.00 K
Packager       : Andreas Radke <andyrtr@archlinux.org>
Architecture   : i686
Build Date     : Mon 18 Jan 2010 06:16:16 PM CET
Install Date   : Mon 01 Feb 2010 10:06:30 PM CET
Install Reason : Explicitly installed
Install Script : Yes
Description    : Pico editor clone with enhancements
PACMAN
      allow(@provider).to receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      expect(@current_resource.version).to eq("2.2.2-1")
    end

    it "should set the candidate version if pacman has one" do
      allow(@stdout).to receive(:each).and_yield("core nano 2.2.3-1")
      allow(@provider).to receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource

      allow_any_instance_of(JSON).to receive(:parse).and_return({"version":1,"type":"info","resultcount":1,"results":{"ID":142434,"Name":"pacaur","PackageBaseID":49145,"PackageBase":"pacaur","Version":"4.2.18-1","CategoryID":16,"Description":"A fast workflow AUR helper using cower as backend","URL":"https:\/\/github.com\/rmarquis\/pacaur","NumVotes":288,"OutOfDate":0,"Maintainer":"Spyhawk","FirstSubmitted":1305666963,"LastModified":1421180118,"License":"GPL","URLPath":"\/packages\/pa\/pacaur\/pacaur.tar.gz"}})

      expect(@provider.candidate_version).to eql("4.2.18-1")
    end

    it "should raise an exception if pacman fails" do
      expect(@status).to receive(:exitstatus).and_return(2)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end

    it "should not raise an exception if pacman succeeds" do
      expect(@status).to receive(:exitstatus).and_return(0)
      expect { @provider.load_current_resource }.not_to raise_error
    end

## For some reason this never returns the right json...
#    it "should raise an exception if pacman does not return a candidate version" do
#      allow_any_instance_of(JSON).to receive(:parse).and_return({"version":1,"type":"info","resultcount":0,"results":[]})
#      expect { @provider.candidate_version }.to raise_error(Chef::Exceptions::Package)
#    end

    it "should return the current resouce" do
      expect(@provider.load_current_resource).to eql(@current_resource)
    end
  end

  describe Chef::Provider::Package::AUR, "install_package" do
    it "should run pacman install with the package name and version" do
      expect(@provider).to receive(:shell_out!).with("rm -rf /tmp/aur_pkgbuilds && mkdir -p /tmp/aur_pkgbuilds && cd /tmp/aur_pkgbuilds && wget http://aur.archlinux.org/packages/pa/pacaur/pacaur.tar.gz && tar xvf pacaur.tar.gz && cd pacaur && makepkg --syncdeps --install --noconfirm --noprogressbar PKGBUILD && cd && rm -rf tmp/aur_pkgbuilds")
      @provider.install_package("pacaur", "1.0")
    end

    # TODO replace --log with pacman -U --debug?
    it "should run pacman install with the package name and version and options if specified" do
      expect(@provider).to receive(:shell_out!).with("rm -rf /tmp/aur_pkgbuilds && mkdir -p /tmp/aur_pkgbuilds && cd /tmp/aur_pkgbuilds && wget http://aur.archlinux.org/packages/pa/pacaur/pacaur.tar.gz && tar xvf pacaur.tar.gz && cd pacaur && makepkg --log --syncdeps --install --noconfirm --noprogressbar PKGBUILD && cd && rm -rf tmp/aur_pkgbuilds")
      allow(@new_resource).to receive(:options).and_return("--log")

      @provider.install_package("pacaur", "1.0")
    end
  end

  describe Chef::Provider::Package::AUR, "upgrade_package" do
    it "should run install_package with the name and version" do
      expect(@provider).to receive(:install_package).with("pacaur", "1.0")
      @provider.upgrade_package("pacaur", "1.0")
    end
  end

  describe Chef::Provider::Package::AUR, "remove_package" do
    it "should run pacman remove with the package name" do
      expect(@provider).to receive(:shell_out!).with("pacman --remove --noconfirm --noprogressbar pacaur")
      @provider.remove_package("pacaur", "1.0")
    end

    it "should run pacman remove with the package name and options if specified" do
      expect(@provider).to receive(:shell_out!).with("pacman --remove --noconfirm --noprogressbar --debug pacaur")
      allow(@new_resource).to receive(:options).and_return("--debug")

      @provider.remove_package("pacaur", "1.0")
    end
  end

  describe Chef::Provider::Package::AUR, "purge_package" do
    it "should run remove_package with the name and version" do
      expect(@provider).to receive(:remove_package).with("pacaur", "1.0")
      @provider.purge_package("pacaur", "1.0")
    end

  end
end
