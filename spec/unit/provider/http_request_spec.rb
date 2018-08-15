#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "spec_helper"

describe Chef::Provider::HttpRequest do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::HttpRequest.new("adam")
    @new_resource.name "adam"
    @new_resource.url "http://www.opscode.com/"
    @new_resource.message "is cool"

    @provider = Chef::Provider::HttpRequest.new(@new_resource, @run_context)
  end

  describe "load_current_resource" do

    it "should set up a Chef::ServerAPI client, with no authentication" do
      expect(Chef::HTTP::Simple).to receive(:new).with(@new_resource.url)
      @provider.load_current_resource
    end
  end

  describe "when making REST calls" do
    before(:each) do
      # run_action(x) forces load_current_resource to run;
      # that would overwrite our supplied mock Chef::Rest # object
      allow(@provider).to receive(:load_current_resource).and_return(true)
      @http = double("Chef::ServerAPI")
      @provider.http = @http
    end

    describe "action_get" do

      it "should inflate a message block at runtime" do
        @new_resource.message { "return" }
        expect(@http).to receive(:get).with("http://www.opscode.com/", {})
        @provider.run_action(:get)
        expect(@new_resource).to be_updated
      end

      it "should run a GET request" do
        expect(@http).to receive(:get).with("http://www.opscode.com/", {})
        @provider.run_action(:get)
        expect(@new_resource).to be_updated
      end
    end

    describe "action_put" do
      it "should run a PUT request with the message as the payload" do
        expect(@http).to receive(:put).with("http://www.opscode.com/", @new_resource.message, {})
        @provider.run_action(:put)
        expect(@new_resource).to be_updated
      end

      it "should inflate a message block at runtime" do
        @new_resource.message(lambda { "return" })
        expect(@http).to receive(:put).with("http://www.opscode.com/", "return", {})
        @provider.run_action(:put)
        expect(@new_resource).to be_updated
      end
    end

    describe "action_post" do
      it "should run a PUT request with the message as the payload" do
        expect(@http).to receive(:post).with("http://www.opscode.com/", @new_resource.message, {})
        @provider.run_action(:post)
        expect(@new_resource).to be_updated
      end

      it "should inflate a message block at runtime" do
        @new_resource.message { "return" }
        expect(@http).to receive(:post).with("http://www.opscode.com/", "return", {})
        @provider.run_action(:post)
        expect(@new_resource).to be_updated
      end
    end

    describe "action_delete" do
      it "should run a DELETE request" do
        expect(@http).to receive(:delete).with("http://www.opscode.com/", {})
        @provider.run_action(:delete)
        expect(@new_resource).to be_updated
      end
    end

    # CHEF-4762: we expect a nil return value for a "200 Success" response
    # and false for a "304 Not Modified" response
    describe "action_head" do
      before do
        @provider.http = @http
      end

      it "should inflate a message block at runtime" do
        @new_resource.message { "return" }
        expect(@http).to receive(:head).with("http://www.opscode.com/", {}).and_return(nil)
        @provider.run_action(:head)
        expect(@new_resource).to be_updated
      end

      it "should run a HEAD request" do
        expect(@http).to receive(:head).with("http://www.opscode.com/", {}).and_return(nil)
        @provider.run_action(:head)
        expect(@new_resource).to be_updated
      end

      it "should update a HEAD request with empty string response body (CHEF-4762)" do
        expect(@http).to receive(:head).with("http://www.opscode.com/", {}).and_return("")
        @provider.run_action(:head)
        expect(@new_resource).to be_updated
      end

      it "should update a HEAD request with nil response body (CHEF-4762)" do
        expect(@http).to receive(:head).with("http://www.opscode.com/", {}).and_return(nil)
        @provider.run_action(:head)
        expect(@new_resource).to be_updated
      end

      it "should not update a HEAD request if a not modified response (CHEF-4762)" do
        if_modified_since = File.mtime(__FILE__).httpdate
        @new_resource.headers "If-Modified-Since" => if_modified_since
        expect(@http).to receive(:head).with("http://www.opscode.com/", { "If-Modified-Since" => if_modified_since }).and_return(false)
        @provider.run_action(:head)
        expect(@new_resource).not_to be_updated
      end

      it "should run a HEAD request with If-Modified-Since header" do
        @new_resource.headers "If-Modified-Since" => File.mtime(__FILE__).httpdate
        expect(@http).to receive(:head).with("http://www.opscode.com/", @new_resource.headers)
        @provider.run_action(:head)
      end

      it "doesn't call converge_by if HEAD does not return modified" do
        expect(@http).to receive(:head).and_return(false)
        expect(@provider).not_to receive(:converge_by)
        @provider.run_action(:head)
      end
    end
  end
end
