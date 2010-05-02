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
      :updated => nil,
      :response_file => nil
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
  
  it "should raise a Chef::Exceptions::Package if no version is specified, and no candidate is available" do
    @provider.candidate_version = nil
    lambda { @provider.action_install }.should raise_error(Chef::Exceptions::Package)
  end
  
  it "should call preseed_package if a response_file is given" do
    @new_resource.stub!(:response_file).and_return("foo")
    @provider.should_receive(:preseed_package).with(
      @new_resource.name, 
      @provider.candidate_version
    ).and_return(true)
    @provider.action_install
  end
  
  it "should not call preseed_package if a response_file is not given" do
    @provider.should_not_receive(:preseed_package)
    @provider.action_install
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

  it "should call the candidate_version accessor if the package is not currently installed" do
    @provider.should_receive(:candidate_version).and_return(true)
    @provider.action_install
  end 

  it "should not call the candidate_version accessor if the package is already installed and no version is specified" do
    @current_resource.stub!(:version).and_return("1.0")
    @provider.should_not_receive(:candidate_version)
    @provider.action_install
  end

  it "should not call the candidate_version accessor if the package is already installed at the version specified" do
    @current_resource.stub!(:version).and_return("1.0")
    @new_resource.stub!(:version).and_return("1.0")
    @provider.should_not_receive(:candidate_version)
    @provider.action_install
  end

  it "should not call the candidate_version accessor if the package is not installed new package's version is specified" do
    @new_resource.stub!(:version).and_return("1.0")
    @provider.should_not_receive(:candidate_version)
    @provider.action_install
  end

  it "should not call the candidate_version accessor if the package at the version specified is a different version than installed" do
    @new_resource.stub!(:version).and_return("1.0")
    @current_resource.stub!(:version).and_return("0.99")
    @provider.should_not_receive(:candidate_version)
    @provider.action_install
  end
  
  it "should set the resource to updated if it installs the package" do
    @new_resource.should_receive(:updated=).with(true)
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
      :package_name => "emacs", 
      :to_s => 'package[emacs]'
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
    @provider.stub!(:upgrade_package).and_return(true)
  end

  it "should upgrade the package if the current version is not the candidate version" do
    @provider.should_receive(:upgrade_package).with(
      @new_resource.name, 
      @provider.candidate_version
    ).and_return(true)
    @provider.action_upgrade
  end
  
  it "should set the resource to updated if it installs the package" do
    @new_resource.should_receive(:updated=).with(true)
    @provider.action_upgrade
  end
  
  it "should not install the package if the current version is the candidate version" do
    @current_resource.stub!(:version).and_return("1.0")
    @provider.should_not_receive(:upgrade_package)
    @provider.action_upgrade
  end
  
  it "should print the word 'uninstalled' if there was no original version" do
    @current_resource.stub!(:version).and_return(nil)
    Chef::Log.should_receive(:info).with("Upgrading #{@new_resource} version from uninstalled to 1.0")
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
      @new_resource.should_receive(:updated=).with(true)
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
    
    it "should raise Chef::Exceptions::UnsupportedAction" do
      lambda { @provider.send(act_string, @new_resource.name, @new_resource.version) }.should raise_error(Chef::Exceptions::UnsupportedAction)      
    end
  end
end

describe Chef::Provider::Package, "preseed_package" do
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
  
  it "should raise Chef::Exceptions::UnsupportedAction" do
    lambda { @provider.preseed_package(@new_resource.name, @new_resource.version) }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end
end

describe Chef::Provider::Package, "get_preseed_file" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "java",
      :version => nil,
      :package_name => "java",
      :cookbook_name => "java"
    )
    @provider = Chef::Provider::Package.new(@node, @new_resource)
    @provider.candidate_version = "1.0"
    @provider.current_resource = @current_resource
    
    @remote_file = mock("Chef::Resource::RemoteFile", 
      :null_object => true,
      :cookbook_name => "java",
      :source => "java-6.seed",
      :backup => false,
      :updated => false
    )
    @rf_provider = mock("Chef::Provider::RemoteFile",
      :null_object => true,
      :load_current_resource => true,
      :action_create => true
    )
    Chef::Resource::RemoteFile.stub!(:new).and_return(@remote_file)
    Chef::Platform.stub!(:find_provider_for_node).and_return(Chef::Provider::RemoteFile)
    Chef::Provider::RemoteFile.stub!(:new).and_return(@rf_provider)
    Chef::FileCache.stub!(:create_cache_path).and_return("/tmp")
    Chef::FileCache.stub!(:load).and_return("/tmp/java-6.seed")
  end
  
  it "should find the full cache path" do
    Chef::FileCache.should_receive(:create_cache_path).with("preseed/java")
    @provider.get_preseed_file("java", "6")
  end
  
  it "should create a new RemoteFile for the response file" do
    Chef::Resource::RemoteFile.should_receive(:new).with(
      "/tmp/java-6.seed",
      nil,
      @node
    ).and_return(@remote_file)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should set the cookbook name of the remote file to the new resources cookbook name" do
    @remote_file.should_receive(:cookbook_name=).with(@new_resource.cookbook_name).and_return(true)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should set remote files source to the new resources response file" do
    @remote_file.should_receive(:source).with(@new_resource.response_file).and_return(true)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should never back up the cached response file" do
    @remote_file.should_receive(:backup).with(false).and_return(true)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should find the provider for the remote file" do
    Chef::Platform.should_receive(:find_provider_for_node).and_return(Chef::Provider::RemoteFile)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should create a new provider for the remote file" do
    Chef::Provider::RemoteFile.should_receive(:new).with(@node, @remote_file).and_return(@rf_provider)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should load the current resource state for the remote file" do
    @rf_provider.should_receive(:load_current_resource)
    @provider.get_preseed_file("java", "6")
  end
   
  it "should run the create action for the remote file" do
    @rf_provider.should_receive(:action_create)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should check to see if the response file has been updated" do
    @remote_file.should_receive(:updated).and_return(false)
    @provider.get_preseed_file("java", "6")
  end
  
  it "should return false if the response file has not been updated" do
    @provider.get_preseed_file("java", "6").should be(false)
  end
  
  it "should return the full path to the cached response file if the response file has been updated" do
    @remote_file.should_receive(:updated).and_return(true)
    @provider.get_preseed_file("java", "6").should == "/tmp/java-6.seed"
  end
end
