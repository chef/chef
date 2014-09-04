#
# Author:: Adam Edwards <adamed@getchef.com>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef'
require 'chef/util/dsc/local_configuration_manager'

describe Chef::Util::DSC::LocalConfigurationManager do

  let(:lcm) { Chef::Util::DSC::LocalConfigurationManager.new(nil, 'tmp') }

  let(:normal_lcm_output) { <<-EOH
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ] [name]
logtype: [machinename]: LCM:  [ End    Resource ] [name]
logtype: [machinename]: LCM:  [ End    Set      ]
EOH
  }

  let(:no_whatif_lcm_output) { <<-EOH
Start-DscConfiguration : A parameter cannot be found that matches parameter name 'whatif'.
At line:1 char:123
+ run-somecommand -whatif
+                        ~~~~~~~~
    + CategoryInfo          : InvalidArgument: (:) [Start-DscConfiguration], ParameterBindingException
    + FullyQualifiedErrorId : NamedParameterNotFound,SomeCompany.SomeAssembly.Commands.RunSomeCommand
EOH
  }

  let(:dsc_resource_import_failure_output) { <<-EOH
PowerShell provider MSFT_xWebsite failed to execute Test-TargetResource functionality with error message: Please ensure that WebAdministration module is installed. + CategoryInfo : InvalidOperation: (:) [], CimException + FullyQualifiedErrorId : ProviderOperationExecutionFailure + PSComputerName : . PowerShell provider MSFT_xWebsite failed to execute Test-TargetResource functionality with error message: Please ensure that WebAdministration module is installed. + CategoryInfo : InvalidOperation: (:) [], CimException + FullyQualifiedErrorId : ProviderOperationExecutionFailure + PSComputerName : . The SendConfigurationApply function did not succeed. + CategoryInfo : NotSpecified: (root/Microsoft/...gurationManager:String) [], CimException + FullyQualifiedErrorId : MI RESULT 1 + PSComputerName : .
EOH
  }

  let(:lcm_status) {
    double("LCM cmdlet status", :stderr => lcm_standard_error, :return_value => lcm_standard_output, :succeeded? => lcm_cmdlet_success)
  }

  describe 'test_configuration method invocation' do
    context 'when interacting with the LCM using a PowerShell cmdlet' do
      before(:each) do
        allow(lcm).to receive(:run_configuration_cmdlet).and_return(lcm_status)
      end
      context 'that returns successfully' do
        before(:each) do
          allow(lcm).to receive(:run_configuration_cmdlet).and_return(lcm_status)
        end

        let(:lcm_standard_output) { normal_lcm_output }
        let(:lcm_standard_error) { nil }
        let(:lcm_cmdlet_success) { true }

        it 'should successfully return resource information for normally formatted output when cmdlet the cmdlet succeeds' do
          test_configuration_result = lcm.test_configuration('config')
          expect(test_configuration_result.class).to be(Array)
          expect(test_configuration_result.length).to be > 0
          expect(Chef::Log).not_to receive(:warn)
        end
      end

      context 'that fails due to missing what-if switch in DSC resource cmdlet implementation' do
        let(:lcm_standard_output) { '' }
        let(:lcm_standard_error) { no_whatif_lcm_output }
        let(:lcm_cmdlet_success) { false }

        it 'should should return a (possibly empty) array of ResourceInfo instances' do
          expect(Chef::Log).to receive(:warn)
          test_configuration_result = nil
          expect {test_configuration_result = lcm.test_configuration('config')}.not_to raise_error
          expect(test_configuration_result.class).to be(Array)
        end
      end

      context 'that fails due to a DSC resource not being imported before StartDSCConfiguration -whatif is executed' do
        let(:lcm_standard_output) { '' }
        let(:lcm_standard_error) { dsc_resource_import_failure_output }
        let(:lcm_cmdlet_success) { false }

        it 'should log a warning if the message is formatted as expected when a resource import failure occurs' do
          expect(Chef::Log).to receive(:warn)
          expect(lcm).to receive(:output_has_dsc_module_failure?).and_call_original
          test_configuration_result = nil
          expect {test_configuration_result = lcm.test_configuration('config')}.not_to raise_error
        end

        it 'should return a (possibly empty) array of ResourceInfo instances' do
          expect(Chef::Log).to receive(:warn)
          test_configuration_result = nil
          expect {test_configuration_result = lcm.test_configuration('config')}.not_to raise_error
          expect(test_configuration_result.class).to be(Array)
        end
      end

      context 'that fails due to an PowerShell cmdlet error that cannot be handled' do
        let(:lcm_standard_output) { 'some output' }
        let(:lcm_standard_error) { 'Abort, Retry, Fail?' }
        let(:lcm_cmdlet_success) { false }

        it 'should raise a Chef::Exceptions::PowershellCmdletException' do
          expect(Chef::Log).not_to receive(:warn)
          expect(lcm).to receive(:output_has_dsc_module_failure?).and_call_original
          expect {lcm.test_configuration('config')}.to raise_error(Chef::Exceptions::PowershellCmdletException)
        end
      end
    end

    it 'should identify a correctly formatted error message as a resource import failure' do
      expect(lcm.send(:output_has_dsc_module_failure?, dsc_resource_import_failure_output)).to be(true)
    end

    it 'should not identify an incorrectly formatted error message as a resource import failure' do
      expect(lcm.send(:output_has_dsc_module_failure?, dsc_resource_import_failure_output.gsub('module', 'gibberish'))).to be(false)
    end

    it 'should not identify a message without a CimException reference as a resource import failure' do
      expect(lcm.send(:output_has_dsc_module_failure?, dsc_resource_import_failure_output.gsub('CimException', 'ArgumentException'))).to be(false)
    end
  end
end

