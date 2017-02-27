#
# Author:: Vasiliy Tolstov <v.tolstov@selfip.ru>
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

# based on the ips specs

describe Chef::Provider::Package::Paludis do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("net/ntp")
    @current_resource = Chef::Resource::Package.new("net/ntp")
    allow(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
    @provider = Chef::Provider::Package::Paludis.new(@new_resource, @run_context)

    @stdin = StringIO.new
    @stderr = StringIO.new
    @stdout = <<-PKG_STATUS
group/ntp 0 accounts
group/ntp 0 installed-accounts
net/ntp 4.2.6_p5-r2 arbor
user/ntp 0 accounts
user/ntp 0 installed-accounts
net/ntp 4.2.6_p5-r1 installed
PKG_STATUS
    @pid = 12345
    @shell_out = OpenStruct.new(:stdout => @stdout, :stdin => @stdin, :stderr => @stderr, :status => @status, :exitstatus => 0)
  end

  context "when loading current resource" do
    it "should create a current resource with the name of the new_resource" do
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      expect(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      expect(@current_resource).to receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run pkg info with the package name" do
      expect(@provider).to receive(:shell_out!).with("cave", "-L", "warning", "print-ids", "-M", "none", "-m", @new_resource.package_name, "-f", "%c/%p %v %r\n").and_return(@shell_out)
      @provider.load_current_resource
    end

    it "should return new version if package is installed" do
      @stdout.replace(<<-INSTALLED)
group/ntp 0 accounts
group/ntp 0 installed-accounts
net/ntp 4.2.6_p5-r2 arbor
user/ntp 0 accounts
user/ntp 0 installed-accounts
net/ntp 4.2.6_p5-r1 installed
INSTALLED
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource
      expect(@current_resource.version).to eq("4.2.6_p5-r1")
      expect(@provider.candidate_version).to eql("4.2.6_p5-r2")
    end

    it "should return the current resource" do
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      expect(@provider.load_current_resource).to eql(@current_resource)
    end
  end

  context "when installing a package" do
    it "should run pkg install with the package name and version" do
      expect(@provider).to receive(:shell_out!).with("cave", "-L", "warning", "resolve", "-x", "=net/ntp-4.2.6_p5-r2", { :timeout => @new_resource.timeout || 900 })
      @provider.install_package("net/ntp", "4.2.6_p5-r2")
    end

    it "should run pkg install with the package name and version and options if specified" do
      expect(@provider).to receive(:shell_out!).with("cave", "-L", "warning", "resolve", "-x", "--preserve-world", "=net/ntp-4.2.6_p5-r2", { :timeout => @new_resource.timeout || 900 })
      @new_resource.options "--preserve-world"
      @provider.install_package("net/ntp", "4.2.6_p5-r2")
    end

    it "should not contain invalid characters for the version string" do
      @stdout.replace(<<-PKG_STATUS)
sys-process/lsof 4.87 arbor
sys-process/lsof 4.87 x86_64
PKG_STATUS
      expect(@provider).to receive(:shell_out!).with("cave", "-L", "warning", "resolve", "-x", "=sys-process/lsof-4.87", { :timeout => @new_resource.timeout || 900 })
      @provider.install_package("sys-process/lsof", "4.87")
    end

    it "should not include the human-readable version in the candidate_version" do
      @stdout.replace(<<-PKG_STATUS)
sys-process/lsof 4.87 arbor
sys-process/lsof 4.87 x86_64
PKG_STATUS
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource
      expect(@current_resource.version).to be_nil
      expect(@provider.candidate_version).to eql("4.87")
    end
  end

  context "when upgrading a package" do
    it "should run pkg install with the package name and version" do
      expect(@provider).to receive(:shell_out!).with("cave", "-L", "warning", "resolve", "-x", "=net/ntp-4.2.6_p5-r2", { :timeout => @new_resource.timeout || 900 })
      @provider.upgrade_package("net/ntp", "4.2.6_p5-r2")
    end
  end

  context "when uninstalling a package" do
    it "should run pkg uninstall with the package name and version" do
      expect(@provider).to receive(:shell_out!).with("cave", "-L", "warning", "uninstall", "-x", "=net/ntp-4.2.6_p5-r2")
      @provider.remove_package("net/ntp", "4.2.6_p5-r2")
    end

  end
end
