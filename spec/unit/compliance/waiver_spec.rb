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
require "tempfile"

describe Chef::Compliance::Waiver do
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:data) { { "ssh-01" => { "expiration_date" => Date.jd(2463810), "justification" => "waived, yo", "run" => false } } }
  let(:path) { "/var/chef/cache/cookbooks/acme_compliance/compliance/waivers/default.yml" }
  let(:cookbook_name) { "acme_compliance" }
  let(:waiver) { Chef::Compliance::Waiver.new(events, data, path, cookbook_name) }

  it "has a cookbook_name" do
    expect(waiver.cookbook_name).to eql(cookbook_name)
  end

  it "has a path" do
    expect(waiver.path).to eql(path)
  end

  it "has a pathname based on the path" do
    expect(waiver.pathname).to eql("default")
  end

  it "is disabled" do
    expect(waiver.enabled).to eql(false)
    expect(waiver.enabled?).to eql(false)
  end

  it "has an event handler" do
    expect(waiver.events).to eql(events)
  end

  it "can be enabled by enable!" do
    waiver.enable!
    expect(waiver.enabled).to eql(true)
    expect(waiver.enabled?).to eql(true)
  end

  it "enabling sends an event" do
    expect(events).to receive(:compliance_waiver_enabled).with(waiver)
    waiver.enable!
  end

  it "can be disabled by disable!" do
    waiver.enable!
    waiver.disable!
    expect(waiver.enabled).to eql(false)
    expect(waiver.enabled?).to eql(false)
  end

  it "has a #inspec_data method that renders the data" do
    expect(waiver.inspec_data).to eql(data)
  end

  it "doesn't render the events in the inspect output" do
    expect(waiver.inspect).not_to include("events")
  end

  it "inflates objects from YAML" do
    string = <<~EOH
ssh-01:
  expiration_date: 2033-07-31
  run: false
  justification: "waived, yo"
    EOH
    newwaiver = Chef::Compliance::Waiver.from_yaml(events, string, path, cookbook_name)
    expect(newwaiver.data).to eql(data)
  end

  it "inflates objects from files" do
    string = <<~EOH
ssh-01:
  expiration_date: 2033-07-31
  run: false
  justification: "waived, yo"
    EOH
    tempfile = Tempfile.new("chef-compliance-test")
    tempfile.write string
    tempfile.close
    newwaiver = Chef::Compliance::Waiver.from_file(events, tempfile.path, cookbook_name)
    expect(newwaiver.data).to eql(data)
  end

  it "inflates objects from hashes" do
    newwaiver = Chef::Compliance::Waiver.from_hash(events, data, path, cookbook_name)
    expect(newwaiver.data).to eql(data)
  end
end
