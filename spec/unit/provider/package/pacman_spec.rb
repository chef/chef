#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Copyright:: Copyright 2010-2016, Jan Zimmek
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

describe Chef::Provider::Package::Pacman do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("nano")
    @current_resource = Chef::Resource::Package.new("nano")

    @status = double(:stdout => "", :exitstatus => 0)
    @provider = Chef::Provider::Package::Pacman.new(@new_resource, @run_context)
    allow(Chef::Resource::Package).to receive(:new).and_return(@current_resource)

    allow(@provider).to receive(:shell_out).and_return(@status)
    @stdin = StringIO.new
    @stdout = StringIO.new(<<-ERR)
error: package "nano" not found
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
      expect(@provider).to receive(:shell_out).with("pacman", "-Qi", @new_resource.package_name, { timeout: 900 }).and_return(@status)
      @provider.load_current_resource
    end

    it "should read stdout on pacman" do
      allow(@provider).to receive(:shell_out).and_return(@status)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if pacman installed version not exists" do
      allow(@provider).to receive(:shell_out).and_return(@status)
      @provider.load_current_resource
    end

    it "should set the installed version if pacman has one" do
      stdout = <<-PACMAN
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

      status = double(:stdout => stdout, :exitstatus => 0)
      allow(@provider).to receive(:shell_out).and_return(status)
      @provider.load_current_resource
      expect(@current_resource.version).to eq("2.2.2-1")
    end

    it "should set the candidate version if pacman has one" do
      status = double(:stdout => "core nano 2.2.3-1", :exitstatus => 0)
      allow(@provider).to receive(:shell_out).and_return(status)
      @provider.load_current_resource
      expect(@provider.candidate_version).to eql("2.2.3-1")
    end

    it "should use pacman.conf to determine valid repo names for package versions" do
      @pacman_conf = <<-PACMAN_CONF
[options]
HoldPkg      = pacman glibc
Architecture = auto

[customrepo]
Server = https://my.custom.repo

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist
PACMAN_CONF

      status = double(:stdout => "customrepo nano 1.2.3-4", :exitstatus => 0)
      allow(::File).to receive(:exist?).with("/etc/pacman.conf").and_return(true)
      allow(::File).to receive(:read).with("/etc/pacman.conf").and_return(@pacman_conf)
      allow(@provider).to receive(:shell_out).and_return(status)

      @provider.load_current_resource
      expect(@provider.candidate_version).to eql("1.2.3-4")
    end

    it "should raise an exception if pacman fails" do
      expect(@status).to receive(:exitstatus).and_return(2)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end

    it "should not raise an exception if pacman succeeds" do
      expect(@status).to receive(:exitstatus).and_return(0)
      expect { @provider.load_current_resource }.not_to raise_error
    end

    it "should raise an exception if pacman does not return a candidate version" do
      allow(@provider).to receive(:shell_out).and_return(@status)
      expect { @provider.candidate_version }.to raise_error(Chef::Exceptions::Package)
    end

    it "should return the current resouce" do
      expect(@provider.load_current_resource).to eql(@current_resource)
    end
  end

  describe Chef::Provider::Package::Pacman, "install_package" do
    it "should run pacman install with the package name and version" do
      expect(@provider).to receive(:shell_out!).with("pacman", "--sync", "--noconfirm", "--noprogressbar", "nano", { timeout: 900 })
      @provider.install_package("nano", "1.0")
    end

    it "should run pacman install with the package name and version and options if specified" do
      expect(@provider).to receive(:shell_out!).with("pacman", "--sync", "--noconfirm", "--noprogressbar", "--debug", "nano", { timeout: 900 })
      @new_resource.options("--debug")

      @provider.install_package("nano", "1.0")
    end
  end

  describe Chef::Provider::Package::Pacman, "upgrade_package" do
    it "should run install_package with the name and version" do
      expect(@provider).to receive(:install_package).with("nano", "1.0")
      @provider.upgrade_package("nano", "1.0")
    end
  end

  describe Chef::Provider::Package::Pacman, "remove_package" do
    it "should run pacman remove with the package name" do
      expect(@provider).to receive(:shell_out!).with("pacman", "--remove", "--noconfirm", "--noprogressbar", "nano", { timeout: 900 })
      @provider.remove_package("nano", "1.0")
    end

    it "should run pacman remove with the package name and options if specified" do
      expect(@provider).to receive(:shell_out!).with("pacman", "--remove", "--noconfirm", "--noprogressbar", "--debug", "nano", { timeout: 900 })
      @new_resource.options("--debug")

      @provider.remove_package("nano", "1.0")
    end
  end

  describe Chef::Provider::Package::Pacman, "purge_package" do
    it "should run remove_package with the name and version" do
      expect(@provider).to receive(:remove_package).with("nano", "1.0")
      @provider.purge_package("nano", "1.0")
    end

  end
end
