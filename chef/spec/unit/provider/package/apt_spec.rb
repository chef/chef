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

require 'spec_helper'
require 'ostruct'

describe Chef::Provider::Package::Apt do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("irssi", @run_context)
    @current_resource = Chef::Resource::Package.new("irssi", @run_context)

    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::Apt.new(@new_resource, @run_context)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @stdin = StringIO.new
    @stdout =<<-PKG_STATUS
irssi:
  Installed: (none)
  Candidate: 0.8.14-1ubuntu4
  Version table:
     0.8.14-1ubuntu4 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid/main Packages
PKG_STATUS
    @stderr = StringIO.new
    @pid = 12345
    @shell_out = OpenStruct.new(:stdout => @stdout,:stdin => @stdin,:stderr => @stderr,:status => @status,:exitstatus => 0)
  end

  describe "when loading current resource" do

    it "should create a current resource with the name of the new_resource" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @current_resource.should_receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run apt-cache policy with the package name" do
      @provider.should_receive(:shell_out!).with("apt-cache policy #{@new_resource.package_name}").and_return(@shell_out)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if package state is not installed" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @current_resource.should_receive(:version).with(nil).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version if package has one" do
      @stdout.replace(<<-INSTALLED)
sudo:
  Installed: 1.7.2p1-1ubuntu5.3
  Candidate: 1.7.2p1-1ubuntu5.3
  Version table:
 *** 1.7.2p1-1ubuntu5.3 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid-updates/main Packages
        500 http://security.ubuntu.com/ubuntu/ lucid-security/main Packages
        100 /var/lib/dpkg/status
     1.7.2p1-1ubuntu5 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid/main Packages
INSTALLED
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource
      @current_resource.version.should == "1.7.2p1-1ubuntu5.3"
      @provider.candidate_version.should eql("1.7.2p1-1ubuntu5.3")
    end

    it "should return the current resouce" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource.should eql(@current_resource)
    end

    # libmysqlclient-dev is a real package in newer versions of debian + ubuntu
    # list of virtual packages: http://www.debian.org/doc/packaging-manuals/virtual-package-names-list.txt
    it "should not install the virtual package there is a single provider package and it is installed" do
      @new_resource.package_name("libmysqlclient15-dev")
      virtual_package_out=<<-VPKG_STDOUT
libmysqlclient15-dev:
  Installed: (none)
  Candidate: (none)
  Version table:
VPKG_STDOUT
      virtual_package = mock(:stdout => virtual_package_out,:exitstatus => 0)
      @provider.should_receive(:shell_out!).with("apt-cache policy libmysqlclient15-dev").and_return(virtual_package)
      showpkg_out =<<-SHOWPKG_STDOUT
Package: libmysqlclient15-dev
Versions: 

Reverse Depends: 
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
Dependencies: 
Provides: 
Reverse Provides: 
libmysqlclient-dev 5.1.41-3ubuntu12.7
libmysqlclient-dev 5.1.41-3ubuntu12.10
libmysqlclient-dev 5.1.41-3ubuntu12
SHOWPKG_STDOUT
      showpkg = mock(:stdout => showpkg_out,:exitstatus => 0)
      @provider.should_receive(:shell_out!).with("apt-cache showpkg libmysqlclient15-dev").and_return(showpkg)
      real_package_out=<<-RPKG_STDOUT
libmysqlclient-dev:
  Installed: 5.1.41-3ubuntu12.10
  Candidate: 5.1.41-3ubuntu12.10
  Version table:
 *** 5.1.41-3ubuntu12.10 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid-updates/main Packages
        100 /var/lib/dpkg/status
     5.1.41-3ubuntu12.7 0
        500 http://security.ubuntu.com/ubuntu/ lucid-security/main Packages
     5.1.41-3ubuntu12 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid/main Packages
RPKG_STDOUT
      real_package = mock(:stdout => real_package_out,:exitstatus => 0)
      @provider.should_receive(:shell_out!).with("apt-cache policy libmysqlclient-dev").and_return(real_package)
      @provider.should_not_receive(:run_command_with_systems_locale)
      @provider.load_current_resource
    end

    it "should raise an exception if you specify a virtual package with multiple provider packages" do
      @new_resource.package_name("mp3-decoder")
      virtual_package_out=<<-VPKG_STDOUT
mp3-decoder:
  Installed: (none)
  Candidate: (none)
  Version table:
VPKG_STDOUT
      virtual_package = mock(:stdout => virtual_package_out,:exitstatus => 0)
      @provider.should_receive(:shell_out!).with("apt-cache policy mp3-decoder").and_return(virtual_package)
      showpkg_out=<<-SHOWPKG_STDOUT
Package: mp3-decoder
Versions: 

Reverse Depends: 
  nautilus,mp3-decoder
  vux,mp3-decoder
  plait,mp3-decoder
  ecasound,mp3-decoder
  nautilus,mp3-decoder
Dependencies: 
Provides: 
Reverse Provides: 
vlc-nox 1.0.6-1ubuntu1.8
vlc 1.0.6-1ubuntu1.8
vlc-nox 1.0.6-1ubuntu1
vlc 1.0.6-1ubuntu1
opencubicplayer 1:0.1.17-2
mpg321 0.2.10.6
mpg123 1.12.1-0ubuntu1
SHOWPKG_STDOUT
      showpkg = mock(:stdout => showpkg_out,:exitstatus => 0)
      @provider.should_receive(:shell_out!).with("apt-cache showpkg mp3-decoder").and_return(showpkg)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end

    it "should run apt-cache policy with the default_release option, if there is one and provider is explicitly defined" do
      @new_resource = Chef::Resource::AptPackage.new("irssi", @run_context)
      @provider = Chef::Provider::Package::Apt.new(@new_resource, @run_context)

      @new_resource.stub!(:default_release).and_return("lenny-backports")
      @new_resource.stub!(:provider).and_return("Chef::Provider::Package::Apt")
      @provider.should_receive(:shell_out!).with("apt-cache -o APT::Default-Release=lenny-backports policy irssi").and_return(@shell_out)
      @provider.load_current_resource
    end

  end

  describe "install_package" do
    it "should run apt-get install with the package name and version" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y install irssi=0.8.12-7",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.install_package("irssi", "0.8.12-7")
    end

    it "should run apt-get install with the package name and version and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y --force-yes install irssi=0.8.12-7",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.install_package("irssi", "0.8.12-7")
    end

    it "should run apt-get install with the package name and version and default_release if there is one and provider is explicitly defined" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y -o APT::Default-Release=lenny-backports install irssi=0.8.12-7",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:default_release).and_return("lenny-backports")
      @new_resource.stub!(:provider).and_return("Chef::Provider::Package::Apt")

      @provider.install_package("irssi", "0.8.12-7")
    end
  end

  describe Chef::Provider::Package::Apt, "upgrade_package" do

    it "should run install_package with the name and version" do
      @provider.should_receive(:install_package).with("irssi", "0.8.12-7")
      @provider.upgrade_package("irssi", "0.8.12-7")
    end
  end

  describe Chef::Provider::Package::Apt, "remove_package" do

    it "should run apt-get remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y remove irssi",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.remove_package("irssi", "0.8.12-7")
    end

    it "should run apt-get remove with the package name and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y --force-yes remove irssi",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.remove_package("irssi", "0.8.12-7")
    end
  end

  describe "when purging a package" do

    it "should run apt-get purge with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y purge irssi",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.purge_package("irssi", "0.8.12-7")
    end

    it "should run apt-get purge with the package name and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y --force-yes purge irssi",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.purge_package("irssi", "0.8.12-7")
    end
  end

  describe "when preseeding a package" do
    before(:each) do
      @provider.stub!(:get_preseed_file).and_return("/tmp/irssi-0.8.12-7.seed")
      @provider.stub!(:run_command_with_systems_locale).and_return(true)
    end

    it "should get the full path to the preseed response file" do
      @provider.should_receive(:get_preseed_file).with("irssi", "0.8.12-7").and_return("/tmp/irssi-0.8.12-7.seed")
      file = @provider.get_preseed_file("irssi", "0.8.12-7")
      @provider.preseed_package(file)
    end

    it "should run debconf-set-selections on the preseed file if it has changed" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "debconf-set-selections /tmp/irssi-0.8.12-7.seed",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      }).and_return(true)
      file = @provider.get_preseed_file("irssi", "0.8.12-7")
      @provider.preseed_package(file)
    end

    it "should not run debconf-set-selections if the preseed file has not changed" do
      @provider.stub(:check_package_state)
      @current_resource.version "0.8.11"
      @new_resource.response_file "/tmp/file"
      @provider.stub!(:get_preseed_file).and_return(false)
      @provider.should_not_receive(:run_command_with_systems_locale)
      @provider.run_action(:reconfig)
    end
  end

  describe "when reconfiguring a package" do
    before(:each) do
      @provider.stub!(:run_command_with_systems_locale).and_return(true)
    end

    it "should run dpkg-reconfigure package" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg-reconfigure irssi",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      }).and_return(true)
      @provider.reconfig_package("irssi", "0.8.12-7")
    end
  end

  describe "when installing a virtual package" do
    it "should install the package without specifying a version" do
        @provider.is_virtual_package = true
        @provider.should_receive(:run_command_with_systems_locale).with({
          :command => "apt-get -q -y install libmysqlclient-dev",
          :environment => {
            "DEBIAN_FRONTEND" => "noninteractive"
          }
        })
        @provider.install_package("libmysqlclient-dev", "not_a_real_version")
    end
  end
end
