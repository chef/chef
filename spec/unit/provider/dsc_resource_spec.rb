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
require "spec_helper"

describe Chef::Provider::DscResource do
  let (:events) { Chef::EventDispatch::Dispatcher.new }
  let (:run_context) { Chef::RunContext.new(node, {}, events) }
  let (:resource) { Chef::Resource::DscResource.new("dscresource", run_context) }
  let (:provider) do
    Chef::Provider::DscResource.new(resource, run_context)
  end

  context "when Powershell does not support Invoke-DscResource" do
    let (:node) do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = "4.0"
      node
    end
    it "raises a ProviderNotFound exception" do
      expect(provider).not_to receive(:meta_configuration)
      expect { provider.run_action(:run) }.to raise_error(
              Chef::Exceptions::ProviderNotFound, /5\.0\.10018\.0/)
    end
  end

  context "when Powershell supports Invoke-DscResource" do

    context "when RefreshMode is not set to Disabled" do
      context "and the WMF 5 is a preview release" do
        let (:node) do
          node = Chef::Node.new
          node.automatic[:languages][:powershell][:version] = "5.0.10018.0"
          node
        end
        it "raises an exception" do
          expect(provider).to receive(:dsc_refresh_mode_disabled?).and_return(false)
          expect { provider.run_action(:run) }.to raise_error(
            Chef::Exceptions::ProviderNotFound, /Disabled/)
        end
      end
      context "and the WMF is 5 RTM or newer" do
        let (:node) do
          node = Chef::Node.new
          node.automatic[:languages][:powershell][:version] = "5.0.10586.0"
          node
        end
        it "does not raises an exception" do
          expect(provider).to receive(:test_resource)
          expect(provider).to receive(:set_resource)
          expect(provider).to receive(:reboot_if_required)
          expect { provider.run_action(:run) }.to_not raise_error
        end
      end
    end
  end

  context "when the LCM supports Invoke-DscResource" do
    let (:node) do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = "5.0.10018.0"
      node
    end
    let (:resource_result) { double("CmdletResult", return_value: { "InDesiredState" => true }, stream: "description") }
    let (:invoke_dsc_resource) { double("cmdlet", run!: resource_result) }
    let (:store) { double("ResourceStore", find: resource_records) }
    let (:resource_records) { [] }

    before do
      allow(Chef::Util::DSC::ResourceStore).to receive(:instance).and_return(store)
      allow(Chef::Util::Powershell::Cmdlet).to receive(:new).and_return(invoke_dsc_resource)
      allow(provider).to receive(:dsc_refresh_mode_disabled?).and_return(true)
    end

    it "does not update the resource if it is up to date" do
      expect(provider).to receive(:test_resource).and_return(true)
      provider.run_action(:run)
      expect(resource).not_to be_updated
    end

    it "converges the resource if it is not up to date" do
      expect(provider).to receive(:test_resource).and_return(false)
      expect(provider).to receive(:set_resource)
      provider.run_action(:run)
      expect(resource).to be_updated
    end

    it "flags the resource as reboot required when required" do
      expect(provider).to receive(:test_resource).and_return(false)
      expect(provider).to receive(:invoke_resource).
        and_return(double(:stdout => "", :return_value => nil))
      expect(provider).to receive(:add_dsc_verbose_log)
      expect(provider).to receive(:return_dsc_resource_result).and_return(true)
      expect(provider).to receive(:create_reboot_resource)
      provider.run_action(:run)
    end

    it "does not flag the resource as reboot required when not required" do
      expect(provider).to receive(:test_resource).and_return(false)
      expect(provider).to receive(:invoke_resource).
        and_return(double(:stdout => "", :return_value => nil))
      expect(provider).to receive(:add_dsc_verbose_log)
      expect(provider).to receive(:return_dsc_resource_result).and_return(false)
      expect(provider).to_not receive(:create_reboot_resource)
      provider.run_action(:run)
    end

    context "resource name cannot be found" do
      let (:resource_records) { [] }

      it "raises ResourceNotFound" do
        expect { provider.run_action(:run) }.to raise_error(Chef::Exceptions::ResourceNotFound)
      end
    end

    context "resource name is found" do
      context "no module name for resource found" do
        let (:resource_records) { [{}] }

        it "returns the default dsc resource module" do
          expect(Chef::Util::Powershell::Cmdlet).to receive(:new) do |node, cmdlet, format|
            expect(cmdlet).to match(/Module PSDesiredStateConfiguration /)
          end.and_return(invoke_dsc_resource)
          provider.run_action(:run)
        end
      end

      context "a module name for resource is found" do
        let (:resource_records) { [{ "Module" => { "Name" => "ModuleName" } }] }

        it "returns the default dsc resource module" do
          expect(Chef::Util::Powershell::Cmdlet).to receive(:new) do |node, cmdlet, format|
            expect(cmdlet).to match(/Module ModuleName /)
          end.and_return(invoke_dsc_resource)
          provider.run_action(:run)
        end
      end

      context "multiple resource are found" do
        let (:resource_records) do
          [
          { "Module" => { "Name" => "ModuleName1" } },
          { "Module" => { "Name" => "ModuleName2" } },
        ] end

        it "raises MultipleDscResourcesFound" do
          expect { provider.run_action(:run) }.to raise_error(Chef::Exceptions::MultipleDscResourcesFound)
        end
      end
    end
  end

  describe "define_resource_requirements" do
    let (:node) do
      set_node_object
    end

    context "module usage is valid" do
      before do
        allow(provider).to receive(:module_usage_valid?).and_return(true)
        allow(provider).to receive(:action_run)
      end

      [:run].each do |action|
        context "action #{action}" do
          it "does not raise the exception" do
            expect { provider.run_action(action) }.not_to raise_error
          end
        end
      end
    end

    context "module usage is invalid" do
      before do
        allow(provider).to receive(:module_usage_valid?).and_return(false)
        allow(provider).to receive(:action_run)
      end

      [:run].each do |action|
        context "action #{action}" do
          it "raises the exception" do
            expect { provider.run_action(action) }.to raise_error(
              Chef::Exceptions::DSCModuleNameMissing
            )
          end
        end
      end
    end
  end

  describe "module_usage_valid?" do
    let (:node) do
      set_node_object
    end

    context "module_name and module_version both are not provided" do
      before do
        provider.instance_variable_set(:@module_name, nil)
        provider.instance_variable_set(:@module_version, nil)
      end

      it "returns true" do
        response = provider.send(:module_usage_valid?)
        expect(response).to be == true
      end
    end

    context "module_name and module_version both are provided" do
      before do
        provider.instance_variable_set(:@module_name, "my_module")
        provider.instance_variable_set(:@module_version, "1.3")
      end

      it "returns true" do
        response = provider.send(:module_usage_valid?)
        expect(response).to be == true
      end
    end

    context "module_name is given but module_version is not given" do
      before do
        provider.instance_variable_set(:@module_name, "my_module")
        provider.instance_variable_set(:@module_version, nil)
      end

      it "returns true" do
        response = provider.send(:module_usage_valid?)
        expect(response).to be == true
      end
    end

    context "module_name is not given but module_version is given" do
      before do
        provider.instance_variable_set(:@module_name, nil)
        provider.instance_variable_set(:@module_version, "1.4.0.1")
      end

      it "returns false" do
        response = provider.send(:module_usage_valid?)
        expect(response).to be == false
      end
    end
  end

  describe "module_info_object" do
    let (:node) do
      set_node_object
    end

    context "module_version is not given" do
      before do
        provider.instance_variable_set(:@module_version, nil)
        allow(provider).to receive(:module_name).and_return("my_module")
      end

      it "returns only name of the module" do
        response = provider.send(:module_info_object)
        expect(response).to be == "my_module"
      end
    end

    context "module_version is given" do
      before do
        provider.instance_variable_set(:@module_version, "1.3.1")
        allow(provider).to receive(:module_name).and_return("my_module")
      end

      it "returns the module info object" do
        response = provider.send(:module_info_object)
        expect(response).to be == "@{ModuleName='my_module';ModuleVersion='1.3.1'}"
      end
    end
  end

  describe "invoke_resource" do
    let (:node) do
      set_node_object
    end

    let(:cmdlet) { double(:run! => nil) }

    before(:each) do
      allow(provider).to receive(:translate_type).and_return("my_properties")
      provider.instance_variable_set(:@new_resource, double(
        :properties => "my_properties", :resource => "my_resource", :timeout => 123
      ))
    end

    context "when module_version is not given" do
      before do
        allow(provider).to receive(:module_info_object).and_return("my_module")
      end

      it "invokes Invoke-DscResource command with module name" do
        expect(Chef::Util::Powershell::Cmdlet).to receive(:new).with(
          node,
          "Invoke-DscResource -Method my_method -Name my_resource -Property my_properties -Module my_module -Verbose",
          "my_output_format"
        ).and_return(cmdlet)
        provider.send(:invoke_resource, "my_method", "my_output_format")
      end
    end

    context "when module_version is given" do
      before do
        allow(provider).to receive(:module_info_object).and_return(
          "@{ModuleName='my_module';ModuleVersion='my_module_version'}"
        )
      end

      it "invokes Invoke-DscResource command with module info object" do
        expect(Chef::Util::Powershell::Cmdlet).to receive(:new).with(
          node,
          "Invoke-DscResource -Method my_method -Name my_resource -Property my_properties -Module @{ModuleName='my_module';ModuleVersion='my_module_version'} -Verbose",
          "my_output_format"
        ).and_return(cmdlet)
        provider.send(:invoke_resource, "my_method", "my_output_format")
      end
    end
  end
end

def set_node_object
  node = Chef::Node.new
  node.automatic[:languages][:powershell][:version] = "5.0.10586.0"
  node
end
