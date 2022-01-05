#
# Author:: Stuart Preston (<stuart@chef.io>)
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

require "spec_helper"
require "chef/mixin/powershell_exec"

describe Chef::Mixin::PowershellExec, :windows_only do
  let(:powershell_mixin) { Class.new { include Chef::Mixin::PowershellExec } }
  subject(:object) { powershell_mixin.new }

  describe "#powershell_exec" do
    context "not specifying an interpreter" do
      it "runs a basic command and returns a Chef::PowerShell object" do
        expect(object.powershell_exec("$PSVersionTable")).to be_kind_of(Chef_PowerShell::PowerShell)
      end

      it "uses less than version 6" do
        execution = object.powershell_exec("$PSVersionTable")
        expect(execution.result["PSVersion"].to_s.to_i).to be < 6
      end
    end

    context "using pwsh interpreter" do
      it "runs a basic command and returns a Chef::PowerShell object" do
        expect(object.powershell_exec("$PSVersionTable", :pwsh)).to be_kind_of(Chef_PowerShell::Pwsh)
      end

      it "uses greater than version 6" do
        execution = object.powershell_exec("$PSVersionTable", :pwsh)
        expect(execution.result["PSVersion"]["Major"]).to be > 6
      end
    end

    context "using powershell interpreter" do
      it "runs a basic command and returns a Chef::PowerShell object" do
        expect(object.powershell_exec("$PSVersionTable", :powershell)).to be_kind_of(Chef_PowerShell::PowerShell)
      end

      it "uses less than version 6" do
        execution = object.powershell_exec("$PSVersionTable", :powershell)
        expect(execution.result["PSVersion"].to_s.to_i).to be < 6
      end
    end

    it "runs a command that fails with a non-terminating error and can trap the error via .error?" do
      execution = object.powershell_exec("this-should-error")
      expect(execution.error?).to eql(true)
    end

    it "runs a command that fails with a non-terminating error and can list the errors" do
      execution = object.powershell_exec("this-should-error")
      expect(execution.errors).to be_a_kind_of(Array)
      expect(execution.errors[0]).to be_a_kind_of(String)
      expect(execution.errors[0]).to include("The term 'this-should-error' is not recognized")
    end

    it "raises an error if the interpreter is invalid" do
      expect { object.powershell_exec("this-should-error", :powerfart) }.to raise_error(ArgumentError)
    end
  end

  describe "#powershell_exec!" do
    it "runs a basic command and returns a Chef::PowerShell object" do
      expect(object.powershell_exec!("$PSVersionTable")).to be_kind_of(Chef_PowerShell::PowerShell)
    end

    it "raises an error if the command fails" do
      expect { object.powershell_exec!("this-should-error") }.to raise_error(Chef_PowerShell::PowerShellExceptions::PowerShellCommandFailed)
    end

    it "raises an error if the interpreter is invalid" do
      expect { object.powershell_exec!("this-should-error", :powerfart) }.to raise_error(ArgumentError)
    end
  end
end
