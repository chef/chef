#
# Author:: Thom May (<thom@chef.io>)
# Author:: Tim Smith (<tim@chef.io>)
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
require "chef/resource/apt_preference"

# FIXME: provider has been moved to a custom resource, should migrate the unit tests
#
describe "Chef::Provider::AptPreference" do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:collection) { double("resource collection") }
  let(:new_resource) { Chef::Resource::AptPreference.new("libmysqlclient16.1*", run_context) }
  let(:pref_dir) { Dir.mktmpdir("apt_pref_d") }
  let(:provider) { new_resource.provider_for_action(:add) }

  before do
    node.automatic["platform_family"] = "debian"
    Chef::Resource::AptPreference.send(:remove_const, :APT_PREFERENCE_DIR)
    Chef::Resource::AptPreference.const_set(:APT_PREFERENCE_DIR, pref_dir)

    new_resource.pin = "1.0.1"
    new_resource.pin_priority 1001
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end

  context "#action_add" do
    context "without a preferences.d directory" do
      before do
        FileUtils.rmdir pref_dir
      end

      it "creates the preferences.d directory" do
        provider.run_action(:add)
        expect(new_resource).to be_updated_by_last_action
        expect(File.exist?(pref_dir)).to be true
        expect(File.directory?(pref_dir)).to be true
      end
    end

    context "with a preferences.d directory" do
      before do
        FileUtils.mkdir pref_dir unless ::File.exist?(pref_dir)
        FileUtils.touch("#{pref_dir}/libmysqlclient16.1*.pref")
        FileUtils.touch("#{pref_dir}/libmysqlclient16.1*")
      end

      # FileUtils.touch throws "Invalid argument @ utime_failed" in appveyer
      it "creates a sanitized .pref file and removes the legacy cookbook files", :unix_only do
        provider.run_action(:add)
        expect(new_resource).to be_updated_by_last_action
        expect(File).not_to exist("#{pref_dir}/libmysqlclient16.1*.pref")
        expect(File).not_to exist("#{pref_dir}/libmysqlclient16.1*")
        expect(File.read(::File.join(pref_dir, "libmysqlclient16_1wildcard.pref"))).to match(/Package: libmysqlclient16.1*.*Pin: 1.0.1.*Pin-Priority: 1001/m)
      end
    end
  end

  context "#action_delete" do
    before do
      FileUtils.mkdir pref_dir unless ::File.exist?(pref_dir)
      FileUtils.touch("#{pref_dir}/libmysqlclient16_1wildcard.pref")
    end

    it "deletes the name sanitized .pref file" do
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
      expect(File).not_to exist("#{pref_dir}/libmysqlclient16_1wildcard.pref")
    end
  end
end
