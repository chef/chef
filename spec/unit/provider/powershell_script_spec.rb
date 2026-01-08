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
describe Chef::Provider::PowershellScript, "action_run", windows_only: true do
  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) {
    @node = Chef::Node.new
    @node.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
    Chef::RunContext.new(@node, {}, events)
  }

  let(:new_resource) do
    Chef::Resource::PowershellScript.new("run some powershell code", run_context)
  end

  let(:provider) do
    Chef::Provider::PowershellScript.new(new_resource, run_context)
  end

  describe "#command" do
    before(:each) do
      allow(provider).to receive(:basepath).and_return("C:\\Windows\\system32")
      allow(ChefUtils).to receive(:windows?).and_return(true)
    end

    it "includes the user's flags after the default flags when building the command" do
      new_resource.flags = "-InputFormat Fabulous"
      provider.send(:script_file_path=, "C:\\Temp\\Script.ps1")

      expected = <<~CMD.strip
        "C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -InputFormat None -InputFormat Fabulous -File "C:\\Temp\\Script.ps1"
      CMD

      expect(provider.send(:command)).to eq(expected)
    end

    it "uses pwsh when given the pwsh interpreter" do
      new_resource.interpreter = "pwsh"
      provider.send(:script_file_path=, "C:\\Temp\\Script.ps1")

      expected = <<~CMD.strip
        "pwsh" -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -InputFormat None  -File "C:\\Temp\\Script.ps1"
      CMD

      expect(provider.send(:command)).to eq(expected)
    end

    it "returns the script specific to the inline interpreter when using use_inline_interpreter" do
      new_resource.code = "test script"
      new_resource.use_inline_powershell = true
      # This is a string that is ONLY in the use_inline_interpreter version of this
      expect(provider.send(:powershell_wrapper_script)).to include("$interpolatedexitcode = $")
    end

    it "returns the script specific to the normal interpreter when not using use_inline_interpreter" do
      new_resource.code = "test script"
      new_resource.use_inline_powershell = false
      # This is a string that is ONLY in the non use_inline_interpreter version of this
      expect(provider.send(:powershell_wrapper_script)).to include("new-variable -name interpolatedexitcode -visibility private")
    end

    it "Correctly returns for $True for regular powershell" do
      new_resource.code = "$True"
      new_resource.use_inline_powershell = false
      new_resource.convert_boolean_return = true
      expect(provider.run_action(:run)).to eq(nil)
    end

    it "Correctly returns for $True for inline powershell with convert_boolean_return" do
      new_resource.code = "$True"
      new_resource.use_inline_powershell = true
      new_resource.convert_boolean_return = true
      expect(provider.run_action(:run)).to eq(nil)
    end

    it "Correctly throws exception for $False for regular powershell" do
      new_resource.code = "$False"
      new_resource.use_inline_powershell = false
      new_resource.convert_boolean_return = true
      expect { provider.run_action(:run) }.to raise_error(an_instance_of(Mixlib::ShellOut::ShellCommandFailed))
    end

    it "Correctly throws exception for $False for inline powershell" do
      new_resource.code = "$False"
      new_resource.use_inline_powershell = true
      new_resource.convert_boolean_return = true
      expect { provider.run_action(:run) }.to raise_error(an_instance_of(ChefPowerShell::PowerShellExceptions::PowerShellCommandFailed))
    end

    it "return 1 fails correctly for non-inline" do
      new_resource.code = "return 1"
      new_resource.use_inline_powershell = false
      expect { provider.run_action(:run) }.to raise_error(an_instance_of(Mixlib::ShellOut::ShellCommandFailed))
    end

    it "return 1 fails correctly for inline" do
      new_resource.code = "return 1"
      new_resource.use_inline_powershell = true
      expect { provider.run_action(:run) }.to raise_error(an_instance_of(ChefPowerShell::PowerShellExceptions::PowerShellCommandFailed))
    end

    it "return 1 is valid when returns includes 1 for non-inline" do
      new_resource.code = "return 1"
      new_resource.use_inline_powershell = false
      new_resource.returns = [1]
      expect(provider.run_action(:run)).to eq(nil)
    end
    it "return 1 is valid when returns includes 1 for inline" do
      new_resource.code = "return 1"
      new_resource.use_inline_powershell = true
      new_resource.returns = [1]
      expect(provider.run_action(:run)).to eq(nil)
    end

    it "bad powershell exceptions for non-inline" do
      new_resource.code = "xyzzy"
      new_resource.use_inline_powershell = false
      expect { provider.run_action(:run) }.to raise_error(an_instance_of(Mixlib::ShellOut::ShellCommandFailed))
    end

    it "bad powershell exceptions for inline" do
      new_resource.code = "xyzzy"
      new_resource.use_inline_powershell = true
      expect { provider.run_action(:run) }.to raise_error(an_instance_of(ChefPowerShell::PowerShellExceptions::PowerShellCommandFailed))
    end

    it "uses powershell for inline by default" do
      new_resource.code = "$host.version.major -lt 7"
      new_resource.use_inline_powershell = true
      expect(provider.run_action(:run)).to eq(nil)
    end

    it "uses pwsh for inline when asked" do
      new_resource.code = "$host.version.major -ge 7"
      new_resource.use_inline_powershell = true
      new_resource.interpreter = "pwsh"
      expect(provider.run_action(:run)).to eq(nil)
    end
  end
end
