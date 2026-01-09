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
#

require "spec_helper"

describe Chef::Resource::InspecWaiver do
  def load_waiver(filename)
    path = "/var/chef/cache/cookbooks/acme_compliance/compliance/waivers/#{filename}"
    run_context.waiver_collection << Chef::Compliance::Waiver.from_yaml(events, waiver_yaml, path, "acme_compliance")
  end

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) do
    Chef::RunContext.new(node, {}, events).tap do |rc|
    end
  end
  let(:collection) { double("resource collection") }
  let(:waiver_yaml) do
    <<~EOH
ssh-01:
  expiration_date: 2033-07-31
  run: false
  justification: "waived, yo"
    EOH
  end
  let(:waiver_json) do
    <<~EOH
{ "ssh-01": {
  "expiration_date": "2033-07-31",
  "run": false,
  "justification": "waived, yo"
  } }
    EOH
  end
  let(:waiver_toml) do
    <<~EOH
[ssh-01]
expiration_date = 2033-07-31T00:00:00.000Z
run = false
justification = "waived, yo"
    EOH
  end
  let(:waiver_hash) do
    { "ssh-01" => {
      "expiration_date" => "2033-07-31",
      "run" => false,
      "justification" => "waived, yo",
      } }
  end
  let(:resource) do
    Chef::Resource::InspecWaiver.new("ssh-01", run_context)
  end
  let(:provider) { resource.provider_for_action(:add) }

  before do
    allow(run_context).to receive(:resource_collection).and_return(collection)
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  context "with a waiver in a cookbook" do
    it "enables the waiver by the name of the cookbook" do
      load_waiver("default.yml")
      resource.name "acme_compliance"
      resource.run_action(:add)
      expect(run_context.waiver_collection.first).to be_enabled
      expect(resource).not_to be_updated_by_last_action
    end

    it "enables the waiver with a regular expression for the cookbook" do
      load_waiver("default.yml")
      resource.name "acme_comp.*"
      resource.run_action(:add)
      expect(run_context.waiver_collection.first).to be_enabled
      expect(resource).not_to be_updated_by_last_action
    end

    it "enables the waiver with an explicit name" do
      load_waiver("default.yml")
      resource.name "acme_compliance::default"
      resource.run_action(:add)
      expect(run_context.waiver_collection.first).to be_enabled
      expect(resource).not_to be_updated_by_last_action
    end

    it "fails when the cookbook name is wrong" do
      load_waiver("default.yml")
      resource.name "evil_compliance"
      expect { resource.run_action(:add) }.to raise_error(StandardError)
    end

    it "enables the waiver when its not named default" do
      load_waiver("ssh01.yml")
      resource.name "acme_compliance::ssh01"
      resource.run_action(:add)
      expect(run_context.waiver_collection.first).to be_enabled
      expect(resource).not_to be_updated_by_last_action
    end

    it "fails when it is not named default and you attempt to enable the default" do
      load_waiver("ssh01.yml")
      resource.name "acme_compliance"
      expect { resource.run_action(:add) }.to raise_error(StandardError)
    end

    it "succeeds with a regexp that matches the cookbook name" do
      load_waiver("ssh01.yml")
      resource.name "acme_comp.*::ssh01"
      resource.run_action(:add)
      expect(run_context.waiver_collection.first).to be_enabled
      expect(resource).not_to be_updated_by_last_action
    end

    it "succeeds with a regexp that matches the file name" do
      load_waiver("ssh01.yml")
      resource.name "acme_compliance::ssh.*"
      resource.run_action(:add)
      expect(run_context.waiver_collection.first).to be_enabled
      expect(resource).not_to be_updated_by_last_action
    end

    it "succeeds with a regexps for both the file name and cookbook name" do
      load_waiver("ssh01.yml")
      resource.name "acme_comp.*::ssh.*"
      resource.run_action(:add)
      expect(run_context.waiver_collection.first).to be_enabled
      expect(resource).not_to be_updated_by_last_action
    end

    it "fails with regexps that do not match" do
      load_waiver("ssh01.yml")
      resource.name "evil_comp.*::etcd.*"
      expect { resource.run_action(:add) }.to raise_error(StandardError)
    end

    it "substring matches without regexps should fail when they are at the end" do
      load_waiver("ssh01.yml")
      resource.name "acme_complianc::ssh0"
      expect { resource.run_action(:add) }.to raise_error(StandardError)
    end

    it "substring matches without regexps should fail when they are at the start" do
      load_waiver("ssh01.yml")
      resource.name "cme_compliance::sh01"
      expect { resource.run_action(:add) }.to raise_error(StandardError)
    end
  end

  context "with a waiver in a file" do
    it "loads a YAML file" do
      tempfile = Tempfile.new(["spec-compliance-test", ".yaml"])
      tempfile.write waiver_yaml
      tempfile.close
      resource.name tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a YAML file in a source attribute" do
      tempfile = Tempfile.new(["spec-compliance-test", ".yaml"])
      tempfile.write waiver_yaml
      tempfile.close
      resource.name "my-resource-name"
      resource.source tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a YML file" do
      tempfile = Tempfile.new(["spec-compliance-test", ".yml"])
      tempfile.write waiver_yaml
      tempfile.close
      resource.name tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a YML file using the source attribute" do
      tempfile = Tempfile.new(["spec-compliance-test", ".yml"])
      tempfile.write waiver_yaml
      tempfile.close
      resource.name "my-resource-name"
      resource.source tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a JSON file" do
      tempfile = Tempfile.new(["spec-compliance-test", ".json"])
      tempfile.write waiver_json
      tempfile.close
      resource.name tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a JSON file using the source attribute" do
      tempfile = Tempfile.new(["spec-compliance-test", ".json"])
      tempfile.write waiver_json
      tempfile.close
      resource.name "my-resource-name"
      resource.source tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a TOML file" do
      tempfile = Tempfile.new(["spec-compliance-test", ".toml"])
      tempfile.write waiver_toml
      tempfile.close
      resource.name tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a TOML file using the source attribute" do
      tempfile = Tempfile.new(["spec-compliance-test", ".toml"])
      tempfile.write waiver_toml
      tempfile.close
      resource.name "my-resource-name"
      resource.source tempfile.path

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end

    it "loads a Hash" do
      resource.source waiver_hash

      resource.run_action(:add)

      expect(run_context.waiver_collection.first).to be_enabled
      expect(run_context.waiver_collection.size).to be 1
      expect(run_context.waiver_collection.first.cookbook_name).to be nil
      expect(run_context.waiver_collection.first.path).to be nil
      expect(run_context.waiver_collection.first.pathname).to be nil
      expect(resource).not_to be_updated_by_last_action
    end
  end
end
