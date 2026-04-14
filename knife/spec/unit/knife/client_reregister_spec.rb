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

describe Chef::Knife::ClientReregister do
  before(:each) do
    @knife = Chef::Knife::ClientReregister.new
    @knife.name_args = [ "adam" ]
    @client_mock = double("client_mock", private_key: "foo_key")
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
  end

  context "when no client name is given on the command line" do
    before do
      @knife.name_args = []
    end

    it "should print usage and exit when a client name is not provided" do
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end

  context "when not configured for file output" do
    it "reregisters the client and prints the key" do
      expect(Chef::ApiClientV1).to receive(:reregister).with("adam").and_return(@client_mock)
      @knife.run
      expect(@stdout.string).to match( /foo_key/ )
    end
  end

  context "when configured for file output" do
    it "should write the private key to a file" do
      expect(Chef::ApiClientV1).to receive(:reregister).with("adam").and_return(@client_mock)

      @knife.config[:file] = "/tmp/monkeypants"
      filehandle = StringIO.new
      expect(File).to receive(:open).with("/tmp/monkeypants", "w").and_yield(filehandle)
      @knife.run
      expect(filehandle.string).to eq("foo_key")
    end
  end

end
