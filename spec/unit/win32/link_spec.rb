#
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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
if Chef::Platform.windows?
  require "chef/win32/api/file"
  require "chef/win32/file"
end

describe Chef::ReservedNames::Win32::File, :windows_only do
  context "#symlink" do
    let(:with_privilege) { Chef::ReservedNames::Win32::API::File::SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE }
    let(:without_privilege) { 0x0 }

    before(:each) do
      allow(File).to receive(:directory?).and_return(false)
      allow(Chef::ReservedNames::Win32::File).to receive(:encode_path) { |a| a }
      allow(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).with(any_args) { "don't //actually// do this" }
    end

    it "should not create unprivileged symlinks if not enabled in the config file" do
      allow(Chef::Config).to receive(:enable_unprivileged_symlinks).and_return(false)
      expect(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).with("b", "a", without_privilege)
      described_class.symlink("a", "b")
    end

    it "should create unprivileged symlinks if enabled in the config file" do
      allow(Chef::Config).to receive(:enable_unprivileged_symlinks).and_return(true)
      expect(Chef::ReservedNames::Win32::File).to receive(:CreateSymbolicLinkW).with("b", "a", with_privilege)
      described_class.symlink("a", "b")
    end
  end
end
