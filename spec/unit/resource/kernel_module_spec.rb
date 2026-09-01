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

describe Chef::Resource::KernelModule do
  let(:resource) { Chef::Resource::KernelModule.new("foo") }

  it "sets resource name as :kernel_module" do
    expect(resource.resource_name).to eql(:kernel_module)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "sets the modname property as its name property" do
    expect(resource.modname).to eql("foo")
  end

  it "supports various actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :uninstall }.not_to raise_error
    expect { resource.action :blacklist }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :load }.not_to raise_error
    expect { resource.action :unload }.not_to raise_error
    expect { resource.action :delete }.to raise_error(ArgumentError)
  end

  describe "#declare_initramfs_resource" do
    let(:node) do
      node = Chef::Node.new
      node.automatic[:platform_family] = "rhel"
      node.automatic[:platform] = "redhat"
      node.automatic[:platform_version] = "9.0"
      node
    end
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:provider) do
      resource.run_context = run_context
      resource.provider_for_action(:install)
    end

    it "declares the shared execute resource in the root run context" do
      initramfs = provider.declare_initramfs_resource
      expect(initramfs.to_s).to eq("execute[update initramfs]")
      expect(initramfs.command).to eq("dracut -f")
      expect(initramfs.action).to eq([:nothing])
    end

    it "does not set ignore_failure when the kernel_module resource did not" do
      expect(provider.declare_initramfs_resource.ignore_failure).to be false
    end

    it "carries ignore_failure over to the initramfs rebuild" do
      resource.ignore_failure true
      expect(provider.declare_initramfs_resource.ignore_failure).to be true
    end

    it "carries :quiet over rather than coercing it to true" do
      resource.ignore_failure :quiet
      expect(provider.declare_initramfs_resource.ignore_failure).to eq(:quiet)
    end

    it "keeps ignore_failure once any kernel_module in the run has asked for it" do
      resource.ignore_failure true
      provider.declare_initramfs_resource

      other = Chef::Resource::KernelModule.new("bar")
      other.run_context = run_context
      other_provider = other.provider_for_action(:install)

      # the shared resource already exists, so find_resource returns it as-is
      expect(other_provider.declare_initramfs_resource.ignore_failure).to be true
    end
  end
end
