#
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "support/shared/context/config"
require "openssl"

describe "knife node create", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:out) { "Created node[bah]\n" }

  when_the_chef_server "is empty" do
    it "creates a new node" do
      knife("node create bah").should_succeed out
    end

    it "creates a new validator node" do
      knife("node create bah").should_succeed out
      knife("node show bah").should_succeed(/Node Name:   bah/)
    end

    it "refuses to add an existing node" do
      pending "Knife node create must not blindly overwrite an existing node"
      knife("node create bah").should_succeed out
      expect { knife("node create bah") }.to raise_error(Net::HTTPClientException)
    end

  end
end
