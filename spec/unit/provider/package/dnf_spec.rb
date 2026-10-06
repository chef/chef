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
#

require "spec_helper"

describe Chef::Provider::Package::Dnf do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::DnfPackage.new("tacos") }

  # Stand in for the dnf python helper, which is not available off-platform.
  let(:version) { double("version", to_s: "tacos-1.0-1.fc99.x86_64", version_with_arch: "1.0-1.fc99.x86_64") }

  let(:provider) do
    provider = Chef::Provider::Package::Dnf.new(new_resource, run_context)
    allow(provider).to receive(:dnf)
    allow(provider).to receive(:available_version).and_return(version)
    allow(provider).to receive(:magical_version).and_return(version)
    provider
  end

  describe "the flush_cache property" do
    it "defaults to flushing after so that the historical behavior is preserved" do
      expect(new_resource.flush_cache).to eq({ before: false, after: true })
    end

    it "can be turned off entirely" do
      new_resource.flush_cache false
      expect(new_resource.flush_cache).to eq({ before: false, after: false })
    end

    it "accepts an array naming which sides to flush" do
      new_resource.flush_cache [ :before ]
      expect(new_resource.flush_cache[:before]).to be true
      expect(new_resource.flush_cache[:after]).to be_falsey
    end
  end

  describe "#install_package" do
    it "flushes the cache afterwards by default" do
      expect(provider).to receive(:flushcache)
      provider.install_package(%w{tacos}, %w{1.0})
    end

    it "does not flush the cache afterwards when flush_cache[:after] is false" do
      new_resource.flush_cache after: false
      expect(provider).not_to receive(:flushcache)
      provider.install_package(%w{tacos}, %w{1.0})
    end
  end

  describe "#remove_package" do
    it "flushes the cache afterwards by default" do
      expect(provider).to receive(:flushcache)
      provider.remove_package(%w{tacos}, %w{1.0})
    end

    it "does not flush the cache afterwards when flush_cache[:after] is false" do
      new_resource.flush_cache after: false
      expect(provider).not_to receive(:flushcache)
      provider.remove_package(%w{tacos}, %w{1.0})
    end
  end

  describe "#load_current_resource" do
    before do
      allow(provider).to receive(:get_current_versions).and_return(%w{1.0})
      allow(provider).to receive(:get_candidate_versions).and_return(%w{1.0})
      allow(provider).to receive(:magic_version_array).and_return(%w{1.0})
    end

    it "does not flush the cache first by default" do
      expect(provider).not_to receive(:flushcache)
      provider.load_current_resource
    end

    it "flushes the cache first when flush_cache[:before] is true" do
      new_resource.flush_cache before: true
      expect(provider).to receive(:flushcache)
      provider.load_current_resource
    end
  end
end
