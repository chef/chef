#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Provider::Package::Solaris, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "SUNWbash",
      :version => nil,
      :package_name => "SUNWbash",
      :updated => nil,
      :source => "/tmp/bash.pkg"
    )
    @current_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "SUNWbash",
      :version => "nil",
      :package_name => nil,
      :updated => nil
    )
    
    @provider = Chef::Provider::Package::Solaris.new(@node, @new_resource)
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
  
  it "should get the source package version from pkginfo if provided" do
    @stdout.stub!(:each).and_yield("PKGINST:  SUNWbash").
			and_yield("NAME:  GNU Bourne-Again shell (bash)").
			and_yield("CATEGORY:  system").
			and_yield("ARCH:  sparc").
			and_yield("VERSION:  11.10.0,REV=2005.01.08.05.16").
			and_yield("BASEDIR:  /").
			and_yield("VENDOR:  Sun Microsystems, Inc.").
			and_yield("DESC:  GNU Bourne-Again shell (bash) version 3.0").
			and_yield("PSTAMP:  sfw10-patch20070430084444").
			and_yield("INSTDATE:  Nov 04 2009 01:02").
			and_yield("HOTLINE:  Please contact your local service provider")
    @provider.stub!(:popen4).with("pkginfo -l -d #{@new_resource.source} #{@new_resource.package_name}").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:package_name).with("SUNWbash")
    @new_resource.should_receive(:version).with("11.10.0,REV=2005.01.08.05.16")
    @provider.load_current_resource
  end
  
  it "should return the current version installed if found by pkginfo" do
    @stdout.stub!(:each).and_yield("PKGINST:  SUNWbash").
                        and_yield("NAME:  GNU Bourne-Again shell (bash)").
                        and_yield("CATEGORY:  system").
                        and_yield("ARCH:  sparc").
                        and_yield("VERSION:  11.10.0,REV=2005.01.08.05.16").
                        and_yield("BASEDIR:  /").
                        and_yield("VENDOR:  Sun Microsystems, Inc.").
                        and_yield("DESC:  GNU Bourne-Again shell (bash) version 3.0").
                        and_yield("PSTAMP:  sfw10-patch20070430084444").
                        and_yield("INSTDATE:  Nov 04 2009 01:02").
                        and_yield("HOTLINE:  Please contact your local service provider")
    @provider.stub!(:popen4).with("pkginfo -l #{@current_resource.package_name}").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with("11.10.0,REV=2005.01.08.05.16")
    @provider.load_current_resource
  end
  
  it "should raise an exception if the source is not set but we are installing" do
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "SUNWbash",
      :version => nil,
      :package_name => "SUNWbash",
      :updated => nil,
      :source => nil
    )
    @provider = Chef::Provider::Package::Solaris.new(@node, @new_resource)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)  
  end
  
  it "should raise an exception if rpm fails to run" do
    @status = mock("Status", :exitstatus => -1)
    @provider.stub!(:popen4).and_return(@status)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
  end

  it "should return a current resource with a nil version if the package is not found" do
    @stdout.stub!(:each).and_yield("")
    @provider.stub!(:popen4).with("pkginfo -l #{@current_resource.package_name}").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with(nil)
    @provider.load_current_resource
  end

end

describe Chef::Provider::Package::Solaris, "candidate_version" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "SUNWbash",
      :version => nil,
      :package_name => "SUNWbash",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Solaris.new(@node, @new_resource)
  end
  
  it "should return the candidate_version variable if already setup" do
    @provider.candidate_version = "11.10.0,REV=2005.01.08.05.16"
    @provider.should_not_receive(:popen4)
    @provider.candidate_version
  end

  it "should lookup the candidate_version if the variable is not already set" do
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @provider.should_receive(:popen4)
    @provider.candidate_version
  end

  it "should throw and exception if the exitstatus is not 0" do
    @status = mock("Status", :exitstatus => 1)
    @provider.stub!(:popen4).and_return(@status)
    lambda { @provider.candidate_version }.should raise_error(Chef::Exceptions::Package)
  end
  
end

describe Chef::Provider::Package::Solaris, "install and upgrade" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "SUNWbash",
      :version => nil,
      :package_name => "SUNWbash",
      :updated => nil,
      :source => "/tmp/bash.pkg",
      :options => nil
    )
    @current_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "SUNWbash",
      :version => nil,
      :package_name => nil,
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Solaris.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  it "should run pkgadd -n -d with the package source to install" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkgadd -n -d /tmp/bash.pkg all"
    })
    @provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
  end

  it "should run pkgadd -n -a /tmp/myadmin -d with the package options -a /tmp/myadmin" do
    @new_resource.stub!(:options).and_return("-a /tmp/myadmin")
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkgadd -n -a /tmp/myadmin -d /tmp/bash.pkg all"
    })
    @provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
  end

  
end

describe Chef::Provider::Package::Solaris, "remove" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "SUNWbash",
      :version => nil,
      :package_name => "SUNWbash",
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Solaris.new(@node, @new_resource)
  end

  it "should run pkgrm -n to remove the package" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkgrm -n SUNWbash"
    })
    @provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
  end

  it "should run pkgrm -n -a /tmp/myadmin with options -a /tmp/myadmin" do
    @new_resource.stub!(:options).and_return("-a /tmp/myadmin")
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkgrm -n -a /tmp/myadmin SUNWbash"
    })
    @provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
  end

end
