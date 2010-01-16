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

describe Chef::Application::Solo, "initialize" do
  before do
    @app = Chef::Application::Solo.new
  end
  
  it "should create an instance of Chef::Application::Solo" do
    @app.should be_kind_of(Chef::Application::Solo)
  end
end

describe Chef::Application::Solo, "reconfigure" do
  before do
    @app = Chef::Application::Solo.new
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config.stub!(:[]).with(:recipe_url).and_return(false)
    Chef::Config.stub!(:[]).with(:json_attribs).and_return(false)
    Chef::Config.stub!(:[]).with(:splay).and_return(nil)
    Chef::Config.stub!(:solo).and_return(true)
  end
  
  after do
    Chef::Config.solo false
  end

  it "should set solo mode to true" do
    Chef::Config.should_receive(:solo).once.with(true).and_return(true)
    @app.reconfigure
  end

  describe "when in daemonized mode" do
    before do
      Chef::Config.stub!(:[]).with(:daemonize).and_return(true)
    end

    describe "and no interval has been set" do
      before do
        Chef::Config.stub!(:[]).with(:interval).and_return(nil)
      end

      it "should set the interval to 1800" do
        Chef::Config.should_receive(:[]=).with(:interval, 1800).once.and_return(1800)
        @app.reconfigure
      end
    end
  end

  describe "when the json_attribs configuration option is specified" do

    describe "and the json_attribs matches a HTTP regex" do
      before do
        @json = mock("Tempfile", :read => {:a=>"b"}.to_json, :null_object => true)
        @rest = mock("Chef::REST", :get_rest => @json, :null_object => true)

        Chef::Config.stub!(:[]).with(:json_attribs).and_return("https://foo.com/foo.json")
        Chef::REST.stub!(:new).with("https://foo.com/foo.json", nil, nil).and_return(@rest)
        @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
      end

      it "should create a new Chef::REST" do
        Chef::REST.should_receive(:new).with("https://foo.com/foo.json", nil, nil).and_return(@rest)
        @app.reconfigure
      end

      it "should perform a RESTful GET on the supplied URL" do
        @rest.should_receive(:get_rest).with("https://foo.com/foo.json", true).and_return(@json)
        @app.reconfigure
      end
    end

    describe "and the json_attribs does not match the HTTP regex" do
      before do
        Chef::Config.stub!(:[]).with(:json_attribs).and_return("/etc/chef/dna.json")
        @json = mock("Tempfile", :read => {:a=>"b"}.to_json, :null_object => true)
        @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
      end

      it "should parse the json out of the file" do
        JSON.should_receive(:parse).with(@json.read)
        @app.reconfigure
      end
    end
    
    describe "when parsing fails" do
      before do
        Chef::Config.stub!(:[]).with(:json_attribs).and_return("/etc/chef/dna.json")
        @json = mock("Tempfile", :read => {:a=>"b"}.to_json, :null_object => true)
        @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
        JSON.stub!(:parse).with(@json.read).and_raise(JSON::ParserError)
        Chef::Application.stub!(:fatal!).and_return(true)
      end
      
      it "should hard fail the application" do
        Chef::Application.should_receive(:fatal!).with("Could not parse the provided JSON file (/etc/chef/dna.json)!: JSON::ParserError", 2).and_return(true)
        @app.reconfigure
      end
    end
  end


  
  describe "when the recipe_url configuration option is specified" do
    before do
      Chef::Config.stub!(:[]).with(:cookbook_path).and_return("/tmp/chef-solo/cookbooks")
      Chef::Config.stub!(:[]).with(:recipe_url).and_return("http://junglist.gen.nz/recipes.tgz")
      FileUtils.stub!(:mkdir_p).and_return(true)
      @tarfile = mock("Tempfile", :null_object => true, :read => "blah")
      @app.stub!(:open).with("http://junglist.gen.nz/recipes.tgz").and_yield(@tarfile)
      
      @target_file = mock("Tempfile", :null_object => true)
      File.stub!(:open).with("/tmp/chef-solo/recipes.tgz", "wb").and_yield(@target_file)
      
      Chef::Mixin::Command.stub!(:run_command).and_return(true)
    end
       
    it "should create the recipes path based on the parent of the cookbook path" do
      FileUtils.should_receive(:mkdir_p).with("/tmp/chef-solo").and_return(true)
      @app.reconfigure
    end
    
    it "should download the recipes" do
      @app.should_receive(:open).with("http://junglist.gen.nz/recipes.tgz").and_yield(@tarfile)
      @app.reconfigure
    end
    
    it "should write the recipes to the target path" do
      @target_file.should_receive(:write).with("blah").and_return(true)
      @app.reconfigure
    end
    
    it "should untar the target file to the parent of the cookbook path" do
      Chef::Mixin::Command.should_receive(:run_command).with({:command => "tar zxvfC /tmp/chef-solo/recipes.tgz /tmp/chef-solo"}).and_return(true)
      @app.reconfigure
    end
  end
end

describe Chef::Application::Solo, "setup_application" do
  before do
    Chef::Daemon.stub!(:change_privilege).and_return(true)    
    @chef_client = mock("Chef::Client", :null_object => true)
    Chef::Client.stub!(:new).and_return(@chef_client)
    @app = Chef::Application::Solo.new
    # this is all stuff the reconfigure method needs
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config.stub!(:[]).with(:interval).and_return(false)
    Chef::Config.stub!(:[]).with(:splay).and_return(false)
    Chef::Config.stub!(:[]).with(:recipe_url).and_return(false)
    Chef::Config.stub!(:[]).with(:json_attribs).and_return("/etc/chef/dna.json")
    @json = mock("Tempfile", :read => {:a=>"b"}.to_json, :null_object => true)
    @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
  end
 
  it "should change privileges" do
    Chef::Daemon.should_receive(:change_privilege).and_return(true)
    @app.setup_application
  end

  it "should instantiate a chef::client object" do
    Chef::Client.should_receive(:new).and_return(@chef_client)
    @app.setup_application
  end
  
  it "should assign the json attributes to the chef client instance" do
    @chef_client.should_receive(:json_attribs=).with({"a"=>"b"}).and_return(true)
    @app.reconfigure
    @app.setup_application
  end
  
  it "should assign the node name to the chef client instance" do
    Chef::Config.stub!(:[]).with(:node_name).and_return("testnode")
    @chef_client.should_receive(:node_name=).with("testnode").and_return(true)
    @app.setup_application
  end
  
  after do
    Chef::Config[:solo] = false
  end  
end
