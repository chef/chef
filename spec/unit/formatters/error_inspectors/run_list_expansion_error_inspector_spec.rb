#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

describe Chef::Formatters::ErrorInspectors::RunListExpansionErrorInspector do
  before do
    @node = Chef::Node.new.tap do |n|
      n.name("unit-test.example.com")
      n.run_list("role[base]")
    end

    @description = Chef::Formatters::ErrorDescription.new("Error Expanding RunList:")
    @outputter = Chef::Formatters::IndentableOutputStream.new(StringIO.new, STDERR)
    #@outputter = Chef::Formatters::IndentableOutputStream.new(STDOUT, STDERR)
  end

  describe "when explaining a missing role error" do

    before do
      @run_list_expansion = Chef::RunList::RunListExpansion.new("_default", @node.run_list)
      @run_list_expansion.missing_roles_with_including_role << [ "role[missing-role]", "role[base]" ]
      @run_list_expansion.missing_roles_with_including_role << [ "role[another-missing-role]", "role[base]" ]

      @exception = Chef::Exceptions::MissingRole.new(@run_list_expansion)

      @inspector = Chef::Formatters::ErrorInspectors::RunListExpansionErrorInspector.new(@node, @exception)
      @inspector.add_explanation(@description)
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining an HTTP 403 error" do
    before do

      @response_body = "forbidden"
      @response = Net::HTTPForbidden.new("1.1", "403", "(response) forbidden")
      allow(@response).to receive(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) forbidden", @response)
      @inspector = Chef::Formatters::ErrorInspectors::RunListExpansionErrorInspector.new(@node, @exception)
      allow(@inspector).to receive(:config).and_return(:node_name => "unit-test.example.com")

      @inspector.add_explanation(@description)
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining an HTTP 401 error" do
    before do
      @response_body = "check your key and node name"
      @response = Net::HTTPUnauthorized.new("1.1", "401", "(response) unauthorized")
      allow(@response).to receive(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) unauthorized", @response)

      @inspector = Chef::Formatters::ErrorInspectors::RunListExpansionErrorInspector.new(@node, @exception)
      allow(@inspector).to receive(:config).and_return(:node_name => "unit-test.example.com",
                                                       :client_key => "/etc/chef/client.pem",
                                                       :chef_server_url => "http://chef.example.com")

      @inspector.add_explanation(@description)
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end
  end

end
