#
# Author:: S.Cavallo (<smcavallo@hotmail.com>)
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
require "chef/resource/snap_package"
require "chef/provider/package/snap"
require "support/shared/unit/resource/static_provider_resolution"
require_relative "../../../kitchen-tests/cookbooks/end_to_end/libraries/snap_store_rate_limit"

describe Chef::Resource::SnapPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::SnapPackage,
    provider: Chef::Provider::Package::Snap,
    name: :snap_package,
    action: :install,
    os: "linux"
  )

  let(:resource) { Chef::Resource::SnapPackage.new("foo") }

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  describe EndToEndSnapStoreRateLimit do
    let(:run_context) { Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new) }
    let(:resource) { Chef::Resource::SnapPackage.new("hello", run_context).extend(described_class) }
    let(:provider) { instance_double(Chef::Provider::Package::Snap) }
    let(:rate_limit_error) { Chef::Exceptions::Package.new('{"message" => "too many requests"}') }

    before do
      allow(resource).to receive(:provider_for_action).with(:install).and_return(provider)
      allow(resource).to receive(:sleep)
      resource.retries 3
    end

    ["=>", " => "].each do |separator|
      it "warns after retries and stops notifications for a rate limit using #{separator.inspect}" do
        allow(provider).to receive(:run_action) do
          resource.updated_by_last_action(true)
          raise Chef::Exceptions::Package, %({"message"#{separator}"too many requests"})
        end
        downstream = Chef::Resource::RubyBlock.new("next snap check", run_context)
        downstream.block { raise "notification must not run" }
        downstream.action :nothing
        run_context.resource_collection.insert(downstream)
        resource.notifies :run, downstream, :immediately

        expect(Chef::Log).to receive(:warn).with(/Snap repository issues: too many requests.*coverage was not completed/)
        Chef::Runner.new(run_context).run_action(resource, :install)

        expect(provider).to have_received(:run_action).exactly(4).times
        expect(resource).not_to be_updated_by_last_action
      end
    end

    it "allows recovery during the existing retries without warning" do
      expect(provider).to receive(:run_action).ordered.and_raise(rate_limit_error)
      expect(provider).to receive(:run_action).ordered.and_return(nil)
      expect(Chef::Log).not_to receive(:warn)

      resource.run_action(:install)
    end

    ["=>", " => "].each do |separator|
      it "warns after retries for a Snap Store deadline using #{separator.inspect} without marking it updated" do
        message = 'Get "https://api.snapcraft.io/v2/snaps/info/core?architecture=amd64&fields=version%2Cname": context deadline exceeded'
        error = %({"message"#{separator}#{message.inspect}})
        allow(provider).to receive(:run_action) do
          resource.updated_by_last_action(true)
          raise Chef::Exceptions::Package, error
        end
        expect(Chef::Log).to receive(:warn).with(/Snap repository issues: Snap Store request timed out.*coverage was not completed/)

        resource.run_action(:install)

        expect(provider).to have_received(:run_action).exactly(4).times
        expect(resource).not_to be_updated_by_last_action
      end
    end

    [
      'Get "https://other.example/v2/snaps/info/core": context deadline exceeded',
      'Get "https://api.snapcraft.io.other.example/v2/snaps/info/core": context deadline exceeded',
      "context deadline exceeded",
    ].each do |message|
      it "does not ignore an unrelated deadline: #{message}" do
        allow(provider).to receive(:run_action).and_raise(Chef::Exceptions::Package, { "message" => message }.inspect)
        expect(Chef::Log).not_to receive(:warn)

        expect { resource.run_action(:install) }.to raise_error(Chef::Exceptions::Package, /context deadline exceeded/)
      end
    end

    it "still raises unrelated package failures after retries" do
      allow(provider).to receive(:run_action).and_raise(Chef::Exceptions::Package, '{"message" => "snap not found"}')
      expect(Chef::Log).not_to receive(:warn)

      expect { resource.run_action(:install) }.to raise_error(Chef::Exceptions::Package, /snap not found/)
      expect(provider).to have_received(:run_action).exactly(4).times
    end

    it "does not ignore another exception containing the rate-limit message" do
      allow(provider).to receive(:run_action).and_raise(RuntimeError, rate_limit_error.message)
      expect(Chef::Log).not_to receive(:warn)

      expect { resource.run_action(:install) }.to raise_error(RuntimeError, /too many requests/)
    end

    it "extends only the Snap resources declared by the end-to-end recipe" do
      unrelated = Chef::Resource::SnapPackage.new("unrelated", run_context)
      run_context.resource_collection.insert(unrelated)
      recipe = Chef::Recipe.new("end_to_end", "_snap", run_context)
      recipe.from_file(File.expand_path("../../../kitchen-tests/cookbooks/end_to_end/recipes/_snap.rb", __dir__))

      snaps = run_context.resource_collection.select { |r| r.is_a?(Chef::Resource::SnapPackage) && r != unrelated }
      expect(snaps).not_to be_empty
      expect(snaps).to all(be_a(described_class))
      expect(unrelated).not_to be_a(described_class)
    end
  end

  it "supports :install, :lock, :purge, :reconfig, :remove, :unlock, :upgrade actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :lock }.not_to raise_error
    expect { resource.action :purge }.not_to raise_error
    expect { resource.action :reconfig }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
    expect { resource.action :unlock }.not_to raise_error
    expect { resource.action :upgrade }.not_to raise_error
  end

  it "supports all channel values" do
    expect { resource.channel "stable" }.not_to raise_error
    expect { resource.channel "edge" }.not_to raise_error
    expect { resource.channel "beta" }.not_to raise_error
    expect { resource.channel "candidate" }.not_to raise_error
    expect { resource.channel "latest/stable" }.not_to raise_error
  end
end
