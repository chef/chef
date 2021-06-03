# Author: John McCrae (john.mccrae@progress.com)
# Copyright:: Copyright (c) Chef Software Inc.
# License: Apache License, Version 2.0
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
require "chef/mixin/powershell_exec"

describe Chef::Resource::WindowsPagefile, :windows_only do
  include Chef::Mixin::PowershellExec

  let(:c_path) { "c:\\" }
  let(:e_path) { "e:\pagefile.sys" }

  let(:run_context) do
    node = Chef::Node.new
    node.consume_external_attrs(OHAI_SYSTEM.data, {}) # node[:languages][:powershell][:version]
    node.automatic["os"] = "windows"
    node.automatic["platform"] = "windows"
    node.automatic["platform_version"] = "6.1"
    node.automatic["kernel"][:machine] = :x86_64 # Only 64-bit architecture is supported
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  end

  subject do
    new_resource = Chef::Resource::WindowsPagefile.new("pagefile", run_context)
    new_resource
  end

  describe "Setting Up Pagefile Management" do
    context "Disable Automatic Management" do
      it "Disables Automatic Management" do
        subject.path c_path
        subject.automatic_managed false
        subject.run_action(:set)
        expect(subject).to be_updated_by_last_action
      end

      it "Enable Automatic Management " do
        subject.path c_path
        subject.automatic_managed true
        subject.run_action(:set)
        expect(subject).to be_updated_by_last_action
      end
    end
  end

  describe "Creating a new Pagefile" do
    context "Create new pagefile" do
      it "Creates a new pagefile on a different drive that doesn't exist" do
        subject.path e_path
        expect { subject.run_action(:set) }.to raise_error(RuntimeError)
      end
    end

    context "Update a pagefile" do
      it "Changes a pagefile to use custom sizes" do
        subject.path c_path
        subject.initial_size 20000
        subject.maximum_size 80000
        subject.run_action(:set)
        expect(subject).to be_updated_by_last_action
      end
    end
  end

  describe "Deleting a Pagefile and Resetting to Automatically Managed" do
    context "delete the pagefile on disk" do
      it "deletes the pagefile located at the given path" do
        subject.path c_path
        subject.run_action(:delete)
        expect(subject).to be_updated_by_last_action
      end
    end

    context "Re-enable automatic management of pagefiles" do
      it "Enable Automatic Management " do
        subject.path c_path
        subject.automatic_managed true
        subject.run_action(:set)
        expect(subject).to be_updated_by_last_action
      end
    end
  end
end
