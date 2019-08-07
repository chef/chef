#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2013-2017, Chef Software Inc.
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
describe Chef::Provider::PowershellScript, "action_run" do

  let(:powershell_version) { nil }
  let(:node) do
    node = Chef::Node.new
    node.default["kernel"] = {}
    node.default["kernel"][:machine] = :x86_64.to_s
    unless powershell_version.nil?
      node.default[:languages] = { powershell: { version: powershell_version } }
    end
    node
  end

  # code block is mandatory for the powershell provider
  let(:code) { "" }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { run_context = Chef::RunContext.new(node, {}, events) }

  let(:new_resource) do
    new_resource = Chef::Resource::PowershellScript.new("run some powershell code", run_context)
    new_resource.code code
    new_resource
  end

  def set_user_defined_flag
    new_resource.flags "-ExecutionPolicy RemoteSigned"
    provider
  end

  let(:provider) do
    Chef::Provider::PowershellScript.new(new_resource, run_context)
  end

  context "when setting interpreter flags" do
    context "on nano" do
      before(:each) do
        allow(Chef::Platform).to receive(:windows_nano_server?).and_return(true)
        allow(provider).to receive(:is_forced_32bit).and_return(false)
        os_info_double = double("os_info")
        allow(provider.run_context.node["kernel"]).to receive(:[]).with("os_info").and_return(os_info_double)
        allow(os_info_double).to receive(:[]).with("system_directory").and_return("C:\\Windows\\system32")
      end

      it "sets the -Command flag as the last flag" do
        flags = provider.command.split(" ").keep_if { |flag| flag =~ /^-/ }
        expect(flags.pop).to eq("-Command")
      end
    end

    context "not on nano" do
      before(:each) do
        allow(Chef::Platform).to receive(:windows_nano_server?).and_return(false)
        allow(provider).to receive(:is_forced_32bit).and_return(false)
        os_info_double = double("os_info")
        allow(provider.run_context.node["kernel"]).to receive(:[]).with("os_info").and_return(os_info_double)
        allow(os_info_double).to receive(:[]).with("system_directory").and_return("C:\\Windows\\system32")
      end

      it "sets the -File flag as the last flag" do
        flags = provider.command.split(" ").keep_if { |flag| flag =~ /^-/ }
        expect(flags.pop).to eq("-File")
      end

      let(:execution_policy_flag) do
        provider_flags = provider.flags.split(" ")
        # Last occurance of "executionpolicy"
        execution_policy_index = provider_flags.map(&:downcase).rindex("-executionpolicy")

        execution_policy_index ? provider_flags[execution_policy_index + 1] : nil
      end

      context "when running with an unspecified PowerShell version" do
        let(:powershell_version) { nil }
        it "sets default -ExecutionPolicy flag to 'Unrestricted'" do
          expect(execution_policy_flag.downcase).to eq("unrestricted".downcase)
        end
        it "sets user defined -ExecutionPolicy flag to 'RemoteSigned'" do
          set_user_defined_flag
          expect(execution_policy_flag.downcase).to eq("RemoteSigned".downcase)
        end
      end

      { "2.0" => "Unrestricted",
        "2.5" => "Unrestricted",
        "3.0" => "Bypass",
        "3.6" => "Bypass",
        "4.0" => "Bypass",
        "5.0" => "Bypass" }.each do |version_policy|
          let(:powershell_version) { version_policy[0].to_f }
          context "when running PowerShell version #{version_policy[0]}" do
            let(:powershell_version) { version_policy[0].to_f }

            it "sets default -ExecutionPolicy flag to '#{version_policy[1]}'" do
              expect(execution_policy_flag.downcase).to eq(version_policy[1].downcase)
            end
            it "sets user defined -ExecutionPolicy flag to 'RemoteSigned'" do
              set_user_defined_flag
              expect(execution_policy_flag.downcase).to eq("RemoteSigned".downcase)
            end
          end
        end
    end
  end
end
