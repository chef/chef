#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

# Shared context used by both Powershell and Batch script provider
# tests.

require "chef/platform/query_helpers"

shared_context Chef::Resource::WindowsScript do
  before(:all) do
    @ohai_reader = Ohai::System.new
    @ohai_reader.all_plugins(%w{platform kernel})

    new_node = Chef::Node.new
    new_node.consume_external_attrs(@ohai_reader.data, {})

    events = Chef::EventDispatch::Dispatcher.new

    @run_context = Chef::RunContext.new(new_node, {}, events)
  end

  let(:script_output_path) do
    File.join(Dir.tmpdir, make_tmpname("windows_script_test"))
  end

  before(:each) do
    File.delete(script_output_path) if File.exists?(script_output_path)
  end

  after(:each) do
    File.delete(script_output_path) if File.exists?(script_output_path)
  end

  let!(:resource) do
    Chef::Resource::WindowsScript::Batch.new("Batch resource functional test", @run_context)
  end

  shared_examples_for "a script resource with architecture attribute" do
    context "with the given architecture attribute value" do
      let(:expected_architecture) do
        if resource_architecture
          expected_architecture = resource_architecture
        else
          expected_architecture = @ohai_reader.data["kernel"]["machine"].to_sym
        end
      end
      let(:expected_architecture_output) do
        expected_architecture == :i386 ? "X86" : "AMD64"
      end
      let(:guard_script_suffix) do
        "guard"
      end
      let(:guard_script_output_path) do
        "#{script_output_path}#{guard_script_suffix}"
      end
      let(:resource_command) do
        "#{architecture_command} #{output_command} #{script_output_path}"
      end
      let(:resource_guard_command) do
        "#{architecture_command} #{output_command} #{guard_script_output_path}"
      end

      before(:each) do
        resource.code resource_command
        (resource.architecture resource_architecture) if resource_architecture
        resource.returns(0)
      end

      it "creates a process with the expected architecture" do
        resource.run_action(:run)
        expect(get_process_architecture).to eq(expected_architecture_output.downcase)
      end

      it "executes guards with the same architecture as the resource" do
        resource.only_if resource_guard_command
        resource.run_action(:run)
        expect(get_process_architecture).to eq(expected_architecture_output.downcase)
        expect(get_guard_process_architecture).to eq(expected_architecture_output.downcase)
        expect(get_guard_process_architecture).to eq(get_process_architecture)
      end

      context "when the guard's architecture is specified as 64-bit" do
        let (:guard_architecture) { :x86_64 }
        it "executes a 64-bit guard", :windows64_only do
          resource.only_if resource_guard_command, :architecture => guard_architecture
          resource.run_action(:run)
          expect(get_guard_process_architecture).to eq("amd64")
        end
      end

      context "when the guard's architecture is specified as 32-bit", :not_supported_on_nano do
        let (:guard_architecture) { :i386 }
        it "executes a 32-bit guard" do
          resource.only_if resource_guard_command, :architecture => guard_architecture
          resource.run_action(:run)
          expect(get_guard_process_architecture).to eq("x86")
        end
      end

      context "when the guard's architecture is specified as 32-bit", :windows_nano_only do
        let (:guard_architecture) { :i386 }
        it "raises an error" do
          resource.only_if resource_guard_command, :architecture => guard_architecture
          expect { resource.run_action(:run) }.to raise_error(
            Chef::Exceptions::Win32ArchitectureIncorrect,
            /cannot execute script with requested architecture 'i386' on Windows Nano Server/)
        end
      end
    end
  end

  shared_examples_for "a Windows script running on Windows" do

    describe "when the run action is invoked on Windows" do
      it "executes the script code" do
        resource.code("whoami > \"#{script_output_path}\"")
        resource.returns(0)
        resource.run_action(:run)
      end
    end

    context "when $env:TMP has a space" do
      before(:each) do
        @dir = Dir.mktmpdir("Jerry Smith")
        @original_env = ENV.to_hash.dup
        ENV.delete("TMP")
        ENV["TMP"] = @dir
      end

      after(:each) do
        FileUtils.remove_entry_secure(@dir)
        ENV.clear
        ENV.update(@original_env)
      end

      it "executes the script code" do
        resource.code("whoami > \"#{script_output_path}\"")
        resource.returns(0)
        resource.run_action(:run)
      end
    end

    context "when evaluating guards" do
      it "has a guard_interpreter attribute set to the short name of the resource" do
        pending "powershell.exe always exits with 0 on nano" if Chef::Platform.windows_nano_server?

        expect(resource.guard_interpreter).to eq(resource.resource_name)
        resource.not_if "findstr.exe /thiscommandhasnonzeroexitstatus"
        expect(Chef::Resource).to receive(:resource_for_node).and_call_original
        expect(resource.class).to receive(:new).and_call_original
        expect(resource.should_skip?(:run)).to be_falsey
      end
    end

    context "when the architecture attribute is not set" do
      let(:resource_architecture) { nil }
      it_behaves_like "a script resource with architecture attribute"
    end

    context "when the architecture attribute is :i386", :not_supported_on_nano do
      let(:resource_architecture) { :i386 }
      it_behaves_like "a script resource with architecture attribute"
    end

    context "when the architecture attribute is :x86_64" do
      let(:resource_architecture) { :x86_64 }
      it_behaves_like "a script resource with architecture attribute"
    end
  end

  def get_windows_script_output(suffix = "")
    File.read("#{script_output_path}#{suffix}")
  end

  def source_contains_case_insensitive_content?( source, content )
    source.downcase.include?(content.downcase)
  end

  def get_guard_process_architecture
    get_process_architecture(guard_script_suffix)
  end

  def get_process_architecture(suffix = "")
    get_windows_script_output(suffix).strip.downcase
  end

end
