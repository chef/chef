#
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
if ChefUtils.windows?
  require "chef/win32/api/file"
  require "chef/win32/file"
  require "chef/win32/version"
end

describe Chef::ReservedNames::Win32::File, :windows_only do
  context "#symlink" do
    let(:with_privilege) { Chef::ReservedNames::Win32::API::File::SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE }
    let(:without_privilege) { 0x0 }

    context "an invalid parameter is passed" do
      it "will throw an exception if an invalid parameter is passed" do
        allow(File).to receive(:directory?).and_return(false)
        allow(Chef::ReservedNames::Win32::File).to receive(:encode_path) { |a| a }
        allow_any_instance_of(Chef::ReservedNames::Win32::Version).to receive(:windows_10?).and_return(true)
        allow_any_instance_of(Chef::ReservedNames::Win32::Version).to receive(:build_number).and_return(1)
        allow(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).and_return(nil)

        expect { Chef::ReservedNames::Win32::File.symlink("a", "b") }.to raise_error Chef::Exceptions::Win32APIError
      end
    end

    context "a valid parameter is passed" do
      before(:each) do
        allow(File).to receive(:directory?).and_return(false)
        allow(Chef::ReservedNames::Win32::File).to receive(:encode_path) { |a| a }
        allow(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).with(any_args) { "don't //actually// do this" }
      end

      it "will not pass the unprivileged symlink flag if the node is not Windows 10" do
        allow_any_instance_of(Chef::ReservedNames::Win32::Version).to receive(:windows_10?).and_return(false)

        expect(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).with("b", "a", without_privilege)
        described_class.symlink("a", "b")
      end

      it "will not pass the unprivileged symlink flag if the node is not at least Windows 10 Creators Update" do
        allow_any_instance_of(Chef::ReservedNames::Win32::Version).to receive(:windows_10?).and_return(true)
        allow_any_instance_of(Chef::ReservedNames::Win32::Version).to receive(:build_number).and_return(1)

        expect(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).with("b", "a", without_privilege)
        described_class.symlink("a", "b")
      end

      it "will pass the unprivileged symlink flag if the node is Windows 10 Creators Update or higher" do
        allow_any_instance_of(Chef::ReservedNames::Win32::Version).to receive(:windows_10?).and_return(true)
        allow_any_instance_of(Chef::ReservedNames::Win32::Version).to receive(:build_number).and_return(15063)

        expect(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).with("b", "a", with_privilege)
        described_class.symlink("a", "b")
      end
    end
  end
end
