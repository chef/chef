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
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::HttpRequest.new('adam')
    @new_resource.name "adam"
    @new_resource.url "http://www.opscode.com/"
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
      @rest = mock("Chef::REST")
      @provider.rest = @rest
    end

    describe "action_get" do

      it "should inflate a message block at runtime" do
        @new_resource.message { "return" }
        @rest.should_receive(:get).with("http://www.opscode.com/?message=return", false, {})
        @provider.run_action(:get)
        @new_resource.should be_updated
      end

      it "should run a GET request" do
        @rest.should_receive(:get).with("http://www.opscode.com/?message=is cool", false, {})
        @provider.run_action(:get)
        @new_resource.should be_updated
      end
    end

    describe "action_put" do
      it "should run a PUT request with the message as the payload" do
        @rest.should_receive(:put).with("http://www.opscode.com/", @new_resource.message, {})
        @provider.run_action(:put)
        @new_resource.should be_updated
      end

      it "should inflate a message block at runtime" do
        @new_resource.stub!(:message).and_return(lambda { "return" })
        @rest.should_receive(:put).with("http://www.opscode.com/", "return", {})
        @provider.run_action(:put)
        @new_resource.should be_updated
      end
    end

    describe "action_post" do
      it "should run a PUT request with the message as the payload" do
        @rest.should_receive(:post).with("http://www.opscode.com/", @new_resource.message, {})
        @provider.run_action(:post)
        @new_resource.should be_updated
      end

      it "should inflate a message block at runtime" do
        @new_resource.message { "return" }
        @rest.should_receive(:post).with("http://www.opscode.com/", "return", {})
        @provider.run_action(:post)
        @new_resource.should be_updated
      end
    end

    describe "action_delete" do
      it "should run a DELETE request" do
        @rest.should_receive(:delete).with("http://www.opscode.com/", {})
        @provider.run_action(:delete)
        @new_resource.should be_updated
      end
    end

    describe "action_head" do
      before do
        @provider.rest = @rest
      end

      it "should inflate a message block at runtime" do
        @new_resource.message { "return" }
        @rest.should_receive(:head).with("http://www.opscode.com/?message=return", {}).and_return("")
        @provider.run_action(:head)
        @new_resource.should be_updated
      end

      it "should run a HEAD request" do
        @rest.should_receive(:head).with("http://www.opscode.com/?message=is cool", {}).and_return("")
        @provider.run_action(:head)
        @new_resource.should be_updated
      end

      it "should run a HEAD request with If-Modified-Since header" do
        @new_resource.headers "If-Modified-Since" => File.mtime(__FILE__).httpdate
        @rest.should_receive(:head).with("http://www.opscode.com/?message=is cool", @new_resource.headers)
        @provider.run_action(:head)
      end

      it "doesn't call converge_by if HEAD does not return modified" do
        @rest.should_receive(:head).and_return(false)
        @provider.should_not_receive(:converge_by)
        @provider.run_action(:head)
      end
    end
  end
end
