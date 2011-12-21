#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Copyright:: Copyright (c) 2010 Jan Zimmek
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

describe Chef::Provider::Package::Pacman do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("nano")
    @current_resource = Chef::Resource::Package.new("nano")

    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::Pacman.new(@new_resource, @run_context)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = StringIO.new
    @stdout = StringIO.new(<<-ERR)
error: package "nano" not found
ERR
    @stderr = StringIO.new
    @pid = 2342
  end

  describe "when determining the current package state" do
    it "should create a current resource with the name of the new_resource" do
      Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      @current_resource.should_receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run pacman query with the package name" do
      @provider.should_receive(:popen4).with("pacman -Qi #{@new_resource.package_name}").and_return(@status)
      @provider.load_current_resource
    end

    it "should read stdout on pacman" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @stdout.should_receive(:each).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if pacman installed version not exists" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:version).with(nil).and_return(true)
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
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @current_resource.version.should == "2.2.2-1"
    end

    it "should set the candidate version if pacman has one" do
      @stdout.stub!(:each).and_yield("core/nano 2.2.3-1 (base)").
                            and_yield("    Pico editor clone with enhancements").
                            and_yield("community/nanoblogger 3.4.1-1").
                            and_yield("    NanoBlogger is a small weblog engine written in Bash for the command line")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.candidate_version.should eql("2.2.3-1")
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

      ::File.stub!(:exists?).with("/etc/pacman.conf").and_return(true)
      ::File.stub!(:read).with("/etc/pacman.conf").and_return(@pacman_conf)
      @stdout.stub!(:each).and_yield("customrepo/nano 1.2.3-4").
                            and_yield("    My custom package")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)

      @provider.load_current_resource
      @provider.candidate_version.should eql("1.2.3-4")
    end

    it "should raise an exception if pacman fails" do
      @status.should_receive(:exitstatus).and_return(2)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end

    it "should not raise an exception if pacman succeeds" do
      @status.should_receive(:exitstatus).and_return(0)
      lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if pacman does not return a candidate version" do
      @stdout.stub!(:each).and_yield("")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      lambda { @provider.candidate_version }.should raise_error(Chef::Exceptions::Package)
    end

    it "should return the current resouce" do
      @provider.load_current_resource.should eql(@current_resource)
    end
  end

  describe Chef::Provider::Package::Pacman, "install_package" do
    it "should run pacman install with the package name and version" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pacman --sync --noconfirm --noprogressbar nano"
      })
      @provider.install_package("nano", "1.0")
    end

    it "should run pacman install with the package name and version and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pacman --sync --noconfirm --noprogressbar --debug nano"
      })
      @new_resource.stub!(:options).and_return("--debug")

      @provider.install_package("nano", "1.0")
    end
  end

  describe Chef::Provider::Package::Pacman, "upgrade_package" do
    it "should run install_package with the name and version" do
      @provider.should_receive(:install_package).with("nano", "1.0")
      @provider.upgrade_package("nano", "1.0")
    end
  end

  describe Chef::Provider::Package::Pacman, "remove_package" do
    it "should run pacman remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pacman --remove --noconfirm --noprogressbar nano"
      })
      @provider.remove_package("nano", "1.0")
    end

    it "should run pacman remove with the package name and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "pacman --remove --noconfirm --noprogressbar --debug nano"
      })
      @new_resource.stub!(:options).and_return("--debug")

      @provider.remove_package("nano", "1.0")
    end
  end

  describe Chef::Provider::Package::Pacman, "purge_package" do
    it "should run remove_package with the name and version" do
      @provider.should_receive(:remove_package).with("nano", "1.0")
      @provider.purge_package("nano", "1.0")
    end

  end
end
