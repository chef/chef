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
      :updated => nil,
      :source => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "cups",
      :version => nil,
      :package_name => nil,
      :updated => nil
    )
    @status = mock("Status", :exitstatus => 0)
		@yum_cache = mock(
			'Chef::Provider::Yum::YumCache',
			:refresh => true,
			:flush => true,
		  :installed_version => "1.2.4-11.18.el5",
		  :candidate_version => "1.2.4-11.18.el5_2.3"
		)
		Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
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
  
  it "should set the installed version to nil on the current resource if no installed package" do
		@yum_cache.stub!(:installed_version).and_return(nil)
    @current_resource.should_receive(:version).with(nil).and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the installed version if yum has one" do
    @current_resource.should_receive(:version).with("1.2.4-11.18.el5").and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the candidate version if yum info has one" do
    @provider.load_current_resource
    @provider.candidate_version.should eql("1.2.4-11.18.el5_2.3")
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
      :updated => nil,
      :source => nil
    )
		@yum_cache = mock(
			'Chef::Provider::Yum::YumCache',
			:refresh => true,
			:flush => true,
		  :installed_version => "1.2.4-11.18.el5",
		  :candidate_version => "1.2.4-11.18.el5_2.3"
		)
		Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
  end
  
  it "should run yum install with the package name and version" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "yum -d0 -e0 -y install emacs-1.0"
    })
    @provider.install_package("emacs", "1.0")
  end

  it "should run yum localinstall if given a path to an rpm" do
    @new_resource.stub!(:source).and_return("/tmp/emacs-21.4-20.el5.i386.rpm")
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "yum -d0 -e0 -y localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
    })
    @provider.install_package("emacs", "21.4-20.el5")
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
      :updated => nil,
      :source => nil
    )
		@yum_cache = mock(
			'Chef::Provider::Yum::YumCache',
			:refresh => true,
			:flush => true,
		  :installed_version => "1.2.4-11.18.el5",
		  :candidate_version => "1.2.4-11.18.el5_2.3"
		)
		Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
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
  
  it "should run yum update if the package is installed and no version is given" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "yum -d0 -e0 -y update emacs"
    })
    @provider.upgrade_package(@new_resource.name, nil)
  end
  
  it "should run yum install if the package is installed and a version is given" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "yum -d0 -e0 -y install emacs-11"
    })
    @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
  end
  
  it "should run yum install if the package is not installed" do
    @current_resource.stub!(:version).and_return(nil)
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "yum -d0 -e0 -y install emacs-11"
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
      :updated => nil,
      :source => nil
    )
		@yum_cache = mock(
			'Chef::Provider::Yum::YumCache',
			:refresh => true,
			:flush => true,
		  :installed_version => "1.2.4-11.18.el5",
		  :candidate_version => "1.2.4-11.18.el5_2.3"
		)
		Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
  end
  
  it "should run yum remove with the package name" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "yum -d0 -e0 -y remove emacs-1.0"
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
      :updated => nil,
      :source => nil
    )
		@yum_cache = mock(
			'Chef::Provider::Yum::YumCache',
			:refresh => true,
			:flush => true,
		  :installed_version => "1.2.4-11.18.el5",
		  :candidate_version => "1.2.4-11.18.el5_2.3"
		)
		Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@node, @new_resource)
  end
  
  it "should run yum remove with the package name" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "yum -d0 -e0 -y remove emacs-1.0"    
    })
    @provider.purge_package("emacs", "1.0")
  end
end
