#--
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

require 'spec_helper'

describe Chef::Formatters::ErrorInspectors::CookbookResolveErrorInspector do

  before do
    @expanded_run_list = Chef::RunList.new("recipe[annoyances]", "recipe[apache2]", "recipe[users]", "recipe[chef::client]")

    @description = Chef::Formatters::ErrorDescription.new("Error Resolving Cookbooks for Run List:")
    @outputter = Chef::Formatters::Outputter.new(StringIO.new, STDERR)
    #@outputter = Chef::Formatters::Outputter.new(STDOUT, STDERR)
  end

  describe "when explaining a 403 error" do
    before do

      @response_body = %Q({"error": [{"message": "gtfo"}])
      @response = Net::HTTPForbidden.new("1.1", "403", "(response) forbidden")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) forbidden", @response)

      @inspector = Chef::Formatters::ErrorInspectors::CookbookResolveErrorInspector.new(@expanded_run_list, @exception)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      lambda { @description.display(@outputter) }.should_not raise_error
    end

  end

  describe "when explaining a PreconditionFailed (412) error with current error message style" do
    # Chef currently returns error messages with some fields as JSON strings,
    # which must be re-parsed to get the actual data.

    before do

      @response_body = "{\"error\":[\"{\\\"non_existent_cookbooks\\\":[\\\"apache2\\\"],\\\"cookbooks_with_no_versions\\\":[\\\"users\\\"],\\\"message\\\":\\\"Run list contains invalid items: no such cookbook nope.\\\"}\"]}"
      @response = Net::HTTPPreconditionFailed.new("1.1", "412", "(response) unauthorized")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) precondition failed", @response)

      @inspector = Chef::Formatters::ErrorInspectors::CookbookResolveErrorInspector.new(@expanded_run_list, @exception)
      @inspector.add_explanation(@description)
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end

  end

  describe "when explaining a PreconditionFailed (412) error with single encoded JSON" do
    # Chef currently returns error messages with some fields as JSON strings,
    # which must be re-parsed to get the actual data.

    before do

      @response_body = "{\"error\":[{\"non_existent_cookbooks\":[\"apache2\"],\"cookbooks_with_no_versions\":[\"users\"],\"message\":\"Run list contains invalid items: no such cookbook nope.\"}]}"
      @response = Net::HTTPPreconditionFailed.new("1.1", "412", "(response) unauthorized")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPServerException.new("(exception) precondition failed", @response)

      @inspector = Chef::Formatters::ErrorInspectors::CookbookResolveErrorInspector.new(@expanded_run_list, @exception)
      @inspector.add_explanation(@description)
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end

  end
end



