#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
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

require "chef"
require "chef/util/dsc/resource_info"
require "spec_helper"

describe Chef::Provider::DscScript do
  context "when DSC is available" do
    let (:node) do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = "4.0"
      node
    end
    let (:events) { Chef::EventDispatch::Dispatcher.new }
    let (:run_context) { Chef::RunContext.new(node, {}, events) }
    let (:resource) { Chef::Resource::DscScript.new("script", run_context) }
    let (:provider) do
      Chef::Provider::DscScript.new(resource, run_context)
    end

    describe "#load_current_resource" do
      it "describes the resource as converged if there were 0 DSC resources" do
        allow(provider).to receive(:run_configuration).with(:test).and_return([])
        provider.load_current_resource
        expect(provider.instance_variable_get("@resource_converged")).to be_truthy
      end

      it "describes the resource as not converged if there is 1 DSC resources that is converged" do
        dsc_resource_info = Chef::Util::DSC::ResourceInfo.new("resource", false, ["nothing will change something"])
        allow(provider).to receive(:run_configuration).with(:test).and_return([dsc_resource_info])
        provider.load_current_resource
        expect(provider.instance_variable_get("@resource_converged")).to be_truthy
      end

      it "describes the resource as not converged if there is 1 DSC resources that is not converged" do
        dsc_resource_info = Chef::Util::DSC::ResourceInfo.new("resource", true, ["will change something"])
        allow(provider).to receive(:run_configuration).with(:test).and_return([dsc_resource_info])
        provider.load_current_resource
        expect(provider.instance_variable_get("@resource_converged")).to be_falsey
      end

      it "describes the resource as not converged if there are any DSC resources that are not converged" do
        dsc_resource_info1 = Chef::Util::DSC::ResourceInfo.new("resource", true, ["will change something"])
        dsc_resource_info2 = Chef::Util::DSC::ResourceInfo.new("resource", false, ["nothing will change something"])

        allow(provider).to receive(:run_configuration).with(:test).and_return([dsc_resource_info1, dsc_resource_info2])
        provider.load_current_resource
        expect(provider.instance_variable_get("@resource_converged")).to be_falsey
      end

      it "describes the resource as converged if all DSC resources that are converged" do
        dsc_resource_info1 = Chef::Util::DSC::ResourceInfo.new("resource", false, ["nothing will change something"])
        dsc_resource_info2 = Chef::Util::DSC::ResourceInfo.new("resource", false, ["nothing will change something"])

        allow(provider).to receive(:run_configuration).with(:test).and_return([dsc_resource_info1, dsc_resource_info2])
        provider.load_current_resource
        expect(provider.instance_variable_get("@resource_converged")).to be_truthy
      end
    end

    describe "#generate_configuration_document" do
      # I think integration tests should cover these cases

      it "uses configuration_document_from_script_path when a dsc script file is given" do
        allow(provider).to receive(:load_current_resource)
        resource.command("path_to_script")
        generator = double("Chef::Util::DSC::ConfigurationGenerator")
        expect(generator).to receive(:configuration_document_from_script_path)
        allow(Chef::Util::DSC::ConfigurationGenerator).to receive(:new).and_return(generator)
        provider.send(:generate_configuration_document, "tmp", nil)
      end

      it "uses configuration_document_from_script_code when a the dsc resource is given" do
        allow(provider).to receive(:load_current_resource)
        resource.code("ImADSCResource{}")
        generator = double("Chef::Util::DSC::ConfigurationGenerator")
        expect(generator).to receive(:configuration_document_from_script_code)
        allow(Chef::Util::DSC::ConfigurationGenerator).to receive(:new).and_return(generator)
        provider.send(:generate_configuration_document, "tmp", nil)
      end

      it "should noop if neither code or command are provided" do
        allow(provider).to receive(:load_current_resource)
        generator = double("Chef::Util::DSC::ConfigurationGenerator")
        expect(generator).to receive(:configuration_document_from_script_code).with("", anything(), anything(), anything())
        allow(Chef::Util::DSC::ConfigurationGenerator).to receive(:new).and_return(generator)
        provider.send(:generate_configuration_document, "tmp", nil)
      end
    end

    describe "action_run" do
      it "should converge the script if it is not converged" do
        dsc_resource_info = Chef::Util::DSC::ResourceInfo.new("resource", true, ["will change something"])
        allow(provider).to receive(:run_configuration).with(:test).and_return([dsc_resource_info])
        allow(provider).to receive(:run_configuration).with(:set)

        provider.run_action(:run)
        expect(resource).to be_updated
      end

      it "should not converge if the script is already converged" do
        allow(provider).to receive(:run_configuration).with(:test).and_return([])

        provider.run_action(:run)
        expect(resource).not_to be_updated
      end
    end

    describe "#generate_description" do
      it "removes the resource name from the beginning of any log line from the LCM" do
        dsc_resource_info = Chef::Util::DSC::ResourceInfo.new("resourcename", true, ["resourcename doing something", "lastline"])
        provider.instance_variable_set("@dsc_resources_info", [dsc_resource_info])
        expect(provider.send(:generate_description)[1]).to match(/converge DSC resource resourcename by doing something/)
      end

      it "ignores the last line" do
        dsc_resource_info = Chef::Util::DSC::ResourceInfo.new("resourcename", true, ["resourcename doing something", "lastline"])
        provider.instance_variable_set("@dsc_resources_info", [dsc_resource_info])
        expect(provider.send(:generate_description)[1]).not_to match(/lastline/)
      end

      it "reports a dsc resource has not been changed if the LCM reported no change was required" do
        dsc_resource_info = Chef::Util::DSC::ResourceInfo.new("resourcename", false, ["resourcename does nothing", "lastline"])
        provider.instance_variable_set("@dsc_resources_info", [dsc_resource_info])
        expect(provider.send(:generate_description)[1]).to match(/converge DSC resource resourcename by doing nothing/)
      end
    end
  end

  context "when Dsc is not available" do
    let (:node) { Chef::Node.new }
    let (:events) { Chef::EventDispatch::Dispatcher.new }
    let (:run_context) { Chef::RunContext.new(node, {}, events) }
    let (:resource) { Chef::Resource::DscScript.new("script", run_context) }
    let (:provider) { Chef::Provider::DscScript.new(resource, run_context) }

    describe "action_run" do
      ["1.0", "2.0", "3.0"].each do |version|
        it "raises an exception for powershell version '#{version}'" do
          node.automatic[:languages][:powershell][:version] = version

          expect do
            provider.run_action(:run)
          end.to raise_error(Chef::Exceptions::ProviderNotFound)
        end
      end

      it "raises an exception if Powershell is not present" do
        expect do
          provider.run_action(:run)
        end.to raise_error(Chef::Exceptions::ProviderNotFound)
      end

    end
  end
end
