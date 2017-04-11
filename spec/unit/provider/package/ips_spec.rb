#
# Author:: Bryan McLellan <btm@chef.io>
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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
require "ostruct"

# based on the apt specs

describe Chef::Provider::Package::Ips do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::IpsPackage.new("crypto/gnupg", @run_context)
    @current_resource = Chef::Resource::IpsPackage.new("crypto/gnupg", @run_context)
    allow(Chef::Resource::IpsPackage).to receive(:new).and_return(@current_resource)
    @provider = Chef::Provider::Package::Ips.new(@new_resource, @run_context)
  end

  def local_output
    stdin  = StringIO.new
    stdout = ""
    stderr = <<-PKG_STATUS
pkg: info: no packages matching the following patterns you specified are
installed on the system.  Try specifying -r to query remotely:

   crypto/gnupg
PKG_STATUS
    OpenStruct.new(:stdout => stdout, :stdin => stdin, :stderr => stderr, :status => @status, :exitstatus => 1)
  end

  def remote_output
    stdout = <<-PKG_STATUS
          Name: security/sudo
       Summary: sudo - authority delegation tool
         State: Not Installed
     Publisher: omnios
       Version: 1.8.4.1 (1.8.4p1)
 Build Release: 5.11
        Branch: 0.151002
Packaging Date: April  1, 2012 05:55:52 PM
          Size: 2.57 MB
          FMRI: pkg://omnios/security/sudo@1.8.4.1,5.11-0.151002:20120401T175552Z
PKG_STATUS
    stdin = StringIO.new
    stderr = ""
    OpenStruct.new(:stdout => stdout, :stdin => stdin, :stderr => stderr, :status => @status, :exitstatus => 0)
  end

  context "when loading current resource" do
    it "should create a current resource with the name of the new_resource" do
      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local_output)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote_output)
      expect(Chef::Resource::IpsPackage).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local_output)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote_output)
      @provider.load_current_resource
      expect(@current_resource.package_name).to eq(@new_resource.package_name)
    end

    it "should run pkg info with the package name" do
      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local_output)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote_output)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if package state is not installed" do
      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local_output)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote_output)
      @provider.load_current_resource
      expect(@current_resource.version).to be_nil
    end

    it "should set the installed version if package has one" do
      local = local_output
      local.stdout = <<-INSTALLED
          Name: crypto/gnupg
       Summary: GNU Privacy Guard
   Description: A complete and free implementation of the OpenPGP Standard as
                defined by RFC4880.
      Category: Applications/System Utilities
         State: Installed
     Publisher: solaris
       Version: 2.0.17
 Build Release: 5.11
        Branch: 0.175.0.0.0.2.537
Packaging Date: October 19, 2011 09:14:50 AM
          Size: 8.07 MB
          FMRI: pkg://solaris/crypto/gnupg@2.0.17,5.11-0.175.0.0.0.2.537:20111019T091450Z
INSTALLED
      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote_output)
      @provider.load_current_resource
      expect(@current_resource.version).to eq("2.0.17")
    end

    it "should return the current resource" do
      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local_output)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote_output)
      expect(@provider.load_current_resource).to eql(@current_resource)
    end
  end

  context "when installing a package" do
    it "should run pkg install with the package name and version" do
      expect(@provider).to receive(:shell_out!).with("pkg", "install", "-q", "crypto/gnupg@2.0.17", timeout: 900)
      @provider.install_package("crypto/gnupg", "2.0.17")
    end

    it "should run pkg install with the package name and version and options if specified" do
      expect(@provider).to receive(:shell_out!).with("pkg", "--no-refresh", "install", "-q", "crypto/gnupg@2.0.17", timeout: 900)
      @new_resource.options "--no-refresh"
      @provider.install_package("crypto/gnupg", "2.0.17")
    end

    it "raises an error if package fails to install" do
      expect(@provider).to receive(:shell_out!).with("pkg", "--no-refresh", "install", "-q", "crypto/gnupg@2.0.17", timeout: 900).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      @new_resource.options("--no-refresh")
      expect { @provider.install_package("crypto/gnupg", "2.0.17") }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end

    it "should not include the human-readable version in the candidate_version" do
      remote = remote_output
      remote.stdout = <<-PKG_STATUS
          Name: security/sudo
       Summary: sudo - authority delegation tool
         State: Not Installed
     Publisher: omnios
       Version: 1.8.4.1 (1.8.4p1)
 Build Release: 5.11
        Branch: 0.151002
Packaging Date: April  1, 2012 05:55:52 PM
          Size: 2.57 MB
          FMRI: pkg://omnios/security/sudo@1.8.4.1,5.11-0.151002:20120401T175552Z
PKG_STATUS
      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local_output)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote)
      @provider.load_current_resource
      expect(@current_resource.version).to be_nil
      expect(@provider.candidate_version).to eql("1.8.4.1")
    end

    it "should not upgrade the package if it is already installed" do
      local = local_output
      local.stdout = <<-INSTALLED
          Name: crypto/gnupg
       Summary: GNU Privacy Guard
   Description: A complete and free implementation of the OpenPGP Standard as
                defined by RFC4880.
      Category: Applications/System Utilities
         State: Installed
     Publisher: solaris
       Version: 2.0.17
 Build Release: 5.11
        Branch: 0.175.0.0.0.2.537
Packaging Date: October 19, 2011 09:14:50 AM
          Size: 8.07 MB
          FMRI: pkg://solaris/crypto/gnupg@2.0.17,5.11-0.175.0.0.0.2.537:20111019T091450Z
INSTALLED
      remote = remote_output
      remote.stdout = <<-REMOTE
          Name: crypto/gnupg
       Summary: GNU Privacy Guard
   Description: A complete and free implementation of the OpenPGP Standard as
                defined by RFC4880.
      Category: Applications/System Utilities
         State: Not Installed
     Publisher: solaris
       Version: 2.0.18
 Build Release: 5.11
        Branch: 0.175.0.0.0.2.537
Packaging Date: October 19, 2011 09:14:50 AM
          Size: 8.07 MB
          FMRI: pkg://solaris/crypto/gnupg@2.0.18,5.11-0.175.0.0.0.2.537:20111019T091450Z
REMOTE

      expect(@provider).to receive(:shell_out).with("pkg", "info", @new_resource.package_name, timeout: 900).and_return(local)
      expect(@provider).to receive(:shell_out!).with("pkg", "info", "-r", @new_resource.package_name, timeout: 900).and_return(remote)
      expect(@provider).to receive(:install_package).exactly(0).times
      @provider.run_action(:install)
    end

    context "when accept_license is true" do
      before do
        @new_resource.accept_license(true)
      end

      it "should run pkg install with the --accept flag" do
        expect(@provider).to receive(:shell_out).with("pkg", "install", "-q", "--accept", "crypto/gnupg@2.0.17", timeout: 900).and_return(local_output)
        @provider.install_package("crypto/gnupg", "2.0.17")
      end
    end
  end

  context "when upgrading a package" do
    it "should run pkg install with the package name and version" do
      expect(@provider).to receive(:shell_out).with("pkg", "install", "-q", "crypto/gnupg@2.0.17", timeout: 900).and_return(local_output)
      @provider.upgrade_package("crypto/gnupg", "2.0.17")
    end
  end

  context "when uninstalling a package" do
    it "should run pkg uninstall with the package name and version" do
      expect(@provider).to receive(:shell_out!).with("pkg", "uninstall", "-q", "crypto/gnupg@2.0.17", timeout: 900)
      @provider.remove_package("crypto/gnupg", "2.0.17")
    end

    it "should run pkg uninstall with the package name and version and options if specified" do
      expect(@provider).to receive(:shell_out!).with("pkg", "--no-refresh", "uninstall", "-q", "crypto/gnupg@2.0.17", timeout: 900)
      @new_resource.options "--no-refresh"
      @provider.remove_package("crypto/gnupg", "2.0.17")
    end
  end
end
