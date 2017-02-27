#
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "support/shared/integration/integration_helper"
require "support/shared/context/config"
require "chef/knife/data_bag_create"

describe "knife data bag create", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:err) { "Created data_bag[foo]\n" }
  let(:out) { "Created data_bag_item[bar]\n" }
  let(:exists) { "Data bag foo already exists\n" }

  when_the_chef_server "is empty" do
    it "creates a new data bag" do
      knife("data bag create foo").should_succeed stderr: err
    end

    it "creates a new data bag and item" do
      knife("data bag create foo bar").should_succeed stdout: out, stderr: err
    end

    it "adds a new item to an existing bag" do
      knife("data bag create foo").should_succeed stderr: err
      knife("data bag create foo bar").should_succeed stdout: out, stderr: exists
    end

    it "refuses to add an existing data bag" do
      knife("data bag create foo").should_succeed stderr: err
      knife("data bag create foo").should_succeed stderr: exists
    end

    it "fails to add an existing item" do
      knife("data bag create foo bar").should_succeed stdout: out, stderr: err
      expect { knife("data bag create foo bar") }.to raise_error(Net::HTTPServerException)
    end
  end
end
