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

describe Chef::Formatters::ErrorInspectors::CookbookSyncErrorInspector do
  before do
    @description = Chef::Formatters::ErrorDescription.new("Error Expanding RunList:")
    @outputter = Chef::Formatters::Outputter.new(StringIO.new, STDERR)
    #@outputter = Chef::Formatters::Outputter.new(STDOUT, STDERR)
  end

  describe "when explaining a 502 error" do
    before do
      @response_body = "sad trombone orchestra"
      @response = Net::HTTPBadGateway.new("1.1", "502", "(response) bad gateway")
      @response.stub!(:body).and_return(@response_body)
      @exception = Net::HTTPFatalError.new("(exception) bad gateway", @response)
      @inspector = described_class.new({}, @exception)
      @inspector.add_explanation(@description)
    end

    it "prints a nice message" do
      @description.display(@outputter)
    end

  end
end
