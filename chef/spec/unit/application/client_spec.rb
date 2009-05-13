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
    Chef::Config.stub!(:[]).with(:json_attribs).and_return(false)
  end
  
  describe "with an splay value" do
    before do
      Chef::Config.stub!(:[]).with(:splay).and_return(60)
      Chef::Config.stub!(:[]).with(:interval).and_return(10)
    end
    
    it "should set the delay based on the interval and splay values" do
      Chef::Config.should_receive(:[]=).with(:delay, an_instance_of(Fixnum))
      @app.reconfigure
    end
  end
  
  describe "without an splay value" do
    before do
      Chef::Config.stub!(:[]).with(:splay).and_return(nil)
      Chef::Config.stub!(:[]).with(:interval).and_return(10)
    end
    
    it "should set the delay based on the interval" do
      Chef::Config.should_receive(:[]=).with(:delay, 10)
      @app.reconfigure
    end
  end

end

describe Chef::Application::Client, "reconfigure" do
  before do
    @app = Chef::Application::Client.new
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config.stub!(:[]).with(:interval).and_return(10)
    Chef::Config.stub!(:[]).with(:splay).and_return(nil)
  end

  describe "when the json_attribs configuration option is specified" do
    before do
      Chef::Config.stub!(:[]).with(:json_attribs).and_return("/etc/chef/dna.json")
      @json = mock("Tempfile", :read => {:a=>"b"}.to_json, :null_object => true)
      @app.stub!(:open).and_yield(@json)
    end
    
    it "should parse the json out of the file" do
      JSON.should_receive(:parse).with(@json.read)
      @app.reconfigure
    end
  end
end

describe Chef::Application::Client, "setup_application" do
  before do
    @chef_client = mock("Chef::Client", :null_object => true)
    Chef::Client.stub!(:new).and_return(@chef_client)
    @app = Chef::Application::Client.new
  end
  
  it "should instantiate a chef::client object" do
    Chef::Client.should_receive(:new).and_return(@chef_client)
    @app.setup_application
  end
end