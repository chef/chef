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
require "chef/api_client_v1"

describe Chef::Knife::ClientEdit do
  before(:each) do
    @knife = Chef::Knife::ClientEdit.new
    @knife.name_args = [ "adam" ]
    @knife.config[:disable_editing] = true
  end

  describe "run" do
    let(:data) do
      {
        "name" => "adam",
        "validator" => false,
        "admin" => false,
        "chef_type" => "client",
        "create_key" => true,
      }
    end

    it "should edit the client" do
      allow(Chef::ApiClientV1).to receive(:load).with("adam").and_return(data)
      expect(@knife).to receive(:edit_hash).with(data).and_return(data)
      @knife.run
    end

    it "should print usage and exit when a client name is not provided" do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end
end
