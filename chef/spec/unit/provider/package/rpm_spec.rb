#
# Author:: Joshua Timberman (<joshua@opscode.com>)
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

describe Chef::Provider::Package::Rpm, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil,
      :source => "/tmp/emacs-21.4-20.el5.i386.rpm"
    )
    @current_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => nil,
      :updated => nil
    )
    
    @provider = Chef::Provider::Package::Rpm.new(@node, @new_resource)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @status = mock("Status", :exitstatus => 0)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @provider.stub!(:popen4).and_return(@status)
    ::File.stub!(:exists?).and_return(true)
  end
  
  it "should create a current resource with the name of new_resource" do
    Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end
  
  it "should set the current reource package name to the new resource package name" do
    @current_resource.should_receive(:package_name).with(@new_resource.package_name)
    @provider.load_current_resource
  end
  
  it "should raise an exception if a source is supplied but not found" do
    ::File.stub!(:exists?).and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
  end
  
  it "should get the source package version from rpm if provided" do
    @stdout.stub!(:each).and_yield("emacs 21.4-20.el5")
    @provider.stub!(:popen4).with("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@new_resource.source}").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:package_name).with("emacs")
    @new_resource.should_receive(:version).with("21.4-20.el5")
    @provider.load_current_resource
  end
  
  it "should return the current version installed if found by rpm" do
    @stdout.stub!(:each).and_yield("emacs 21.4-20.el5")
    @provider.stub!(:popen4).with("rpm -q --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@current_resource.package_name}").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with("21.4-20.el5")
    @provider.load_current_resource
  end
  
  it "should raise an exception if the source is not set but we are installing" do
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil,
      :source => nil
    )
    @provider = Chef::Provider::Package::Rpm.new(@node, @new_resource)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)  
  end
  
  it "should raise an exception if rpm fails to run" do
    @status = mock("Status", :exitstatus => -1)
    @provider.stub!(:popen4).and_return(@status)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
  end
end

describe Chef::Provider::Package::Rpm, "install and upgrade" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil,
      :source => "/tmp/emacs-21.4-20.el5.i386.rpm"
    )
    @current_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => nil,
      :updated => nil
    )
    @provider = Chef::Provider::Package::Rpm.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  it "should run rpm -i with the package source to install" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "rpm -i /tmp/emacs-21.4-20.el5.i386.rpm"
    })
    @provider.install_package("emacs", "21.4-20.el5")
  end
  
  it "should run rpm -U with the package source to upgrade" do
    @current_resource.stub!(:version).and_return("21.4-19.el5")
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "rpm -U /tmp/emacs-21.4-20.el5.i386.rpm"
    })
    @provider.upgrade_package("emacs", "21.4-20.el5")
  end
end

describe Chef::Provider::Package::Rpm, "remove" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Rpm.new(@node, @new_resource)
  end

  it "should run rpm -e to remove the package" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "rpm -e emacs-21.4-20.el5"
    })
    @provider.remove_package("emacs", "21.4-20.el5")
  end
end
