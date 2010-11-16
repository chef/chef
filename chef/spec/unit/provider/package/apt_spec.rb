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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Package::Apt do
  before(:each) do
    @node = Chef::Node.new
    @node.cookbook_collection = {}
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Package.new("emacs", @run_context)
    @current_resource = Chef::Resource::Package.new("emacs", @run_context)

    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::Apt.new(@new_resource, @run_context)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stdout.stub!(:each).and_yield("emacs:").
                         and_yield("  Installed: (none)").
                         and_yield("  Candidate: 0.1.1").
                         and_yield("  Version Table:")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  describe "when loading current resource" do

    it "should create a current resource with the name of the new_resource" do
      Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      @current_resource.should_receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run apt-cache policy with the package name" do
      @provider.should_receive(:popen4).with("apt-cache policy #{@new_resource.package_name}").and_return(@status)
      @provider.load_current_resource
    end

    it "should read stdout on apt-cache policy" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @stdout.should_receive(:each).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if apt-cache policy installed version is (none)" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:version).with(nil).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version if apt-cache policy has one" do
      @stdout.stub!(:each).and_yield("emacs:").
                           and_yield("  Installed: 0.1.1").
                           and_yield("  Candidate: 0.1.1").
                           and_yield("  Version Table:")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:version).with("0.1.1").and_return(true)
      @provider.load_current_resource
    end

    it "should set the candidate version if apt-cache policy has one" do
      @stdout.stub!(:each).and_yield("emacs:").
                           and_yield("  Installed: 0.1.1").
                           and_yield("  Candidate: 10").
                           and_yield("  Version Table:")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.candidate_version.should eql("10")
    end

    it "should raise an exception if apt-cache policy fails" do
      @status.should_receive(:exitstatus).and_return(1)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end

    it "should not raise an exception if apt-cache policy succeeds" do
      @status.should_receive(:exitstatus).and_return(0)
      lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if apt-cache policy does not return a candidate version" do
      @stdout.stub!(:each).and_yield("emacs:").
                           and_yield("  Installed: 0.1.1").
                           and_yield("  Candidate: (none)").
                           and_yield("  Version Table:")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end

    it "should return the current resouce" do
      @provider.load_current_resource.should eql(@current_resource)
    end

  end

  describe "install_package" do

    it "should run apt-get install with the package name and version" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y install emacs=1.0",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.install_package("emacs", "1.0")
    end

    it "should run apt-get install with the package name and version and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y --force-yes install emacs=1.0",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.install_package("emacs", "1.0")
    end
  end

  describe Chef::Provider::Package::Apt, "upgrade_package" do

    it "should run install_package with the name and version" do
      @provider.should_receive(:install_package).with("emacs", "1.0")
      @provider.upgrade_package("emacs", "1.0")
    end
  end

  describe Chef::Provider::Package::Apt, "remove_package" do

    it "should run apt-get remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y remove emacs",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.remove_package("emacs", "1.0")
    end

    it "should run apt-get remove with the package name and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y --force-yes remove emacs",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.remove_package("emacs", "1.0")
    end
  end

  describe "when purging a package" do

    it "should run apt-get purge with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y purge emacs",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @provider.purge_package("emacs", "1.0")
    end

    it "should run apt-get purge with the package name and options if specified" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "apt-get -q -y --force-yes purge emacs",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      })
      @new_resource.stub!(:options).and_return("--force-yes")

      @provider.purge_package("emacs", "1.0")
    end
  end

  describe "when preseeding a package" do
    before(:each) do
      @provider.stub!(:get_preseed_file).and_return("/tmp/emacs-10.seed")
      @provider.stub!(:run_command_with_systems_locale).and_return(true)
    end

    it "should get the full path to the preseed response file" do
      @provider.should_receive(:get_preseed_file).with("emacs", "10").and_return("/tmp/emacs-10.seed")
      @provider.preseed_package("emacs", "10")
    end

    it "should run debconf-set-selections on the preseed file if it has changed" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "debconf-set-selections /tmp/emacs-10.seed",
        :environment => {
          "DEBIAN_FRONTEND" => "noninteractive"
        }
      }).and_return(true)
      @provider.preseed_package("emacs", "10")
    end

    it "should not run debconf-set-selections if the preseed file has not changed" do
      @provider.stub!(:get_preseed_file).and_return(false)
      @provider.should_not_receive(:run_command_with_systems_locale)
      @provider.preseed_package("emacs", "10")
    end
  end
end
