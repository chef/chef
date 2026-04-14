#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2011-2016, Thomas Bishop
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

describe Chef::Knife::ClientShow do
  before(:each) do
    @knife = Chef::Knife::ClientShow.new
    @knife.name_args = [ "adam" ]
    @client_mock = double("client_mock")
  end

  describe "run" do
    it "should list the client" do
      expect(Chef::ApiClientV1).to receive(:load).with("adam").and_return(@client_mock)
      expect(@knife).to receive(:format_for_display).with(@client_mock)
      @knife.run
    end

    it "should pretty print json" do
      @knife.config[:format] = "json"
      @stdout = StringIO.new
      allow(@knife.ui).to receive(:stdout).and_return(@stdout)
      fake_client_contents = { "foo" => "bar", "baz" => "qux" }
      expect(Chef::ApiClientV1).to receive(:load).with("adam").and_return(fake_client_contents)
      @knife.run
      expect(@stdout.string).to eql("{\n  \"foo\": \"bar\",\n  \"baz\": \"qux\"\n}\n")
    end

    it "should print usage and exit when a client name is not provided" do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end
end
