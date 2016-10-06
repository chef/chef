#
# Author:: Adam Edwards <adamed@chef.io>
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
require "chef/util/dsc/local_configuration_manager"

describe Chef::Util::DSC::LocalConfigurationManager do

  let(:lcm) { Chef::Util::DSC::LocalConfigurationManager.new(nil, "tmp") }

  let(:normal_lcm_output) do
    <<-EOH
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ] [name]
logtype: [machinename]: LCM:  [ End    Resource ] [name]
logtype: [machinename]: LCM:  [ End    Set      ]
EOH
  end

  let(:no_whatif_lcm_output) do
    <<-EOH
Start-DscConfiguration : A parameter cannot be found\r\n that matches parameter name 'whatif'.
At line:1 char:123
+ run-somecommand -whatif
+                        ~~~~~~~~
    + CategoryInfo          : InvalidArgument: (:) [Start-DscConfiguration], ParameterBindingException
    + FullyQualifiedErrorId : NamedParameterNotFound,SomeCompany.SomeAssembly.Commands.RunSomeCommand
EOH
  end

  let(:dsc_resource_import_failure_output) do
    <<-EOH
PowerShell provider MSFT_xWebsite failed to execute Test-TargetResource functionality with error message: Please ensure that WebAdministration module is installed. + CategoryInfo : InvalidOperation: (:) [], CimException + FullyQualifiedErrorId : ProviderOperationExecutionFailure + PSComputerName : . PowerShell provider MSFT_xWebsite failed to execute Test-TargetResource functionality with error message: Please ensure that WebAdministration module is installed. + CategoryInfo : InvalidOperation: (:) [], CimException + FullyQualifiedErrorId : ProviderOperationExecutionFailure + PSComputerName : . The SendConfigurationApply function did not succeed. + CategoryInfo : NotSpecified: (root/Microsoft/...gurationManager:String) [], CimException + FullyQualifiedErrorId : MI RESULT 1 + PSComputerName : .
EOH
  end

  let(:lcm_status) do
    double("LCM cmdlet status", :stderr => lcm_standard_error, :return_value => lcm_standard_output, :succeeded? => lcm_cmdlet_success)
  end

  describe "test_configuration method invocation" do
    context "when interacting with the LCM using a PowerShell cmdlet" do
      before(:each) do
        allow(lcm).to receive(:run_configuration_cmdlet).and_return(lcm_status)
      end
      context "that returns successfully" do
        let(:lcm_standard_output) { normal_lcm_output }
        let(:lcm_standard_error) { nil }
        let(:lcm_cmdlet_success) { true }

        it "should successfully return resource information for normally formatted output when cmdlet the cmdlet succeeds" do
          test_configuration_result = lcm.test_configuration("config", {})
          expect(test_configuration_result.class).to be(Array)
          expect(test_configuration_result.length).to be > 0
          expect(Chef::Log).not_to receive(:warn)
        end
      end

      context "that fails due to missing what-if switch in DSC resource cmdlet implementation" do
        let(:lcm_standard_output) { "" }
        let(:lcm_standard_error) { no_whatif_lcm_output }
        let(:lcm_cmdlet_success) { false }

        it "returns true when passed to #whatif_not_supported?" do
          expect(lcm.send(:whatif_not_supported?, no_whatif_lcm_output)).to be_truthy
        end

        it "should should return a (possibly empty) array of ResourceInfo instances" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          expect(lcm).to receive(:whatif_not_supported?).and_call_original
          test_configuration_result = nil
          expect { test_configuration_result = lcm.test_configuration("config", {}) }.not_to raise_error
          expect(test_configuration_result.class).to be(Array)
        end
      end

      context "that fails due to a DSC resource not being imported before StartDSCConfiguration -whatif is executed" do
        let(:lcm_standard_output) { "" }
        let(:lcm_standard_error) { dsc_resource_import_failure_output }
        let(:lcm_cmdlet_success) { false }

        it "should log a warning if the message is formatted as expected when a resource import failure occurs" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          expect(lcm).to receive(:dsc_module_import_failure?).and_call_original
          test_configuration_result = nil
          expect { test_configuration_result = lcm.test_configuration("config", {}) }.not_to raise_error
        end

        it "should return a (possibly empty) array of ResourceInfo instances" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          test_configuration_result = nil
          expect { test_configuration_result = lcm.test_configuration("config", {}) }.not_to raise_error
          expect(test_configuration_result.class).to be(Array)
        end
      end

      context "that fails due to an unknown PowerShell cmdlet error" do
        let(:lcm_standard_output) { "some output" }
        let(:lcm_standard_error) { "Abort, Retry, Fail?" }
        let(:lcm_cmdlet_success) { false }

        it "should log a warning" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          expect(lcm).to receive(:dsc_module_import_failure?).and_call_original
          expect { lcm.test_configuration("config", {}) }.not_to raise_error
        end
      end
    end

    it "should identify a correctly formatted error message as a resource import failure" do
      expect(lcm.send(:dsc_module_import_failure?, dsc_resource_import_failure_output)).to be(true)
    end

    it "should not identify an incorrectly formatted error message as a resource import failure" do
      expect(lcm.send(:dsc_module_import_failure?, dsc_resource_import_failure_output.gsub("module", "gibberish"))).to be(false)
    end

    it "should not identify a message without a CimException reference as a resource import failure" do
      expect(lcm.send(:dsc_module_import_failure?, dsc_resource_import_failure_output.gsub("CimException", "ArgumentException"))).to be(false)
    end
  end

  describe "#run_configuration_cmdlet" do
    context "when invalid dsc script is given" do
      it "raises exception" do
        configuration_document = "invalid-config"
        shellout_flags = { :cwd => nil, :environment => nil, :timeout => nil }
        expect { lcm.send(:run_configuration_cmdlet, configuration_document, true, shellout_flags) }.to raise_error(Chef::Exceptions::PowershellCmdletException)
      end
    end
  end
end
