#
# Author:: Jay Mundrawala (<jdm@chef.io>)
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

describe Chef::Resource::DscResource, :windows_powershell_dsc_only do
  let(:event_dispatch) { Chef::EventDispatch::Dispatcher.new }

  let(:node) do
    Chef::Node.new.tap do |n|
      n.consume_external_attrs(OHAI_SYSTEM.data, {})
    end
  end

  let(:run_context) { Chef::RunContext.new(node, {}, event_dispatch) }

  let(:new_resource) do
    Chef::Resource::DscResource.new("dsc_resource_test", run_context)
  end

  it "requires PowerShell DLLs and runtimes to be present" do
    unless chef_powershell_gem_available?
      raise <<~ERROR

        ╔═══════════════════════════════════════════════════════════════════════════╗
        ║                          CRITICAL TEST FAILURE                            ║
        ╠═══════════════════════════════════════════════════════════════════════════╣
        ║                                                                           ║
        ║  PowerShell execution environment is NOT available!                       ║
        ║                                                                           ║
        ║  Required components missing:                                             ║
        ║    - chef-powershell gem and/or                                           ║
        ║    - Chef.PowerShell.dll and/or                                           ║
        ║    - vcruntime140.dll (Visual C++ Runtime)                                ║
        ║                                                                           ║
        ║  DSC resource tests CANNOT run without these dependencies.                ║
        ║                                                                           ║
        ║  Please ensure all required PowerShell runtime components are installed.  ║
        ║                                                                           ║
        ╚═══════════════════════════════════════════════════════════════════════════╝

      ERROR
    end
  end

  context "when PowerShell DLLs are missing (mocked)" do
    it "fails with a clear error message" do
      allow(self).to receive(:powershell_exec_available?).and_return(false)

      expect {
        unless powershell_exec_available?
          raise "PowerShell execution environment is NOT available!"
        end
      }.to raise_error(RuntimeError, /PowerShell execution environment is NOT available/)
    end
  end

  context "when PowerShell does not support Invoke-DscResource"
  context "when PowerShell supports Invoke-DscResource" do
    before do
      if !Chef::Platform.supports_dsc_invoke_resource?(node)
        skip "Requires PowerShell >= 5.0.10018.0"
      elsif !Chef::Platform.supports_refresh_mode_enabled?(node) && !Chef::Platform.dsc_refresh_mode_disabled?(node)
        skip "Requires LCM RefreshMode is Disabled"
      end
    end
    context "with an invalid dsc resource" do
      it "raises an exception if the resource is not found" do
        new_resource.resource "thisdoesnotexist"
        expect { new_resource.run_action(:run) }.to raise_error(
          Chef::Exceptions::ResourceNotFound
        )
      end
    end

    context "with a valid dsc resource" do
      let(:tmp_file_name) { Dir::Tmpname.create("tmpfile") {} }
      let(:test_text) { "'\"!@#$%^&*)(}{][\u2713~n" }

      before do
        new_resource.resource :File
        new_resource.property :Contents, test_text
        new_resource.property :DestinationPath, tmp_file_name
      end

      after do
        File.delete(tmp_file_name) if File.exist? tmp_file_name
      end

      it "converges the resource if it is not converged" do
        new_resource.run_action(:run)
        contents = File.open(tmp_file_name, "rb:bom|UTF-16LE") do |f|
          f.read.encode("UTF-8")
        end
        expect(contents).to eq(test_text)
        expect(new_resource).to be_updated
      end

      it "does not converge the resource if it is already converged" do
        new_resource.run_action(:run)
        expect(new_resource).to be_updated
        reresource =
          Chef::Resource::DscResource.new("dsc_resource_retest", run_context)
        reresource.resource :File
        reresource.property :Contents, test_text
        reresource.property :DestinationPath, tmp_file_name
        reresource.run_action(:run)
        expect(reresource).not_to be_updated
      end
    end

  end
end
