#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "spec_helper"
require "json"
require "chef/data_collector/run_end_message"

describe Chef::DataCollector::RunEndMessage do
  let(:contract_fixture_path) { File.expand_path("../../data/contracts/run_end_message_contract.json", __dir__) }
  let(:start_time) { Time.utc(2026, 1, 1, 10, 0, 0) }
  let(:end_time) { Time.utc(2026, 1, 1, 10, 0, 5) }
  let(:run_id) { "contract-run-123" }
  let(:expanded_run_list) { { "recipes" => ["contract::default"], "roles" => [] } }
  let(:cookbooks) { { "contract_cookbook" => { "version" => "1.0.0" } } }
  let(:run_list) { instance_double("Chef::RunList", for_json: ["recipe[contract::default]"]) }
  let(:node) do
    node = instance_double("Chef::Node",
      data_for_save: { "name" => "contract-node" },
      name: "contract-node",
      run_list: run_list,
      policy_name: nil,
      policy_group: nil)
    allow(node).to receive(:[]).with("cookbooks").and_return(cookbooks)
    node
  end
  let(:run_status) do
    instance_double("Chef::RunStatus",
      run_id: run_id,
      start_time: start_time,
      end_time: end_time,
      exception: nil)
  end
  let(:reporter) do
    instance_double("Chef::DataCollector::Reporter",
      action_collection: nil,
      run_status: run_status,
      node: node,
      expanded_run_list: expanded_run_list,
      deprecations: [])
  end

  before do
    Chef::Config.reset
    Chef::Config[:chef_server_url] = "https://chef-api.example.test"
    Chef::Config[:chef_guid] = "contract-guid-123"
    Chef::Config[:solo_legacy_mode] = false
    Chef::Config[:local_mode] = false
    Chef::Config[:data_collector] = {} unless Chef::Config[:data_collector]
  end

  # Contract update instructions:
  # 1. Intentionally change run_end_message payload behavior.
  # 2. Run this spec and inspect the diff against spec/data/contracts/run_end_message_contract.json.
  # 3. Update the fixture only after review confirms the new boundary is intentional.
  it "matches the run_end_message contract fixture" do
    expected = JSON.parse(File.read(contract_fixture_path))

    actual = described_class.construct_message(reporter, "success")

    expect(actual).to eq(expected)
  end
end
