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

describe Chef::Provider::Package::Zypper do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("cups")

    @current_resource = Chef::Resource::Package.new("cups")

    @status = mock("Status", :exitstatus => 0)

    @provider = Chef::Provider::Package::Zypper.new(@new_resource, @run_context)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @provider.stub!(:popen4).and_return(@status)
    @stderr = StringIO.new
    @stdout = StringIO.new
    @pid = mock("PID")
    @provider.stub!(:`).and_return("2.0")
  end

  describe "when loading the current package state" do
    it "should create a current resource with the name of the new_resource" do
      Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      @current_resource.should_receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run zypper info with the package name" do
      @provider.should_receive(:popen4).with("zypper --non-interactive info #{@new_resource.package_name}").and_return(@status)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if zypper info installed version is (none)" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:version).with(nil).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version if zypper info has one" do
      @stdout = StringIO.new("Version: 1.0\nInstalled: Yes\n")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:version).with("1.0").and_return(true)
      @provider.load_current_resource
    end

    it "should set the candidate version if zypper info has one" do
      @stdout = StringIO.new("Version: 1.0\nInstalled: No\nStatus: out-of-date (version 0.9 installed)")

      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.candidate_version.should eql("1.0")
    end

    it "should raise an exception if zypper info fails" do
      @status.should_receive(:exitstatus).and_return(1)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end

    it "should not raise an exception if zypper info succeeds" do
      @status.should_receive(:exitstatus).and_return(0)
      lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::Package)
    end

    it "should return the current resouce" do
      @provider.load_current_resource.should eql(@current_resource)
    end
  end

  describe "install_package" do
    it "should run zypper install with the package name and version" do
      Chef::Config.stub(:[]).with(:zypper_check_gpg).and_return(true)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive install --auto-agree-with-licenses emacs=1.0")
      @provider.install_package("emacs", "1.0")
    end
    it "should run zypper install without gpg checks" do
      Chef::Config.stub(:[]).with(:zypper_check_gpg).and_return(false)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.install_package("emacs", "1.0")
    end
    it "should warn about gpg checks on zypper install" do
      Chef::Log.should_receive(:warn).with(
        /All packages will be installed without gpg signature checks/)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.install_package("emacs", "1.0")
    end
  end

  describe "upgrade_package" do
    it "should run zypper update with the package name and version" do
      Chef::Config.stub(:[]).with(:zypper_check_gpg).and_return(true)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive install --auto-agree-with-licenses emacs=1.0")
      @provider.upgrade_package("emacs", "1.0")
    end
    it "should run zypper update without gpg checks" do
      Chef::Config.stub(:[]).with(:zypper_check_gpg).and_return(false)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.upgrade_package("emacs", "1.0")
    end
    it "should warn about gpg checks on zypper upgrade" do
      Chef::Log.should_receive(:warn).with(
        /All packages will be installed without gpg signature checks/)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.upgrade_package("emacs", "1.0")
    end
    it "should run zypper upgrade without gpg checks" do
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")

      @provider.upgrade_package("emacs", "1.0")
    end
  end

  describe "remove_package" do
    it "should run zypper remove with the package name" do
      Chef::Config.stub(:[]).with(:zypper_check_gpg).and_return(true)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive remove emacs=1.0")
      @provider.remove_package("emacs", "1.0")
    end
    it "should run zypper remove without gpg checks" do
      Chef::Config.stub(:[]).with(:zypper_check_gpg).and_return(false)
      @provider.should_receive(:shell_out!).with(
          "zypper --non-interactive --no-gpg-checks remove emacs=1.0")
      @provider.remove_package("emacs", "1.0")
    end
    it "should warn about gpg checks on zypper remove" do
      Chef::Log.should_receive(:warn).with(
        /All packages will be installed without gpg signature checks/)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks remove emacs=1.0")

      @provider.remove_package("emacs", "1.0")
    end
  end

  describe "purge_package" do
    it "should run remove_package with the name and version" do
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks remove --clean-deps emacs=1.0")
      @provider.purge_package("emacs", "1.0")
    end
    it "should run zypper purge without gpg checks" do
      Chef::Config.stub(:[]).with(:zypper_check_gpg).and_return(false)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks remove --clean-deps emacs=1.0")
      @provider.purge_package("emacs", "1.0")
    end
    it "should warn about gpg checks on zypper purge" do
      Chef::Log.should_receive(:warn).with(
        /All packages will be installed without gpg signature checks/)
      @provider.should_receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks remove --clean-deps emacs=1.0")
      @provider.purge_package("emacs", "1.0")
    end
  end

  describe "on an older zypper" do
    before(:each) do
      @provider.stub!(:`).and_return("0.11.6")
    end

    describe "install_package" do
      it "should run zypper install with the package name and version" do
        @provider.should_receive(:shell_out!).with(
          "zypper --no-gpg-checks install --auto-agree-with-licenses -y emacs")
        @provider.install_package("emacs", "1.0")
      end
    end

    describe "upgrade_package" do
      it "should run zypper update with the package name and version" do
        @provider.should_receive(:shell_out!).with(
          "zypper --no-gpg-checks install --auto-agree-with-licenses -y emacs")
        @provider.upgrade_package("emacs", "1.0")
      end
    end

    describe "remove_package" do
      it "should run zypper remove with the package name" do
        @provider.should_receive(:shell_out!).with(
           "zypper --no-gpg-checks remove -y emacs")
        @provider.remove_package("emacs", "1.0")
      end
    end
  end
end
