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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Package, "initialize" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end
  
  it "should return a Chef::Provider::Package object" do
    provider = Chef::Provider::Package.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Package)
  end  
end

describe Chef::Provider::Package, "action_install" do
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
      :package_name => "emacs"
    )
    @provider = Chef::Provider::Package.new(@node, @new_resource)
    @provider.candidate_version = "1.0"
    @provider.current_resource = @current_resource
    @provider.stub!(:install_package).and_return(true)
  end
  
  it "should raise a Chef::Exception::Package if no version is specified, and no candidate is available" do
    @provider.candidate_version = nil
    lambda { @provider.action_install }.should raise_error(Chef::Exception::Package)
  end
  
  it "should install the package at the candidate_version if it is not already installed" do
    @provider.should_receive(:install_package).with(
      @new_resource.name, 
      @provider.candidate_version
    ).and_return(true)
    @provider.action_install
  end 
  
  it "should install the package at the version specified if it is not already installed" do
    @new_resource.stub!(:version).and_return("1.0")
    @provider.should_receive(:install_package).with(
      @new_resource.name, 
      @new_resource.version
    ).and_return(true)
    @provider.action_install
  end
  
  it "should install the package at the version specified if a different version is installed" do
    @new_resource.stub!(:version).and_return("1.0")
    @current_resource.stub!(:version).and_return("0.99")
    @provider.should_receive(:install_package).with(
      @new_resource.name, 
      @new_resource.version
    ).and_return(true)
    @provider.action_install
  end
  
  it "should not install the package if it is already installed and no version is specified" do
    @current_resource.stub!(:version).and_return("1.0")
    @provider.should_not_receive(:install_package)
    @provider.action_install
  end 
  
  it "should not install the package if it is already installed at the version specified" do
    @current_resource.stub!(:version).and_return("1.0")
    @new_resource.stub!(:version).and_return("1.0")
    @provider.should_not_receive(:install_package)
    @provider.action_install
  end
  
  it "should set the resource to updated if it installs the package" do
    @new_resource.should_recieve(:updated).with(true)
    @provider.action_install
  end
  
end

describe Chef::Provider::Package, "action_upgrade" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => nil,
      :package_name => "emacs"
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "emacs",
      :version => "0.99",
      :package_name => "emacs"
    )
    @provider = Chef::Provider::Package.new(@node, @new_resource)
    @provider.candidate_version = "1.0"
    @provider.current_resource = @current_resource
    @provider.stub!(:install_package).and_return(true)
  end

  it "should install the package if the current version is not the candidate version" do
    @provider.should_receive(:install_package).with(
      @new_resource.name, 
      @provider.candidate_version
    ).and_return(true)
    @provider.action_upgrade
  end
  
  it "should set the resource to updated if it installs the package" do
    @new_resource.should_recieve(:updated).with(true)
    @provider.action_upgrade
  end
  
  it "should not install the package if the current version is the candidate version" do
    @current_resource.stub!(:version).and_return("1.0")
    @provider.should_not_receive(:install_package)
    @provider.action_upgrade
  end
end

# Oh ruby, you are so nice.
# Remove is the same as purge, just with a different method.
%w{remove purge}.each do |act|
  act_string = "action_#{act}"
  act_symbol = "action_#{act}".to_sym
  act_method = "#{act}_package".to_sym
  
  describe Chef::Provider::Package, act_string do
    before(:each) do
      @node = mock("Chef::Node", :null_object => true)
      @new_resource = mock("Chef::Resource::Package", 
        :null_object => true,
        :name => "emacs",
        :version => nil,
        :package_name => "emacs"
      )
      @current_resource = mock("Chef::Resource::Package", 
        :null_object => true,
        :name => "emacs",
        :version => "0.99",
        :package_name => "emacs"
      )
      @provider = Chef::Provider::Package.new(@node, @new_resource)
      @provider.candidate_version = "1.0"
      @provider.current_resource = @current_resource
      @provider.stub!(act_method).and_return(true)
    end

    it "should #{act} the package if it is installed" do
      @provider.should_receive(act_method).with(
        @new_resource.name, 
        @new_resource.version
      ).and_return(true)
      @provider.send(act_symbol)
    end
  
    it "should #{act} the package at a specific version if it is installed at that version" do
      @new_resource.stub!(:version).and_return("1.0")
      @current_resource.stub!(:version).and_return("1.0")
      @provider.should_receive(act_method).with(
        @new_resource.name, 
        @new_resource.version
      ).and_return(true)
      @provider.send(act_symbol)
    end
  
    it "should not #{act} the package at a specific version if it is not installed at that version" do
      @new_resource.stub!(:version).and_return("1.0")
      @current_resource.stub!(:version).and_return("1.2")
      @provider.should_not_receive(act_method)
      @provider.send(act_symbol)
    end
  
    it "should not #{act} the package if it is not installed" do
      @provider.should_not_receive(act_method)
      @current_resource.stub!(:version).and_return(nil)
      @provider.send(act_symbol)
    end
  
    it "should set the resource to updated if it #{act}s the package" do
      @new_resource.should_recieve(:updated).with(true)
      @provider.send(act_symbol)
    end

  end
end

%w{install upgrade remove purge}.each do |act|
  act_string = "#{act}_package"
    
  describe Chef::Provider::Package, act_string do
    before(:each) do
      @node = mock("Chef::Node", :null_object => true)
      @new_resource = mock("Chef::Resource::Package", 
        :null_object => true,
        :name => "emacs",
        :version => nil,
        :package_name => "emacs"
      )
      @current_resource = mock("Chef::Resource::Package", 
        :null_object => true,
        :name => "emacs",
        :version => "0.99",
        :package_name => "emacs"
      )
      @provider = Chef::Provider::Package.new(@node, @new_resource)
      @provider.candidate_version = "1.0"
      @provider.current_resource = @current_resource
    end
    
    it "should raise Chef::Exception::UnsupportedAction" do
      lambda { @provider.send(act_string, @new_resource.name, @new_resource.version) }.should raise_error(Chef::Exception::UnsupportedAction)      
    end
  end
end