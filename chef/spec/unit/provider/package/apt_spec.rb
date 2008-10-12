#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

describe Chef::Provider::Package::Apt, "load_current_resource" do
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
      :version => nil,
      :package_name => nil,
      :updated => nil
    )
    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::Apt.new(@node, @new_resource)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @provider.stub!(:popen4).and_return(@status)
  end
  
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
  
  it "should raise an exception if apt-cache policy fails" do
    @status.should_receive(:exitstatus).and_return(1)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exception::Package)
  end
  
  it "should not raise an exception if apt-cache policy succeeds" do
    @status.should_receive(:exitstatus).and_return(0)
    lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exception::Package)
  end
  
  it "should return the current resouce" do
    @provider.load_current_resource.should eql(@current_resource)
  end
end

describe Chef::Provider::Package::Apt, "install_package" do
  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Apt.new(@node, @new_resource)
  end
  
  it "should run apt-get install with the package name and version" do
    @provider.should_receive(:run_command).with({
      :command => "apt-get -q -y install emacs=1.0",
      :environment => {
        "DEBIAN_FRONTEND" => "noninteractive"
      }
    })
    @provider.install_package("emacs", "1.0")
  end
end

describe Chef::Provider::Package::Apt, "upgrade_package" do
  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Apt.new(@node, @new_resource)
  end
  
  it "should run install_package with the name and version" do
    @provider.should_receive(:install_package).with("emacs", "1.0")
    @provider.upgrade_package("emacs", "1.0")
  end
end

describe Chef::Provider::Package::Apt, "remove_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Apt.new(@node, @new_resource)
  end
  
  it "should run apt-get remove with the package name" do
    @provider.should_receive(:run_command).with({
      :command => "apt-get -q -y remove emacs",
      :environment => {
        "DEBIAN_FRONTEND" => "noninteractive"
      }
    })
    @provider.remove_package("emacs", "1.0")
  end
end

describe Chef::Provider::Package::Apt, "purge_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Apt.new(@node, @new_resource)
  end
  
  it "should run apt-get purge with the package name" do
    @provider.should_receive(:run_command).with({
      :command => "apt-get -q -y purge emacs",
      :environment => {
        "DEBIAN_FRONTEND" => "noninteractive"
      }
    })
    @provider.purge_package("emacs", "1.0")
  end
end