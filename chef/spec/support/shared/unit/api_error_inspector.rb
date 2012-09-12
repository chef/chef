#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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



# == API Error Inspector Examples
# These tests are work in progress. They exercise the code enough to ensure it
# runs without error, but don't make assertions about the output. This is
# because aspects such as how information gets formatted, what's included, etc.
# are still in flux. When testing an inspector, change the outputter to use
# STDOUT and manually check the ouput.

shared_examples_for "an api error inspector" do

  before do
    @node_name = "test-node.example.com"
    @config = {
      :validation_client_name => "testorg-validator",
      :validation_key => "/etc/chef/testorg-validator.pem",
      :chef_server_url => "https://chef-api.example.com",
      :node_name => "testnode-name",
      :client_key => "/etc/chef/client.pem"
    }
    @description = Chef::Formatters::ErrorDescription.new("Error registering the node:")
    @outputter = Chef::Formatters::Outputter.new(StringIO.new, STDERR)
    #@outputter = Chef::Formatters::Outputter.new(STDOUT, STDERR)

  end

  describe "when explaining a network error" do
    before do
      @exception = Errno::ECONNREFUSED.new("connection refused")
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining a 'private key missing' error" do
    before do
      @exception = Chef::Exceptions::PrivateKeyMissing.new("no private key yo")
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining a 401 caused by clock skew" do
    before do
      @response_body = "synchronize the clock on your host"
      @response = Net::HTTPUnauthorized.new("1.1", "401", "(response) unauthorized")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) unauthorized", @response)
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining a 401 (no clock skew)" do
    before do
      @response_body = "check your key and node name"
      @response = Net::HTTPUnauthorized.new("1.1", "401", "(response) unauthorized")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) unauthorized", @response)
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining a 403" do
    before do
      @response_body = "forbidden"
      @response = Net::HTTPForbidden.new("1.1", "403", "(response) forbidden")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) forbidden", @response)
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining a 400" do
    before do
      @response_body = "didn't like your data"
      @response = Net::HTTPBadRequest.new("1.1", "400", "(response) bad request")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) bad request", @response)
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining a 404" do
    before do
      @response_body = "probably caused by a redirect to a get"
      @response = Net::HTTPNotFound.new("1.1", "404", "(response) not found")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) not found", @response)
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end
  end

  describe "when explaining a 500" do
    before do
      @response_body = "sad trombone"
      @response = Net::HTTPInternalServerError.new("1.1", "500", "(response) internal server error")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPFatalError.new("(exception) internal server error", @response)
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end
  end

  describe "when explaining a 503" do
    before do
      @response_body = "sad trombone orchestra"
      @response = Net::HTTPBadGateway.new("1.1", "502", "(response) bad gateway")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPFatalError.new("(exception) bad gateway", @response)
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end
  end

  describe "when explaining an unknown error" do
    before do
      @exception = RuntimeError.new("(exception) something went wrong")
      @inspector = described_class.new(@node_name, @exception, @config)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end
  end

end
