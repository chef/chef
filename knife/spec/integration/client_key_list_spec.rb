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
require "date"

describe "knife client key list", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:now) { DateTime.now }
  let(:last_month) { (now << 1).strftime("%FT%TZ") }
  let(:next_month) { (now >> 1).strftime("%FT%TZ") }

  when_the_chef_server "has a client" do
    before do
      client "cons", {}
      knife("client key create cons -k new")
      knife("client key create cons -k next_month -e #{next_month}")
      knife("client key create cons -k expired -e #{last_month}")
    end

    it "lists the keys for a client" do
      knife("client key list cons").should_succeed "expired\nnew\nnext_month\n"
    end

    it "shows detailed output" do
      knife("client key list -w cons").should_succeed <<~EOM
        expired:    http://127.0.0.1:8900/clients/cons/keys/expired (expired)
        new:        http://127.0.0.1:8900/clients/cons/keys/new
        next_month: http://127.0.0.1:8900/clients/cons/keys/next_month
      EOM
    end

    it "lists the expired keys for a client" do
      knife("client key list -e cons").should_succeed "expired\n"
    end

    it "lists the unexpired keys for a client" do
      knife("client key list -n cons").should_succeed "new\nnext_month\n"
    end

  end
end
