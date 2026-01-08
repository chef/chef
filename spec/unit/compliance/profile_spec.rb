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

describe Chef::Compliance::Profile do
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:data) { { "copyright" => "DevSec Hardening Framework Team", "copyright_email" => "hello@dev-sec.io", "license" => "Apache-2.0", "maintainer" => "DevSec Hardening Framework Team", "name" => "ssh-baseline", "summary" => "Test-suite for best-practice SSH hardening", "supports" => [{ "os-family" => "unix" }], "title" => "DevSec SSH Baseline", "version" => "2.6.4" } }
  let(:path) { "/var/chef/cache/cookbooks/acme_compliance/compliance/profiles/thisdirectoryisnotthename/inspec.yml" }
  let(:cookbook_name) { "acme_compliance" }
  let(:profile) { Chef::Compliance::Profile.new(events, data, path, cookbook_name) }

  it "has a cookbook_name" do
    expect(profile.cookbook_name).to eql(cookbook_name)
  end

  it "has a path" do
    expect(profile.path).to eql(path)
  end

  it "has a name based on the yml" do
    expect(profile.name).to eql("ssh-baseline")
  end

  it "has a pathname based on the path" do
    expect(profile.pathname).to eql("thisdirectoryisnotthename")
  end

  it "is disabled" do
    expect(profile.enabled).to eql(false)
    expect(profile.enabled?).to eql(false)
  end

  it "has an event handler" do
    expect(profile.events).to eql(events)
  end

  it "can be enabled by enable!" do
    profile.enable!
    expect(profile.enabled).to eql(true)
    expect(profile.enabled?).to eql(true)
  end

  it "enabling sends an event" do
    expect(events).to receive(:compliance_profile_enabled).with(profile)
    profile.enable!
  end

  it "can be disabled by disable!" do
    profile.enable!
    profile.disable!
    expect(profile.enabled).to eql(false)
    expect(profile.enabled?).to eql(false)
  end

  it "has a #inspec_data method that renders the path" do
    expect(profile.inspec_data).to eql( { name: "ssh-baseline", path: "/var/chef/cache/cookbooks/acme_compliance/compliance/profiles/thisdirectoryisnotthename" } )
  end

  it "doesn't render the events in the inspect output" do
    expect(profile.inspect).not_to include("events")
  end

  it "inflates objects from YAML" do
    string = <<~EOH
name: ssh-baseline#{" "}
title: DevSec SSH Baseline#{" "}
maintainer: DevSec Hardening Framework Team#{" "}
copyright: DevSec Hardening Framework Team#{" "}
copyright_email: hello@dev-sec.io#{" "}
license: Apache-2.0#{" "}
summary: Test-suite for best-practice SSH hardening#{" "}
version: 2.6.4#{" "}
supports:#{"     "}
  - os-family: unix
    EOH
    newprofile = Chef::Compliance::Profile.from_yaml(events, string, path, cookbook_name)
    expect(newprofile.data).to eql(data)
  end

  it "inflates objects from files" do
    string = <<~EOH
name: ssh-baseline#{" "}
title: DevSec SSH Baseline#{" "}
maintainer: DevSec Hardening Framework Team#{" "}
copyright: DevSec Hardening Framework Team#{" "}
copyright_email: hello@dev-sec.io#{" "}
license: Apache-2.0#{" "}
summary: Test-suite for best-practice SSH hardening#{" "}
version: 2.6.4#{" "}
supports:#{"     "}
  - os-family: unix
    EOH
    tempfile = Tempfile.new("chef-compliance-test")
    tempfile.write string
    tempfile.close
    newprofile = Chef::Compliance::Profile.from_file(events, tempfile.path, cookbook_name)
    expect(newprofile.data).to eql(data)
  end

  it "inflates objects from hashes" do
    newprofile = Chef::Compliance::Profile.from_hash(events, data, path, cookbook_name)
    expect(newprofile.data).to eql(data)
  end
end
