#
# Author:: Adam Leff (<adamleff@chef.io)
#
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "json"
require "serverspec"

set :backend, :exec

class Chef
  class Node
    # dummy class for parsing JSON action messages
  end
end

shared_examples_for "reset counters" do
  it "resets the counters" do
    expect(command("curl http://localhost:9292/reset-counters").exit_status).to eq(0)
  end
end

shared_examples_for "reset cache" do
  it "resets the message cache" do
    expect(command("curl http://localhost:9292/reset-cache").exit_status).to eq(0)
  end
end

shared_examples_for "successful chef run" do |cmd|
  include_examples "reset counters"
  include_examples "reset cache"

  it "runs chef and expects a zero exit status" do
    expect(command(cmd).exit_status).to eq(0)
  end
end

shared_examples_for "unsuccessful chef run" do |cmd|
  include_examples "reset counters"
  include_examples "reset cache"

  it "runs chef and expects a non-zero exit status" do
    expect(command(cmd).exit_status).not_to eq(0)
  end
end

shared_examples_for "counter checks" do |counters_to_check|
  counters_to_check.each do |counter, value|
    it "counter #{counter} should equal #{value.inspect}" do
      counter_values = JSON.load(command("curl http://localhost:9292/counters").stdout)
      expect(counter_values[counter]).to eq(value)
    end
  end
end

shared_examples_for "run_start payload check" do
  describe "run_start message" do
    let(:required_fields) do
      %w{
        chef_server_fqdn
        entity_uuid
        id
        message_version
        message_type
        node_name
        organization_name
        run_id
        source
        start_time
      }
    end
    let(:optional_fields) { [] }

    it "is not missing any required fields" do
      payload = JSON.load(command("curl http://localhost:9292/cache/run_start").stdout)
      missing_fields = required_fields.select { |key| !payload.key?(key) }
      expect(missing_fields).to eq([])
    end

  end
end

shared_examples_for "run_converge.success payload check" do
  describe "run_converge success message" do
    let(:required_fields) do
      %w{
        chef_server_fqdn
        entity_uuid
        id
        end_time
        expanded_run_list
        message_type
        message_version
        node
        node_name
        organization_name
        policy_name
        policy_group
        resources
        run_id
        run_list
        source
        start_time
        status
        total_resource_count
        updated_resource_count
        deprecations
      }
    end
    let(:optional_fields) { [] }

    it "is not missing any required fields" do
      payload = JSON.load(command("curl http://localhost:9292/cache/run_converge.success").stdout)
      missing_fields = required_fields.select { |key| !payload.key?(key) }
      expect(missing_fields).to eq([])
    end

  end
end

shared_examples_for "run_converge.failure payload check" do
  describe "run_converge failure message" do
    let(:required_fields) do
      %w{
        chef_server_fqdn
        entity_uuid
        error
        id
        end_time
        expanded_run_list
        message_type
        message_version
        node
        node_name
        organization_name
        policy_name
        policy_group
        resources
        run_id
        run_list
        source
        start_time
        status
        total_resource_count
        updated_resource_count
        deprecations
      }
    end
    let(:optional_fields) { [] }

    it "is not missing any required fields" do
      payload = JSON.load(command("curl http://localhost:9292/cache/run_converge.failure").stdout)
      missing_fields = required_fields.select { |key| !payload.key?(key) }
      expect(missing_fields).to eq([])
    end

    it "does not have any extra fields" do
      payload = JSON.load(command("curl http://localhost:9292/cache/run_converge.failure").stdout)
      extra_fields = payload.keys.select { |key| !required_fields.include?(key) && !optional_fields.include?(key) }
      expect(extra_fields).to eq([])
    end
  end
end

describe "CCR with no data collector URL configured" do
  include_examples "successful chef run", "chef-client -z -c /etc/chef/no-endpoint.rb"
  include_examples "counter checks", { "run_start" => nil, "run_converge.success" => nil, "run_converge.failure" => nil }
end

describe "CCR, local mode, config in solo mode" do
  include_examples "successful chef run", "chef-client -z -c /etc/chef/solo-mode.rb"
  include_examples "counter checks", { "run_start" => 1, "run_converge.success" => 1, "run_converge.failure" => nil }
  include_examples "run_start payload check"
  include_examples "run_converge.success payload check"
end

describe "CCR, local mode, config in client mode" do
  include_examples "successful chef run", "chef-client -z -c /etc/chef/client-mode.rb"
  include_examples "counter checks", { "run_start" => nil, "run_converge.success" => nil, "run_converge.failure" => nil }
end

describe "CCR, local mode, config in both mode" do
  include_examples "successful chef run", "chef-client -z -c /etc/chef/both-mode.rb"
  include_examples "counter checks", { "run_start" => 1, "run_converge.success" => 1, "run_converge.failure" => nil }
  include_examples "run_start payload check"
  include_examples "run_converge.success payload check"
end

describe "CCR, local mode, config in solo mode, failed run" do
  include_examples "unsuccessful chef run", "chef-client -z -c /etc/chef/solo-mode.rb -r 'recipe[cookbook-that-does-not-exist::default]'"
  include_examples "counter checks", { "run_start" => 1, "run_converge.success" => nil, "run_converge.failure" => 1 }
  include_examples "run_start payload check"
  include_examples "run_converge.failure payload check"
end
