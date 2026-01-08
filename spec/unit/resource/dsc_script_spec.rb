#
# Author:: Adam Edwards (<adamed@chef.io>)
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

describe Chef::Resource::DscScript do
  let(:resource_name) { "DSCTest" }

  context "when Powershell supports Dsc" do
    let(:dsc_test_run_context) do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = "4.0"
      empty_events = Chef::EventDispatch::Dispatcher.new
      Chef::RunContext.new(node, {}, empty_events)
    end
    let(:resource) do
      Chef::Resource::DscScript.new(resource_name, dsc_test_run_context)
    end
    let(:configuration_code) { 'echo "This is supposed to create a configuration document."' }
    let(:configuration_path) { "c:/myconfigs/formatc.ps1" }
    let(:configuration_name) { "formatme" }
    let(:configuration_data) { '@{AllNodes = @( @{ NodeName = "localhost"; PSDscAllowPlainTextPassword = $true })}' }
    let(:configuration_data_script) { "c:/myconfigs/data/safedata.psd1" }

    it "sets the default action as :run" do
      expect(resource.action).to eql([:run])
    end

    it "supports :run action" do
      expect { resource.action :run }.not_to raise_error
    end

    it "allows the code property to be set" do
      resource.code(configuration_code)
      expect(resource.code).to eq(configuration_code)
    end

    it "allows the command property to be set" do
      resource.command(configuration_path)
      expect(resource.command).to eq(configuration_path)
    end

    it "allows the configuration_name property to be set" do
      resource.configuration_name(configuration_name)
      expect(resource.configuration_name).to eq(configuration_name)
    end

    it "allows the configuration_data property to be set" do
      resource.configuration_data(configuration_data)
      expect(resource.configuration_data).to eq(configuration_data)
    end

    it "allows the configuration_data_script property to be set" do
      resource.configuration_data_script(configuration_data_script)
      expect(resource.configuration_data_script).to eq(configuration_data_script)
    end

    it "has the ps_credential helper method" do
      expect(resource).to respond_to(:ps_credential)
    end

    context "when calling imports" do
      let(:module_name)   { "FooModule" }
      let(:module_name_b)   { "BarModule" }
      let(:dsc_resources) { %w{ResourceA ResourceB} }

      it "allows an arbitrary number of resources to be set for a module to be set" do
        resource.imports module_name, *dsc_resources
        module_imports = resource.imports[module_name]
        expect(module_imports).to eq(dsc_resources)
      end

      it "adds * to the imports when no resources are set for a moudle" do
        resource.imports module_name
        module_imports = resource.imports[module_name]
        expect(module_imports).to eq(["*"])
      end

      it "allows an arbitrary number of modules" do
        resource.imports module_name
        resource.imports module_name_b
        expect(resource.imports).to have_key(module_name)
        expect(resource.imports).to have_key(module_name_b)
      end

      it "allows resources to be added for a module" do
        resource.imports module_name, dsc_resources[0]
        resource.imports module_name, dsc_resources[1]
        module_imports = resource.imports[module_name]
        expect(module_imports).to eq(dsc_resources)
      end
    end

    it "raises an ArgumentError exception if an attempt is made to set the code property when the command property is already set" do
      resource.command(configuration_path)
      expect { resource.code(configuration_code) }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError exception if an attempt is made to set the command property when the code property is already set" do
      resource.code(configuration_code)
      expect { resource.command(configuration_path) }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError exception if an attempt is made to set the configuration_name property when the code property is already set" do
      resource.code(configuration_code)
      expect { resource.configuration_name(configuration_name) }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError exception if an attempt is made to set the configuration_data property when the configuration_data_script property is already set" do
      resource.configuration_data_script(configuration_data_script)
      expect { resource.configuration_data(configuration_data) }.to raise_error(ArgumentError)
    end

    it "raises an ArgumentError exception if an attempt is made to set the configuration_data_script property when the configuration_data property is already set" do
      resource.configuration_data(configuration_data)
      expect { resource.configuration_data_script(configuration_data_script) }.to raise_error(ArgumentError)
    end
  end
end
