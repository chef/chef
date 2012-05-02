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

require 'spec_helper'

describe Chef::Provider::HttpRequest do
  before(:each) do
    @node = Chef::Node.new
    @console_ui = Chef::ConsoleUI.new
    @run_context = Chef::RunContext.new(@node, {}, @console_ui)

    @new_resource = Chef::Resource::HttpRequest.new('adam')
    @new_resource.name "adam"
    @new_resource.url "http://www.opscode.com"
    @new_resource.message "is cool"

    @provider = Chef::Provider::HttpRequest.new(@new_resource, @run_context)
  end

  describe "load_current_resource" do  

    it "should set up a Chef::REST client, with no authentication" do
      Chef::REST.should_receive(:new).with(@new_resource.url, nil, nil)
      @provider.load_current_resource
    end
  end

  describe "when making REST calls" do
    before(:each) do
      # run_action(x) forces load_current_resource to run;
      # that would overwrite our supplied mock Chef::Rest # object
      @provider.stub!(:load_current_resource).and_return(true)
      @rest = mock("Chef::REST", :create_url => "http://www.opscode.com", :run_request => "you made it!" )
      @provider.rest = @rest
    end

    describe "action_get" do  
      it "should create the url with a message argument" do
        @rest.should_receive(:create_url).with("#{@new_resource.url}?message=#{@new_resource.message}")
        @provider.run_action(:get)
      end

      it "should inflate a message block at runtime" do
        @new_resource.stub!(:message).and_return(lambda { "return" })
        @rest.should_receive(:create_url).with("#{@new_resource.url}?message=return")
        @provider.run_action(:get)
      end

      it "should run a GET request" do
        @rest.should_receive(:run_request).with(:GET, @rest.create_url, {}, false, 10, false)
        @provider.run_action(:get)
      end

      it "should update the resource" do
        @provider.run_action(:get)
        @new_resource.should be_updated
      end
    end

    describe "action_put" do  
      it "should create the url" do
        @rest.should_receive(:create_url).with("#{@new_resource.url}")
        @provider.run_action(:put)
      end

      it "should run a PUT request with the message as the payload" do
        @rest.should_receive(:run_request).with(:PUT, @rest.create_url, {}, @new_resource.message, 10, false)
        @provider.run_action(:put)
      end

      it "should inflate a message block at runtime" do
        @new_resource.stub!(:message).and_return(lambda { "return" })
        @rest.should_receive(:run_request).with(:PUT, @rest.create_url, {}, "return", 10, false)    
        @provider.run_action(:put)
      end

      it "should update the resource" do
        @provider.run_action(:put)
        @new_resource.should be_updated
      end
    end

    describe "action_post" do  
      it "should create the url" do
        @rest.should_receive(:create_url).with("#{@new_resource.url}")
        @provider.run_action(:post)
      end
  
      it "should run a PUT request with the message as the payload" do
        @rest.should_receive(:run_request).with(:POST, @rest.create_url, {}, @new_resource.message, 10, false)
        @provider.run_action(:post)
      end
  
      it "should inflate a message block at runtime" do
        @new_resource.stub!(:message).and_return(lambda { "return" })
        @rest.should_receive(:run_request).with(:POST, @rest.create_url, {}, "return", 10, false)    
        @provider.run_action(:post)
      end
  
      it "should update the resource" do
        @provider.run_action(:post)
        @new_resource.should be_updated
      end
    end

    describe "action_delete" do  
      it "should create the url" do
        @rest.should_receive(:create_url).with("#{@new_resource.url}")
        @provider.run_action(:delete)
      end

      it "should run a DELETE request" do
        @rest.should_receive(:run_request).with(:DELETE, @rest.create_url, {}, false, 10, false)
        @provider.run_action(:delete)
      end

      it "should update the resource" do
        @provider.run_action(:delete)
        @new_resource.should be_updated
      end
    end

    describe "action_head" do
      before do
        @rest = mock("Chef::REST", :create_url => "http://www.opscode.com", :run_request => true)
        @provider.rest = @rest
      end

      it "should create the url with a message argument" do
        @rest.should_receive(:create_url).with("#{@new_resource.url}?message=#{@new_resource.message}")
        @provider.run_action(:head)
      end

      it "should inflate a message block at runtime" do
        @new_resource.stub!(:message).and_return(lambda { "return" })
        @rest.should_receive(:create_url).with("#{@new_resource.url}?message=return")
        @provider.run_action(:head)
      end

      it "should run a HEAD request" do
        @rest.should_receive(:run_request).with(:HEAD, @rest.create_url, {}, false, 10, false)
        @provider.run_action(:head)
      end

      it "should update the resource" do
        @provider.run_action(:head)
        @new_resource.should be_updated
      end

      it "should run a HEAD request with If-Modified-Since header" do
        @new_resource.headers "If-Modified-Since" => File.mtime(__FILE__).httpdate
        @rest.should_receive(:run_request).with(:HEAD, @rest.create_url, @new_resource.headers, false, 10, false)
        @provider.run_action(:head)
      end
    end
  end
end
