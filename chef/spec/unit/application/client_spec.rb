#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Application::Client, "initialize" do
  before do
    @app = Chef::Application::Client.new
  end
  
  it "should create an instance of Chef::Application::Client" do
    @app.should be_kind_of(Chef::Application::Client)
  end
end

describe Chef::Application::Client, "reconfigure" do
  before do
    @app = Chef::Application::Client.new
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config.stub!(:[]).with(:json_attribs).and_return(nil)
  end
  
  it "should set the delay based on the interval and splay values"

  describe "when the json_attribs configuration option is specified" do
    before do
      Chef::Config.stub!(:[]).with(:json_attribs).and_return("/etc/chef/dna.json")
      @json = mock("IO", :null_object => true)
      Kernel.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
    end
    
    it "should try and open the json attribute file"
    
    it "should bomb out on a socket error"
    
    it "should bomb out if the json file doesn't exist"
    
    it "should bomb out if we don't have sufficient access to the json file"
    
    it "should bomb out on an unexpected exception"
  end
end

describe Chef::Application::Client, "setup_application" do
  before do
    @chef_client = mock("Chef::Client", :null_object => true)
    Chef::Client.stub!(:new).and_return(@chef_client)
    JSON.stub!(:parse).and_return({:a => 'b', :d => 'c'})
    @app = Chef::Application::Client.new
  end
  
  it "should instantiate a chef::client object" do
    Chef::Client.should_receive(:new).and_return(@chef_client)
    @app.setup_application
  end
  
  it "should assign the json attribs"
  
  it "should assign the validation token"
  
  it "should assign the node name"
end

describe Chef::Application::Client, "run_application" do
  before do
    @chef_client = mock("Chef::Client", :null_object => true)
    Chef::Client.stub!(:new).and_return(@chef_client)
    @app = Chef::Application::Client.new
  end
  
  describe "if we're daemonizing" do
    before do
      Chef::Config.stub!(:[]).with(:daemonize).and_return(true)
    end
    
    it "should change privileges"
    
    it "should daemonize the process"
  end
  
  describe "if we're not daemonizing" do
    before do
      Chef::Config.stub!(:[]).with(:daemonize).and_return(false)
    end
    
    it "should run the chef client"
  end
end