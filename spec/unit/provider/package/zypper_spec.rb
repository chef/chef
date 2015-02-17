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

    @provider = Chef::Provider::Package::Zypper.new(@new_resource, @run_context)
    allow(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
    @status = double(:stdout => "\n", :exitstatus => 0)
    allow(@provider).to receive(:shell_out).and_return(@status)
    allow(@provider).to receive(:`).and_return("2.0")
  end

  describe "when loading the current package state" do
    it "should create a current resource with the name of the new_resource" do
      expect(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      expect(@current_resource).to receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run zypper info with the package name" do
      expect(@provider).to receive(:shell_out).with("zypper --non-interactive info #{@new_resource.package_name}").and_return(@status)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if zypper info installed version is (none)" do
      allow(@provider).to receive(:shell_out).and_return(@status)
      expect(@current_resource).to receive(:version).with(nil).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version if zypper info has one" do
      status = double(:stdout => "Version: 1.0\nInstalled: Yes\n", :exitstatus => 0)

      allow(@provider).to receive(:shell_out).and_return(status)
      expect(@current_resource).to receive(:version).with("1.0").and_return(true)
      @provider.load_current_resource
    end

    it "should set the candidate version if zypper info has one" do
      status = double(:stdout => "Version: 1.0\nInstalled: No\nStatus: out-of-date (version 0.9 installed)", :exitstatus => 0)

      allow(@provider).to receive(:shell_out).and_return(status)
      @provider.load_current_resource
      expect(@provider.candidate_version).to eql("1.0")
    end

    it "should raise an exception if zypper info fails" do
      expect(@status).to receive(:exitstatus).and_return(1)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end

    it "should not raise an exception if zypper info succeeds" do
      expect(@status).to receive(:exitstatus).and_return(0)
      expect { @provider.load_current_resource }.not_to raise_error
    end

    it "should return the current resouce" do
      expect(@provider.load_current_resource).to eql(@current_resource)
    end
  end

  describe "install_package" do
    it "should run zypper install with the package name and version" do
      allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(true)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive install --auto-agree-with-licenses emacs=1.0")
      @provider.install_package("emacs", "1.0")
    end
    it "should run zypper install without gpg checks" do
      allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(false)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.install_package("emacs", "1.0")
    end
    it "should warn about gpg checks on zypper install" do
      expect(Chef::Log).to receive(:warn).with(
        /All packages will be installed without gpg signature checks/)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.install_package("emacs", "1.0")
    end
  end

  describe "upgrade_package" do
    it "should run zypper update with the package name and version" do
      allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(true)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive install --auto-agree-with-licenses emacs=1.0")
      @provider.upgrade_package("emacs", "1.0")
    end
    it "should run zypper update without gpg checks" do
      allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(false)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.upgrade_package("emacs", "1.0")
    end
    it "should warn about gpg checks on zypper upgrade" do
      expect(Chef::Log).to receive(:warn).with(
        /All packages will be installed without gpg signature checks/)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")
      @provider.upgrade_package("emacs", "1.0")
    end
    it "should run zypper upgrade without gpg checks" do
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks install "+
        "--auto-agree-with-licenses emacs=1.0")

      @provider.upgrade_package("emacs", "1.0")
    end
  end

  describe "remove_package" do

    context "when package version is not explicitly specified" do
      it "should run zypper remove with the package name" do
        allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(true)
        expect(@provider).to receive(:shell_out!).with(
            "zypper --non-interactive remove emacs")
        @provider.remove_package("emacs", nil)
      end
    end

    context "when package version is explicitly specified" do
      it "should run zypper remove with the package name" do
        allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(true)
        expect(@provider).to receive(:shell_out!).with(
          "zypper --non-interactive remove emacs=1.0")
        @provider.remove_package("emacs", "1.0")
      end
      it "should run zypper remove without gpg checks" do
        allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(false)
        expect(@provider).to receive(:shell_out!).with(
            "zypper --non-interactive --no-gpg-checks remove emacs=1.0")
        @provider.remove_package("emacs", "1.0")
      end
      it "should warn about gpg checks on zypper remove" do
        expect(Chef::Log).to receive(:warn).with(
          /All packages will be installed without gpg signature checks/)
        expect(@provider).to receive(:shell_out!).with(
          "zypper --non-interactive --no-gpg-checks remove emacs=1.0")

        @provider.remove_package("emacs", "1.0")
      end
    end
  end

  describe "purge_package" do
    it "should run remove_package with the name and version" do
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks remove --clean-deps emacs=1.0")
      @provider.purge_package("emacs", "1.0")
    end
    it "should run zypper purge without gpg checks" do
      allow(Chef::Config).to receive(:[]).with(:zypper_check_gpg).and_return(false)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks remove --clean-deps emacs=1.0")
      @provider.purge_package("emacs", "1.0")
    end
    it "should warn about gpg checks on zypper purge" do
      expect(Chef::Log).to receive(:warn).with(
        /All packages will be installed without gpg signature checks/)
      expect(@provider).to receive(:shell_out!).with(
        "zypper --non-interactive --no-gpg-checks remove --clean-deps emacs=1.0")
      @provider.purge_package("emacs", "1.0")
    end
  end

  describe "on an older zypper" do
    before(:each) do
      allow(@provider).to receive(:`).and_return("0.11.6")
    end

    describe "install_package" do
      it "should run zypper install with the package name and version" do
        expect(@provider).to receive(:shell_out!).with(
          "zypper --no-gpg-checks install --auto-agree-with-licenses -y emacs")
        @provider.install_package("emacs", "1.0")
      end
    end

    describe "upgrade_package" do
      it "should run zypper update with the package name and version" do
        expect(@provider).to receive(:shell_out!).with(
          "zypper --no-gpg-checks install --auto-agree-with-licenses -y emacs")
        @provider.upgrade_package("emacs", "1.0")
      end
    end

    describe "remove_package" do
      it "should run zypper remove with the package name" do
        expect(@provider).to receive(:shell_out!).with(
           "zypper --no-gpg-checks remove -y emacs")
        @provider.remove_package("emacs", "1.0")
      end
    end
  end
end
