#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"

describe Chef::Knife::NodeList do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    Chef::Config[:environment] = nil # reset this value each time, as it is not reloaded
    @knife = Chef::Knife::NodeList.new
    allow(@knife).to receive(:output).and_return(true)
    @list = {
      "foo" => "http://example.com/foo",
      "bar" => "http://example.com/foo",
    }
    allow(Chef::Node).to receive(:list).and_return(@list)
    allow(Chef::Node).to receive(:list_by_environment).and_return(@list)
  end

  describe "run" do
    it "should list all of the nodes if -E is not specified" do
      expect(Chef::Node).to receive(:list).and_return(@list)
      @knife.run
    end

    it "should pretty print the list" do
      expect(Chef::Node).to receive(:list).and_return(@list)
      expect(@knife).to receive(:output).with(%w{bar foo})
      @knife.run
    end

    it "should list nodes in the specific environment if -E ENVIRONMENT is specified" do
      Chef::Config[:environment] = "prod"
      expect(Chef::Node).to receive(:list_by_environment).with("prod").and_return(@list)
      @knife.run
    end

    describe "with -w or --with-uri" do
      it "should pretty print the hash" do
        @knife.config[:with_uri] = true
        expect(Chef::Node).to receive(:list).and_return(@list)
        expect(@knife).to receive(:output).with(@list)
        @knife.run
      end
    end
  end
end
