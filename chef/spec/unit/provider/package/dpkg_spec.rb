#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Provider::Package::Dpkg do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("wget")
    @new_resource.source "/tmp/wget_1.11.4-1ubuntu1_amd64.deb"

    @provider = Chef::Provider::Package::Dpkg.new(@new_resource, @run_context)

    @stdin = StringIO.new
    @stdout = StringIO.new
    @status = mock("Status", :exitstatus => 0)
    @stderr = StringIO.new
    @pid = mock("PID")
    @provider.stub!(:popen4).and_return(@status)

    ::File.stub!(:exists?).and_return(true)
  end

  describe "when loading the current resource state" do

    it "should create a current resource with the name of the new_resource" do
      @provider.load_current_resource
      @provider.current_resource.package_name.should == "wget"
    end

    it "should raise an exception if a source is supplied but not found" do
      @provider.load_current_resource
      @provider.define_resource_requirements
      ::File.stub!(:exists?).and_return(false)
      lambda { @provider.run_action(:install) }.should raise_error(Chef::Exceptions::Package)
    end

    describe 'gets the source package version from dpkg-deb' do
      def check_version(version)
        @stdout = StringIO.new("wget\t#{version}")
        @provider.stub!(:popen4).with("dpkg-deb -W #{@new_resource.source}").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        @provider.load_current_resource
        @provider.current_resource.package_name.should == "wget"
        @new_resource.version.should == version
      end
      
      it 'if short version provided' do
        check_version('1.11.4')
      end
      
      it 'if extended version provided' do
        check_version('1.11.4-1ubuntu1')
      end
      
      it 'if distro-specific version provided' do
        check_version('1.11.4-1ubuntu1~lucid')
      end
    end

    it "gets the source package name from dpkg-deb correctly when the package name has `-', `+' or `.' characters" do
      @stdout = StringIO.new("f.o.o-pkg++2\t1.11.4-1ubuntu1")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.package_name.should == "f.o.o-pkg++2"
    end

    it "should raise an exception if the source is not set but we are installing" do
      @new_resource = Chef::Resource::Package.new("wget")
      @provider.new_resource = @new_resource
      @provider.define_resource_requirements
      @provider.load_current_resource
      lambda { @provider.run_action(:install)}.should raise_error(Chef::Exceptions::Package)
    end

    it "should return the current version installed if found by dpkg" do
      @stdout = StringIO.new(<<-DPKG_S)
Package: wget
Status: install ok installed
Priority: important
Section: web
Installed-Size: 1944
Maintainer: Ubuntu Core developers <ubuntu-devel-discuss@lists.ubuntu.com>
Architecture: amd64
Version: 1.11.4-1ubuntu1
Config-Version: 1.11.4-1ubuntu1
Depends: libc6 (>= 2.8~20080505), libssl0.9.8 (>= 0.9.8f-5)
Conflicts: wget-ssl
DPKG_S
      @provider.stub!(:popen4).with("dpkg -s wget").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)

      @provider.load_current_resource
      @provider.current_resource.version.should == "1.11.4-1ubuntu1"
    end

    it "should raise an exception if dpkg fails to run" do
      @status = mock("Status", :exitstatus => -1)
      @provider.stub!(:popen4).and_return(@status)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end
  end

  describe Chef::Provider::Package::Dpkg, "install and upgrade" do
    it "should run dpkg -i with the package source" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -i /tmp/wget_1.11.4-1ubuntu1_amd64.deb",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.install_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -i if the package is a path and the source is nil" do
      @new_resource = Chef::Resource::Package.new("/tmp/wget_1.11.4-1ubuntu1_amd64.deb")
      @provider = Chef::Provider::Package::Dpkg.new(@new_resource, @run_context)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -i /tmp/wget_1.11.4-1ubuntu1_amd64.deb",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.install_package("/tmp/wget_1.11.4-1ubuntu1_amd64.deb", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -i if the package is a path and the source is nil for an upgrade" do
      @new_resource = Chef::Resource::Package.new("/tmp/wget_1.11.4-1ubuntu1_amd64.deb")
      @provider = Chef::Provider::Package::Dpkg.new(@new_resource, @run_context)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -i /tmp/wget_1.11.4-1ubuntu1_amd64.deb",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.upgrade_package("/tmp/wget_1.11.4-1ubuntu1_amd64.deb", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -i with the package source and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -i --force-yes /tmp/wget_1.11.4-1ubuntu1_amd64.deb",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.install_package("wget", "1.11.4-1ubuntu1")
    end
    it "should upgrade by running install_package" do
      @provider.should_receive(:install_package).with("wget", "1.11.4-1ubuntu1")
      @provider.upgrade_package("wget", "1.11.4-1ubuntu1")
    end
  end

  describe Chef::Provider::Package::Dpkg, "remove and purge" do
    it "should run dpkg -r to remove the package" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -r wget",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.remove_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -r to remove the package with options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -r --force-yes wget",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.remove_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -P to purge the package" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -P wget",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.purge_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -P to purge the package with options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "dpkg -P --force-yes wget",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.purge_package("wget", "1.11.4-1ubuntu1")
    end
  end
end
