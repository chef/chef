#
# Author:: Tim Smith (<tsmith@chef.io>)
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

describe Chef::Resource::Alternatives do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::Alternatives.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:install) }

  let(:alternatives_display_exists) do
    double("shellout", stdout: <<-STDOUT)
    java - auto mode
    link best version is /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
    link currently points to /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
    link java is /usr/bin/java
    slave java.1.gz is /usr/share/man/man1/java.1.gz
/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java - priority 1081
    slave java.1.gz: /usr/lib/jvm/java-8-openjdk-amd64/jre/man/man1/java.1.gz
    STDOUT
  end

  let(:alternatives_display_does_not_exist) do
    double("shellout", stdout: "update-alternatives: error: no alternatives for fakey_fakerton")
  end

  it "the link_name property is the name_property" do
    expect(resource.link_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "coerces priority value to an Integer" do
    resource.priority("1")
    expect(resource.priority).to eql(1)
  end

  it "builds a default value for link based on link_name value" do
    expect(resource.link).to eql("/usr/bin/fakey_fakerton")
  end

  it "supports :install, :auto, :refresh, and :remove actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :auto }.not_to raise_error
    expect { resource.action :refresh }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#path_exists?" do
    it "returns true if the path exists according to alternatives --display" do
      allow(provider).to receive(:shell_out).with("alternatives", "--display", "fakey_fakerton").and_return(alternatives_display_exists)
      expect(provider.path_exists?).to eql(true)
    end

    it "returns false if alternatives --display does not find a path" do
      allow(provider).to receive(:shell_out).with("alternatives", "--display", "fakey_fakerton").and_return(alternatives_display_does_not_exist)
      expect(provider.path_exists?).to eql(false)
    end
  end

  describe "#current_path" do
    it "extracts the current path by running alternatives --display" do
      allow(provider).to receive(:shell_out).with("alternatives", "--display", "fakey_fakerton").and_return(alternatives_display_exists)
      expect(provider.current_path).to eql("/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java")
    end
  end

  describe "#path_priority" do
    it "extracts the path priority by running alternatives --display" do
      allow(provider).to receive(:shell_out).with("alternatives", "--display", "fakey_fakerton").and_return(alternatives_display_exists)
      expect(provider.path_priority).to eql(1081)
    end
  end

  describe "#alternatives_cmd" do
    it "returns alternatives on fedora" do
      node.automatic_attrs[:platform_family] = "fedora"
      expect(provider.alternatives_cmd).to eql("alternatives")
    end

    it "returns alternatives on amazon" do
      node.automatic_attrs[:platform_family] = "amazon"
      expect(provider.alternatives_cmd).to eql("alternatives")
    end

    it "returns alternatives on suse" do
      node.automatic_attrs[:platform_family] = "suse"
      expect(provider.alternatives_cmd).to eql("alternatives")
    end

    it "returns alternatives on redhat" do
      node.automatic_attrs[:platform_family] = "rhel"
      expect(provider.alternatives_cmd).to eql("alternatives")
    end

    it "returns update-alternatives on debian" do
      node.automatic_attrs[:platform_family] = "debian"
      expect(provider.alternatives_cmd).to eql("update-alternatives")
    end
  end
end
