#
# Author:: Stuart Preston (<stuart@chef.io>)
# Copyright:: Copyright 2018, Chef Software, Inc.
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
    it "runs a basic command and returns a Chef::PowerShell object" do
      expect(object.powershell_exec("$PSVersionTable")).to be_kind_of(Chef::PowerShell)
    end

    it "runs a command that fails with a non-terminating error and can trap the error via .error?" do
      execution = object.powershell_exec("this-should-error")
      expect(execution.error?).to eql(true)
    end

    it "runs a command that fails with a non-terminating error and can list the errors" do
      execution = object.powershell_exec("this-should-error")
      expect(execution.errors).to be_a_kind_of(Array)
      expect(execution.errors[0]).to be_a_kind_of(String)
      expect(execution.errors[0]).to include("Runtime exception: this-should-error")
    end
  end
end
