#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2010 Daniel DeLeo
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

describe Chef::Provider::RemoteDirectory do
  before do
    @resource = Chef::Resource::RemoteDirectory.new("/tmp/tafty")
    @resource.source "path/on/server"
    @node = Chef::Node.new
    @node.name "latte"
    @node.platform :mac_os_x
    @node.platform_version "10.6"
    @provider = Chef::Provider::RemoteDirectory.new(@node, @resource)
    @provider.current_resource = @resource.clone
  end
  
  it "doesn't support create_if_missing and explodes if you try to use it" do
    lambda {@provider.send :action_create_if_missing}.should raise_error(Chef::Exceptions::UnsupportedAction)
  end
  
  describe "recursively transferring files" do
    before do
      @resource.mode  "0750"
      @resource.group "wheel"
      @resource.owner "root"
      
      @resource.files_mode  "0640"
      @resource.files_group "staff"
      @resource.files_owner "toor"
      @resource.files_backup 23
      
      @provider.current_resource = @resource.clone
    end
    
    it "creates Directory resources and assigns them the correct attributes" do
      directory_resource = @provider.send(:provider_for_directory, "/tmp/intermediate_dir").new_resource
      directory_resource.path.should  == "/tmp/intermediate_dir"
      directory_resource.mode.should  == "0750"
      directory_resource.group.should == "wheel"
      directory_resource.owner.should == "root"
      directory_resource.recursive.should be_true
    end
    
    it "creates intermediate directories as required" do
      @directory_resource = mock("Resource::Directory", :updated => true)
      @directory_provider = mock("Provider::Directory", :new_resource => @directory_resource)
      @directory_provider.should_receive(:load_current_resource)
      @directory_provider.should_receive(:action_create)
      @provider.stub!(:provider_for_directory).and_return(@directory_provider)
      @provider.send(:ensure_directory_exists, "/tmp/an_intermediate_dir")
      @resource.updated.should be_true
    end
    
    it "creates remote_file resources and assigns them the correct attributes" do
      @resource.cookbook "berlin_style_tasty_cupcakes"
      rf_provider = @provider.send(:provider_for_remote_file, 
                                    "/enclosing_dir/file_to_transfer.txt", 
                                    "file_to_transfer.txt")
      rf_resource = rf_provider.new_resource
      rf_resource.cookbook_name.should  == "berlin_style_tasty_cupcakes"
      rf_resource.source.should         == "path/on/server/file_to_transfer.txt"
      rf_resource.mode.should           == "0640"
      rf_resource.group.should          == "staff"
      rf_resource.owner.should          == "toor"
      rf_resource.backup.should         == 23
    end
    
    it "fetches files using remote file resources" do
      @rf_resource = mock("Resource::RemoteFile", :updated => true)
      @rf_provider = mock("Provider::RemoteFile", :new_resource => @rf_resource)
      
      @rf_provider.should_receive(:load_current_resource)
      @rf_provider.should_receive(:action_create)
      
      @provider.stub!(:ensure_directory_exists)
      @provider.stub!(:provider_for_remote_file).and_return(@rf_provider)
      
      @provider.send(:fetch_remote_file, "foo")
      @resource.updated.should be_true
    end
  end
  
  describe "generating the list of files to transfer" do
    
    after do
      Chef::Config[:solo] = false
    end
    
    it "lists the directory contents from the cookbook for chef-solo" do
      Chef::Config[:solo] = true
      @source_path = File.join(File.dirname(__FILE__), "..", "..", "data", "remote_directory_data")
      @resource.source(@source_path)
      @provider.stub!(:find_preferred_file).and_return(@source_path)
      
      file_list = @provider.send(:generate_solo_file_list)
      file_list.map! { |f| ::File.expand_path(f) }
      expected_file_list = %w{ remote_subdirectory/remote_subdir_file.txt remote_dir_file.txt }
      expected_file_list.map! { |f| ::File.expand_path(::File.join(@source_path, f)) }
      file_list.should == expected_file_list
    end
    
    it "requests a recursive file listing from the server for chef-client" do
      @resource.source("dir_on_the_server")
      Chef::Config[:solo] = false
      
      @rest = mock("Chef::REST")
      Chef::REST.should_receive(:new).and_return(@rest)
      
      list = %w{ foo bar baz}
      @rest.should_receive(:get_rest).with("cookbooks//files?id=dir_on_the_server&recursive=true").and_return(list)
      @provider.send(:generate_client_file_list).should == list
      
    end
    
  end
end