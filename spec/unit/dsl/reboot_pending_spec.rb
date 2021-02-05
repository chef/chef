#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

require "chef/dsl/reboot_pending"
require "spec_helper"

describe Chef::DSL::RebootPending do
  describe "reboot_pending?" do
    describe "in isolation" do
      let(:recipe) { Object.new.extend(Chef::DSL::RebootPending) }

      before do
        allow(recipe).to receive(:platform?).and_return(false)
      end

      context "platform is windows" do
        before do
          allow(recipe).to receive(:platform?).with("windows").and_return(true)
          allow(recipe).to receive(:registry_key_exists?).and_return(false)
          allow(recipe).to receive(:registry_value_exists?).and_return(false)
        end

        it 'should return true if "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations" exists' do
          allow(recipe).to receive(:registry_value_exists?).with('HKLM\SYSTEM\CurrentControlSet\Control\Session Manager', { name: "PendingFileRenameOperations" }).and_return(true)
          expect(recipe.reboot_pending?).to be_truthy
        end

        it 'should return true if "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" exists' do
          allow(recipe).to receive(:registry_key_exists?).with('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired').and_return(true)
          expect(recipe.reboot_pending?).to be_truthy
        end

        it 'should return true if key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired" exists' do
          allow(recipe).to receive(:registry_key_exists?).with('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending').and_return(true)
          expect(recipe.reboot_pending?).to be_truthy
        end
      end

      context "platform_family is debian" do
        before do
          allow(recipe).to receive(:platform_family?).with("debian").and_return(true)
        end

        it "should return true if /var/run/reboot-required exists" do
          allow(File).to receive(:exist?).with("/var/run/reboot-required").and_return(true)
          expect(recipe.reboot_pending?).to be_truthy
        end

        it "should return false if /var/run/reboot-required does not exist" do
          allow(File).to receive(:exist?).with("/var/run/reboot-required").and_return(false)
          expect(recipe.reboot_pending?).to be_falsey
        end
      end

    end # describe in isolation

    describe "in a recipe" do
      it "responds to reboot_pending?" do
        # Chef::Recipe.new(cookbook_name, recipe_name, run_context(node, cookbook_collection, events))
        recipe = Chef::Recipe.new(nil, nil, Chef::RunContext.new(Chef::Node.new, {}, nil))
        expect(recipe).to respond_to(:reboot_pending?)
      end
    end # describe in a recipe

    describe "in a resource" do
      it "responds to reboot_pending?" do
        resource = Chef::Resource.new("Crackerjack::Timing", nil)
        expect(resource).to respond_to(:reboot_pending?)
      end
    end # describe in a resource
  end
end
