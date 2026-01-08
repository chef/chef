#
# Author:: Adam Jacob (adam@chef.io)
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

describe Chef::Provider::Batch do
  let(:node) do
    node = Chef::Node.new
    node.default["kernel"] = {}
    node.default["kernel"][:machine] = :x86_64.to_s
    node
  end

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:new_resource) do
    new_resource = Chef::Resource::Batch.new("cmd.exe and conquer")
    new_resource.code %q{echo "hello"}
    new_resource
  end

  let(:provider) { Chef::Provider::Batch.new(new_resource, run_context) }

  context "#grant_alternate_user_read_access" do
    before do
      allow(ChefUtils).to receive(:windows?).and_return(true)
      stub_const("Chef::ReservedNames::Win32::API::Security::GENERIC_READ", 1)
      stub_const("Chef::ReservedNames::Win32::API::Security::GENERIC_EXECUTE", 4)
      stub_const("Chef::ReservedNames::Win32::Security", Class.new)
      stub_const("Chef::ReservedNames::Win32::Security::SecurableObject", Class.new)
      stub_const("Chef::ReservedNames::Win32::Security::SID", Class.new)
      stub_const("Chef::ReservedNames::Win32::Security::ACE", Class.new)
      stub_const("Chef::ReservedNames::Win32::Security::ACL", Class.new)

      provider.singleton_class.send(:public, :grant_alternate_user_read_access)
    end

    context "when an alternate user is not specified" do
      it "does not attempt to set the script file's security descriptor" do
        expect(provider).to receive(:grant_alternate_user_read_access)
        expect(Chef::ReservedNames::Win32::Security::SecurableObject).not_to receive(:new)
        provider.grant_alternate_user_read_access("a fake path")
      end
    end

    context "when an alternate user is specified" do
      let(:security_descriptor) { instance_double("Chef::ReservedNames::Win32::Security::SecurityDescriptor", dacl: []) }
      let(:securable_object) { instance_double("Chef::ReservedNames::Win32::Security::SecurableObject", :security_descriptor => security_descriptor, :dacl= => nil) }

      it "sets the script file's security descriptor" do
        new_resource.user("toor")
        expect(Chef::ReservedNames::Win32::Security::SecurableObject).to receive(:new).and_return(securable_object)
        expect(Chef::ReservedNames::Win32::Security::SID).to receive(:from_account).and_return(nil)
        expect(Chef::ReservedNames::Win32::Security::ACE).to receive(:access_allowed).and_return(nil)
        expect(Chef::ReservedNames::Win32::Security::ACL).to receive(:create).and_return(nil)
        expect(securable_object).to receive(:dacl=)
        provider.grant_alternate_user_read_access("a fake path")
      end
    end
  end

  describe "#with_temp_script_file" do
    before do
      provider.singleton_class.send(:public, :with_temp_script_file)
      provider.singleton_class.send(:public, :script_file_path)
    end

    it "should put the contents of the script in the temp file" do
      temp_file_contents = nil

      provider.with_temp_script_file do
        temp_file_contents = File.read(provider.script_file_path)
      end

      expect(temp_file_contents.strip).to eq(%q{echo "hello"})
    end
  end

  describe "#command" do
    let(:basepath) { "C:\\Windows\\system32\\" }
    let(:interpreter) { File.join(basepath, "cmd.exe") }

    before do
      allow(provider).to receive(:basepath).and_return(basepath)
      provider.singleton_class.send(:public, :with_temp_script_file)
      provider.singleton_class.send(:public, :script_file_path)
    end

    it 'should set the command to "interpreter"  "tempfile"' do
      command = nil
      script_file_path = nil
      provider.with_temp_script_file do
        command = provider.command
        script_file_path = provider.script_file_path
      end

      expect(command).to eq(%Q{"#{interpreter}"  /c "#{script_file_path}"})
    end

    it "should set the command to 'interpreter flags tempfile'" do
      new_resource.flags "/f"

      command = nil
      script_file_path = nil
      provider.with_temp_script_file do
        command = provider.command
        script_file_path = provider.script_file_path
      end

      expect(command).to eq(%Q{"#{interpreter}" /f /c "#{script_file_path}"})
    end
  end
end
