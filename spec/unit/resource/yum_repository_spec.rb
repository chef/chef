#
# Author:: Thom May (<thom@chef.io>)
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

describe Chef::Resource::YumRepository do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::YumRepository.new("fakey_fakerton", run_context) }

  it "has a resource_name of :yum_repository" do
    expect(resource.resource_name).to eq(:yum_repository)
  end

  it "the repositoryid property is the name_property" do
    expect(resource.repositoryid).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :add, :create, :delete, :makecache, :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :makecache }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "fails if the user provides a repositoryid with a forward slash" do
    expect { resource.repositoryid "foo/bar" }.to raise_error(ArgumentError)
  end

  it "clean_headers property defaults to false" do
    expect(resource.clean_headers).to eql(false)
  end

  it "clean_metadata property defaults to true" do
    expect(resource.clean_metadata).to eql(true)
  end

  it "description property defaults to 'Yum Repository'" do
    expect(resource.description).to eql("Yum Repository")
  end

  it "enabled property defaults to true" do
    expect(resource.enabled).to eql(true)
  end

  it "make_cache property defaults to true" do
    expect(resource.make_cache).to eql(true)
  end

  it "makecache_fast property defaults to false" do
    expect(resource.makecache_fast).to eql(false)
  end

  it "mode property defaults to '0644'" do
    expect(resource.mode).to eql("0644")
  end

  it "the timeout property expects numeric Strings" do
    expect { resource.timeout "123" }.not_to raise_error
    expect { resource.timeout "123foo" }.to raise_error(ArgumentError)
  end

  it "the priority property expects numeric Strings from '1' to '99'" do
    expect { resource.priority "99" }.not_to raise_error
    expect { resource.priority "1" }.not_to raise_error
    expect { resource.priority "100" }.to raise_error(ArgumentError)
    expect { resource.priority "0" }.to raise_error(ArgumentError)
  end

  it "the failovermethod property accepts 'priority' or 'roundrobin'" do
    expect { resource.failovermethod "priority" }.not_to raise_error
    expect { resource.failovermethod "roundrobin" }.not_to raise_error
    expect { resource.failovermethod "bob" }.to raise_error(ArgumentError)
  end

  it "the http_caching property accepts 'packages', 'all', or 'none'" do
    expect { resource.http_caching "packages" }.not_to raise_error
    expect { resource.http_caching "all" }.not_to raise_error
    expect { resource.http_caching "none" }.not_to raise_error
    expect { resource.http_caching "bob" }.to raise_error(ArgumentError)
  end

  it "the metadata_expire property accepts a time value or 'never'" do
    expect { resource.metadata_expire "100" }.not_to raise_error
    expect { resource.metadata_expire "100d" }.not_to raise_error
    expect { resource.metadata_expire "100h" }.not_to raise_error
    expect { resource.metadata_expire "100m" }.not_to raise_error
    expect { resource.metadata_expire "never" }.not_to raise_error
    expect { resource.metadata_expire "100s" }.to raise_error(ArgumentError)
  end

  it "the mirror_expire property accepts a time value" do
    expect { resource.mirror_expire "100" }.not_to raise_error
    expect { resource.mirror_expire "100d" }.not_to raise_error
    expect { resource.mirror_expire "100h" }.not_to raise_error
    expect { resource.mirror_expire "100m" }.not_to raise_error
    expect { resource.mirror_expire "never" }.to raise_error(ArgumentError)
  end

  it "the mirrorlist_expire property accepts a time value" do
    expect { resource.mirrorlist_expire "100" }.not_to raise_error
    expect { resource.mirrorlist_expire "100d" }.not_to raise_error
    expect { resource.mirrorlist_expire "100h" }.not_to raise_error
    expect { resource.mirrorlist_expire "100m" }.not_to raise_error
    expect { resource.mirrorlist_expire "never" }.to raise_error(ArgumentError)
  end

  it "accepts the legacy 'url' property" do
    resource.url "foo"
    expect(resource.baseurl).to eql("foo")
  end

  it "accepts the legacy 'keyurl' property" do
    resource.keyurl "foo"
    expect(resource.gpgkey).to eql("foo")
  end

  context "on linux", :linux_only do
    it "resolves to a Noop class when yum is not found" do
      expect(Chef::Provider::YumRepository).to receive(:which).with("yum").and_return(false)
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
    end

    it "resolves to a YumRepository class when yum is found" do
      expect(Chef::Provider::YumRepository).to receive(:which).with("yum").and_return(true)
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::YumRepository)
    end
  end

  context "on windows", :windows_only do
    it "resolves to a NoOp provider" do
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
    end
  end
end
