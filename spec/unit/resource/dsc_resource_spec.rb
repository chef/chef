#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
describe Chef::Resource::DscResource do
  let(:dsc_test_resource_name) { "DSCTest" }
  let(:dsc_test_resource_module_version) { "2.7.2" }
  let(:dsc_test_property_name) { :DSCTestProperty }
  let(:dsc_test_property_value) { "DSCTestValue" }
  let(:dsc_test_reboot_action) { :reboot_now }
  let(:dsc_test_timeout) { 101 }

  context "when Powershell supports Dsc" do
    let(:dsc_test_run_context) do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = "5.0.10018.0"
      empty_events = Chef::EventDispatch::Dispatcher.new
      Chef::RunContext.new(node, {}, empty_events)
    end

    let(:dsc_test_resource) do
      Chef::Resource::DscResource.new(dsc_test_resource_name, dsc_test_run_context)
    end

    it "has a default action of `:run`" do
      expect(dsc_test_resource.action).to eq([:run])
    end

    it "has an ed_actions attribute with only the `:run` and `:nothing` attributes" do
      expect(dsc_test_resource.allowed_actions.to_set).to eq([:run, :nothing].to_set)
    end

    it "allows the resource attribute to be set" do
      dsc_test_resource.resource(dsc_test_resource_name)
      expect(dsc_test_resource.resource).to eq(dsc_test_resource_name)
    end

    it "allows the module_name attribute to be set" do
      dsc_test_resource.module_name(dsc_test_resource_name)
      expect(dsc_test_resource.module_name).to eq(dsc_test_resource_name)
    end

    it "allows the module_version attribute to be set" do
      dsc_test_resource.module_version(dsc_test_resource_module_version)
      expect(dsc_test_resource.module_version).to eq(dsc_test_resource_module_version)
    end

    it "allows the reboot_action attribute to be set" do
      dsc_test_resource.reboot_action(dsc_test_reboot_action)
      expect(dsc_test_resource.reboot_action).to eq(dsc_test_reboot_action)
    end

    it "allows the timeout attribute to be set" do
      dsc_test_resource.timeout(dsc_test_timeout)
      expect(dsc_test_resource.timeout).to eq(dsc_test_timeout)
    end

    context "when setting a dsc property" do
      it "allows setting a dsc property with a property name of type Symbol" do
        dsc_test_resource.property(dsc_test_property_name, dsc_test_property_value)
        expect(dsc_test_resource.property(dsc_test_property_name)).to eq(dsc_test_property_value)
        expect(dsc_test_resource.properties[dsc_test_property_name]).to eq(dsc_test_property_value)
      end

      it "raises a TypeError if property_name is not a symbol" do
        expect do
          dsc_test_resource.property("Foo", dsc_test_property_value)
        end.to raise_error(TypeError)
      end

      context "when using DelayedEvaluators" do
        it "allows setting a dsc property with a property name of type Symbol" do
          dsc_test_resource.property(dsc_test_property_name, Chef::DelayedEvaluator.new do
            dsc_test_property_value
          end)
          expect(dsc_test_resource.property(dsc_test_property_name)).to eq(dsc_test_property_value)
          expect(dsc_test_resource.properties[dsc_test_property_name]).to eq(dsc_test_property_value)
        end
      end
    end

    context "Powershell DSL methods" do
      it "responds to :ps_credential" do
        expect(dsc_test_resource.respond_to?(:ps_credential)).to be true
      end
    end
  end
end
