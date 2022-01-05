#
# Author:: Adam Edwards <adamed@chef.io>
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

require "chef"
require "chef/util/dsc/local_configuration_manager"

describe Chef::Util::DSC::LocalConfigurationManager do

  let(:lcm) { Chef::Util::DSC::LocalConfigurationManager.new(nil, "tmp") }

  let(:normal_lcm_output) do
    <<~EOH
      logtype: [machinename]: LCM:  [ Start  Set      ]
      logtype: [machinename]: LCM:  [ Start  Resource ] [name]
      logtype: [machinename]: LCM:  [ End    Resource ] [name]
      logtype: [machinename]: LCM:  [ End    Set      ]
    EOH
  end

  let(:no_whatif_lcm_output) do
    <<~EOH
      Start-DscConfiguration : A parameter cannot be found\r\n that matches parameter name 'whatif'.
      At line:1 char:123
      + run-somecommand -whatif
      +                        ~~~~~~~~
          + CategoryInfo          : InvalidArgument: (:) [Start-DscConfiguration], ParameterBindingException
          + FullyQualifiedErrorId : NamedParameterNotFound,SomeCompany.SomeAssembly.Commands.RunSomeCommand
    EOH
  end

  let(:dsc_resource_import_failure_output) do
    <<~EOH
      PowerShell provider MSFT_xWebsite failed to execute Test-TargetResource functionality with error message: Please ensure that WebAdministration module is installed. + CategoryInfo : InvalidOperation: (:) [], CimException + FullyQualifiedErrorId : ProviderOperationExecutionFailure + PSComputerName : . PowerShell provider MSFT_xWebsite failed to execute Test-TargetResource functionality with error message: Please ensure that WebAdministration module is installed. + CategoryInfo : InvalidOperation: (:) [], CimException + FullyQualifiedErrorId : ProviderOperationExecutionFailure + PSComputerName : . The SendConfigurationApply function did not succeed. + CategoryInfo : NotSpecified: (root/Microsoft/...gurationManager:String) [], CimException + FullyQualifiedErrorId : MI RESULT 1 + PSComputerName : .
    EOH
  end

  let(:powershell) do
    double("Chef::PowerShell", errors: lcm_errors, error?: !lcm_errors.empty?, result: lcm_result)
  end

  describe "test_configuration method invocation" do
    context "when interacting with the LCM using a PowerShell cmdlet" do
      before(:each) do
        allow(lcm).to receive(:run_configuration_cmdlet).and_return(powershell)
        allow(lcm).to receive(:ps_version_gte_5?).and_return(false)
      end
      context "that returns successfully" do
        let(:lcm_result) { normal_lcm_output }
        let(:lcm_errors) { [] }

        it "successfully returns resource information for normally formatted output when cmdlet the cmdlet succeeds" do
          test_configuration_result = lcm.test_configuration("config")
          expect(test_configuration_result.class).to be(Array)
          expect(test_configuration_result.length).to be > 0
          expect(Chef::Log).not_to receive(:warn)
        end
      end

      context "when running on PowerShell version 5" do
        let(:lcm_result) { normal_lcm_output }
        let(:lcm_errors) { [] }

        it "successfully returns resource information for normally formatted output when cmdlet the cmdlet succeeds" do
          allow(lcm).to receive(:ps_version_gte_5?).and_return(true)
          test_configuration_result = lcm.test_configuration("config")
          expect(test_configuration_result.class).to be(Array)
          expect(test_configuration_result.length).to be > 0
          expect(Chef::Log).not_to receive(:warn)
        end
      end

      context "when running on PowerShell version less than 5" do
        let(:lcm_result) { normal_lcm_output }
        let(:lcm_errors) { [] }

        it "successfully returns resource information for normally formatted output when cmdlet the cmdlet succeeds" do
          allow(lcm).to receive(:ps_version_gte_5?).and_return(false)
          test_configuration_result = lcm.test_configuration("config")
          expect(test_configuration_result.class).to be(Array)
          expect(test_configuration_result.length).to be > 0
          expect(Chef::Log).not_to receive(:warn)
        end
      end

      context "#lcm_command" do
        let(:common_command_prefix) { "$ProgressPreference = 'SilentlyContinue';" }
        let(:ps4_base_command) { "#{common_command_prefix} Start-DscConfiguration -path tmp -wait -erroraction 'stop' -force" }
        let(:lcm_command_ps4) { ps4_base_command + " -whatif; if (! $?) { exit 1 }" }
        let(:lcm_command_ps5) { "#{common_command_prefix} Test-DscConfiguration -path tmp | format-list | Out-String" }
        let(:lcm_result) { normal_lcm_output }
        let(:lcm_errors) { [] }

        it "successfully returns command when apply_configuration true" do
          expect(lcm.send(:lcm_command, true)).to eq(ps4_base_command)
        end

        it "successfully returns command when PowerShell version 4" do
          allow(lcm).to receive(:ps_version_gte_5?).and_return(false)
          expect(lcm.send(:lcm_command, false)).to eq(lcm_command_ps4)
        end

        it "successfully returns command when PowerShell version 5" do
          allow(lcm).to receive(:ps_version_gte_5?).and_return(true)
          expect(lcm.send(:lcm_command, false)).to eq(lcm_command_ps5)
        end
      end

      context "that fails due to missing what-if switch in DSC resource cmdlet implementation" do
        let(:lcm_result) { "" }
        let(:lcm_errors) { [no_whatif_lcm_output] }

        it "returns true when passed to #whatif_not_supported?" do
          expect(lcm.send(:whatif_not_supported?, no_whatif_lcm_output)).to be_truthy
        end

        it "returns a (possibly empty) array of ResourceInfo instances" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          expect(lcm).to receive(:whatif_not_supported?).and_call_original
          test_configuration_result = nil
          expect { test_configuration_result = lcm.test_configuration("config") }.not_to raise_error
          expect(test_configuration_result.class).to be(Array)
        end
      end

      context "that fails due to a DSC resource not being imported before StartDSCConfiguration -whatif is executed" do
        let(:lcm_result) { "" }
        let(:lcm_errors) { [dsc_resource_import_failure_output] }

        it "logs a warning if the message is formatted as expected when a resource import failure occurs" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          expect(lcm).to receive(:dsc_module_import_failure?).and_call_original
          test_configuration_result = nil
          expect { test_configuration_result = lcm.test_configuration("config") }.not_to raise_error
        end

        it "returns a (possibly empty) array of ResourceInfo instances" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          test_configuration_result = nil
          expect { test_configuration_result = lcm.test_configuration("config") }.not_to raise_error
          expect(test_configuration_result.class).to be(Array)
        end
      end

      context "that fails due to an unknown PowerShell cmdlet error" do
        let(:lcm_result) { "some output" }
        let(:lcm_errors) { ["Abort, Retry, Fail?"] }

        it "logs a warning" do
          expect(Chef::Log).to receive(:warn).at_least(:once)
          expect(lcm).to receive(:dsc_module_import_failure?).and_call_original
          expect { lcm.test_configuration("config") }.not_to raise_error
        end
      end
    end

    it "identify a correctly formatted error message as a resource import failure" do
      expect(lcm.send(:dsc_module_import_failure?, dsc_resource_import_failure_output)).to be(true)
    end

    it "does not identify an incorrectly formatted error message as a resource import failure" do
      expect(lcm.send(:dsc_module_import_failure?, dsc_resource_import_failure_output.gsub("module", "gibberish"))).to be(false)
    end

    it "does not identify a message without a CimException reference as a resource import failure" do
      expect(lcm.send(:dsc_module_import_failure?, dsc_resource_import_failure_output.gsub("CimException", "ArgumentException"))).to be(false)
    end
  end

  describe "#run_configuration_cmdlet", :windows_powershell_dsc_only do
    context "when invalid dsc script is given" do
      it "raises exception" do
        configuration_document = "invalid-config"
        expect { lcm.send(:run_configuration_cmdlet, configuration_document, true) }.to raise_error(Chef_PowerShell::PowerShellExceptions::PowerShellCommandFailed)
      end
    end
  end
end
