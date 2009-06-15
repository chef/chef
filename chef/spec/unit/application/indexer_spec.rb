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

describe Chef::Application::Indexer, "initialize" do
  before do
    @app = Chef::Application::Indexer.new
  end
  
  it "should create an instance of Chef::Application::Indexer" do
    @app.should be_kind_of(Chef::Application::Indexer)
  end
end

describe Chef::Application::Indexer, "setup_application" do
  before do
    Chef::Daemon.stub!(:change_privilege).and_return(true)
    @chef_searchindex = mock("Chef::SearchIndex", :null_object => true)
    Chef::SearchIndex.stub!(:new).and_return(@chef_searchindex)
    Chef::Queue.stub!(:connect).and_return(true)
    Chef::Queue.stub!(:subscribe).and_return(true)
    @app = Chef::Application::Indexer.new
  end
  
  it "should change privileges" do
    Chef::Daemon.should_receive(:change_privilege).and_return(true)
    @app.setup_application
  end
  
  it "should instantiate a chef::client object" do
    Chef::SearchIndex.should_receive(:new).and_return(@chef_searchindex)
    @app.setup_application
  end
  
  it "should connect to the queue" do
    Chef::Queue.should_receive(:connect).and_return(true)
    @app.setup_application
  end
  
  it "should subscribe to index" do
    Chef::Queue.should_receive(:subscribe).with(:queue, "index").and_return(true)
    @app.setup_application
  end
  
  it "should subscribe to remove" do
    Chef::Queue.should_receive(:subscribe).with(:queue, "remove").and_return(true)
    @app.setup_application
  end
end
