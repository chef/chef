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
require "ostruct"

describe Chef::Resource::HomebrewCask do

  context "name with under bar" do
    let(:resource) { Chef::Resource::HomebrewCask.new("fakey_fakerton") }

    it "has a resource name of :homebrew_cask" do
      expect(resource.resource_name).to eql(:homebrew_cask)
    end

    it "the cask_name property is the name_property" do
      expect(resource.cask_name).to eql("fakey_fakerton")
    end

    it "sets the default action as :install" do
      expect(resource.action).to eql([:install])
    end

    it "supports :install, :remove actions" do
      expect { resource.action :install }.not_to raise_error
      expect { resource.action :remove }.not_to raise_error
    end
  end

  context "name with high fun" do
    let(:resource) { Chef::Resource::HomebrewCask.new("fakey-fakerton") }

    it "the cask_name property is the name_property" do
      expect(resource.cask_name).to eql("fakey-fakerton")
    end
  end

  context "name with at mark" do
    let(:resource) { Chef::Resource::HomebrewCask.new("fakey-fakerton@10") }

    it "the cask_name property is the name_property" do
      expect(resource.cask_name).to eql("fakey-fakerton@10")
    end
  end

  # Regression tests: brew's vendored (setgid) portable-ruby raises
  # "no -I allowed while running setgid (SecurityError)" when Homebrew
  # commands are executed via a login shell (`login true`). This is the
  # same underlying issue reported in
  # https://github.com/chef/chef/issues/14885 and previously fixed for
  # the homebrew_package provider by removing `login: true`. We must not
  # reintroduce `login true` anywhere in homebrew_cask.
  context "avoiding the homebrew setgid/login shell bug (GH-14885)" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:resource) do
      Chef::Resource::HomebrewCask.new("1password", run_context).tap do |r|
        # Avoid the `owner` property's lazy default (find_homebrew_username),
        # which would otherwise shell out to locate a real "brew" binary --
        # something that isn't installed on the Linux/Windows CI runners
        # that also execute this unit test suite.
        r.owner "testuser"
      end
    end
    let(:provider) { resource.provider_for_action(:install) }

    before do
      # These specs only care that `login: true` is never passed and that
      # the expected environment is set; they don't exercise real Homebrew
      # path/user detection, which would fail on CI runners (Linux/Windows)
      # that don't have "brew" on the PATH or a "testuser" account.
      allow_any_instance_of(Chef::Mixin::Homebrew).to receive(:homebrew_bin_path).and_return("/opt/homebrew/bin/brew")
      allow(::Dir).to receive(:home).with("testuser").and_return("/Users/testuser")
    end

    describe "#casked?" do
      it "does not pass login: true to shell_out!" do
        expect(provider).to receive(:shell_out!) do |*_args, **opts|
          expect(opts).not_to have_key(:login)
          expect(opts[:env]).to include("RUBYOPT" => nil, "TMPDIR" => nil)
          OpenStruct.new(stdout: "")
        end
        provider.send(:casked?)
      end
    end

    describe "action :install" do
      it "runs the underlying execute resource without `login true`" do
        allow(provider).to receive(:casked?).and_return(false)
        allow_any_instance_of(Chef::Provider::Execute).to receive(:shell_out!) do |instance, *_args, **_opts|
          expect(instance.new_resource.login).to be_falsey
          expect(instance.new_resource.environment).to include("RUBYOPT" => nil, "TMPDIR" => nil)
          OpenStruct.new(stdout: "", exitstatus: 0)
        end
        provider.run_action(:install)
      end
    end

    describe "action :remove" do
      it "runs the underlying execute resource without `login true`" do
        allow(provider).to receive(:casked?).and_return(true)
        allow_any_instance_of(Chef::Provider::Execute).to receive(:shell_out!) do |instance, *_args, **_opts|
          expect(instance.new_resource.login).to be_falsey
          expect(instance.new_resource.environment).to include("RUBYOPT" => nil, "TMPDIR" => nil)
          OpenStruct.new(stdout: "", exitstatus: 0)
        end
        provider.run_action(:remove)
      end
    end
  end
end
