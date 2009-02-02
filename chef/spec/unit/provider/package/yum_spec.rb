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

describe Chef::Provider::Package::Yum, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "cups",
      :version => nil,
      :package_name => "cups",
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "cups",
      :version => nil,
      :package_name => nil,
      :updated => nil
    )
    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stdout.stub!(:each).and_yield("Installed Packages").
      and_yield("Name   : cups").
      and_yield("Arch   : i386").
      and_yield("Epoch  : 1").
      and_yield("Version: 1.2.4").
      and_yield("Release: 11.18.el5").
      and_yield("Size   : 7.8 M").
      and_yield("Repo   : installed").
      and_yield("Summary: Common Unix Printing System").
      and_yield("Description:").
      and_yield("The Common UNIX Printing System provides a portable printing layer for").
      and_yield("UNIX® operating systems. It has been developed by Easy Software Products").
      and_yield("to promote a standard printing solution for all UNIX vendors and users.").
      and_yield("CUPS provides the System V and Berkeley command-line interfaces.").
      and_yield("").
      and_yield("Available Packages").
      and_yield("Name   : cups").
      and_yield("Arch   : i386").
      and_yield("Epoch  : 1").
      and_yield("Version: 1.2.4").
      and_yield("Release: 11.18.el5_2.3").
      and_yield("Size   : 2.7 M").
      and_yield("Repo   : updates").
      and_yield("Summary: Common Unix Printing System").
      and_yield("Description:").
      and_yield("The Common UNIX Printing System provides a portable printing layer for").
      and_yield("UNIX® operating systems. It has been developed by Easy Software Products").
      and_yield("to promote a standard printing solution for all UNIX vendors and users.").
      and_yield("CUPS provides the System V and Berkeley command-line interfaces.")
    @stdout_available = mock("STDOUT AVAILABLE", :null_object => true)
    @stdout_available.stub!(:each).and_yield("Available Packages").
      and_yield("Name   : cups").
      and_yield("Arch   : i386").
      and_yield("Epoch  : 1").
      and_yield("Version: 1.2.4").
      and_yield("Release: 11.18.el5_2.3").
      and_yield("Size   : 2.7 M").
      and_yield("Repo   : updates").
      and_yield("Summary: Common Unix Printing System").
      and_yield("Description:").
      and_yield("The Common UNIX Printing System provides a portable printing layer for").
      and_yield("UNIX® operating systems. It has been developed by Easy Software Products").
      and_yield("to promote a standard printing solution for all UNIX vendors and users.").
      and_yield("CUPS provides the System V and Berkeley command-line interfaces.")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should create a current resource with the name of the new_resource" do
    Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end
  
  it "should set the current resources package name to the new resources package name" do
    @current_resource.should_receive(:package_name).with(@new_resource.package_name)
    @provider.load_current_resource
  end
  
  it "should run yum info with the package name" do
    @provider.should_receive(:popen4).with("yum info -q -y #{@new_resource.package_name}").and_return(@status)
    @provider.load_current_resource
  end
  
  it "should read stdout on yum info" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @stdout.should_receive(:each).and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the installed version to nil on the current resource if no installed package" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout_available, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with(nil).and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the installed version if yum info has one" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with("1.2.4-11.18.el5").and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the candidate version if yum info has one" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.load_current_resource
    @provider.candidate_version.should eql("1.2.4-11.18.el5_2.3")
  end
  
  it "should raise an exception if yum info fails" do
    @status.should_receive(:exitstatus).and_return(1)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exception::Package)
  end
  
  it "should not raise an exception if yum info succeeds" do
    @status.should_receive(:exitstatus).and_return(0)
    lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exception::Package)
  end
  
  it "should return the current resouce" do
    @provider.load_current_resource.should eql(@current_resource)
  end
end

describe Chef::Provider::Package::Yum, "install_package" do
  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
  end
  
  it "should run yum install with the package name and version" do
    @provider.should_receive(:run_command).with({
      :command => "yum -q -y install emacs-1.0"
    })
    @provider.install_package("emacs", "1.0")
  end
end

describe Chef::Provider::Package::Yum, "upgrade_package" do
  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => "10",
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
    @provider.candidate_version = "11"
    @provider.current_resource = @current_resource
  end
  
  it "should run yum update if the package is installed" do
    @provider.should_receive(:run_command).with({
      :command => "yum -q -y update emacs-11"
    })
    @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
  end
  
  it "should run yum install if the package is not installed" do
    @current_resource.stub!(:version).and_return(nil)
    @provider.should_receive(:run_command).with({
      :command => "yum -q -y install emacs-11"
    })
    @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
  end
end

describe Chef::Provider::Package::Yum, "remove_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
  end
  
  it "should run yum remove with the package name" do
    @provider.should_receive(:run_command).with({
      :command => "yum -q -y remove emacs-1.0"
    })
    @provider.remove_package("emacs", "1.0")
  end
end

describe Chef::Provider::Package::Yum, "purge_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => "10",
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
  end
  
  it "should run yum remove with the package name" do
    @provider.should_receive(:run_command).with({
      :command => "yum -q -y remove emacs-1.0"    
    })
    @provider.purge_package("emacs", "1.0")
  end
end
