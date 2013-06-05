#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'spec_helper'

unless Chef::Platform.windows?
  class Chef
    module ReservedNames
      module Win32
        module Security
          ACL = Object.new
          SecurableObject = Object.new
        end
      end
    end
  end
end

require 'chef/file_content_management/deploy/mv_windows'

describe Chef::FileContentManagement::Deploy::MvWindows do

  let(:content_deployer) { described_class.new }
  let(:target_file_path) { "/etc/my_app.conf" }

  describe "creating the file" do

    it "touches the file to create it" do
      FileUtils.should_receive(:touch).with(target_file_path)
      content_deployer.create(target_file_path)
    end
  end

  describe "updating the file" do

    let(:staging_file_path) { "/tmp/random-dir/staging-file.tmp" }

    let(:target_file_security_object) do
      mock "Securable Object for target file"
    end

    let(:updated_target_security_object) do
      mock "Securable Object for target file after staging file deploy"
    end

    before do
      Chef::ReservedNames::Win32::Security::SecurableObject.
        stub(:new).
        with(target_file_path).
        and_return(target_file_security_object, updated_target_security_object)

    end

    context "when run without adminstrator privileges" do
      before do
        target_file_security_object.should_receive(:security_descriptor).and_raise(Chef::Exceptions::Win32APIError)
      end

      it "errors out with a WindowsNotAdmin error" do
        lambda { content_deployer.deploy(staging_file_path, target_file_path)}.should raise_error(Chef::Exceptions::WindowsNotAdmin)
      end

    end

    context "when run with administrator privileges" do

      let(:original_target_file_owner) { mock("original target file owner") }
      let(:original_target_file_group) { mock("original target file group") }

      let(:target_file_security_descriptor) do
        mock "security descriptor for target file",
             :group => original_target_file_group,
             :owner => original_target_file_owner
      end

      let(:updated_target_security_descriptor) do
        mock "security descriptor for target file"
      end


      before do
        target_file_security_object.stub(:security_descriptor).and_return(target_file_security_descriptor)

        FileUtils.should_receive(:mv).with(staging_file_path, target_file_path)

        updated_target_security_object.should_receive(:group=).with(original_target_file_group)
        updated_target_security_object.should_receive(:owner=).with(original_target_file_owner)
      end

      context "and the target file has no dacl or sacl" do

        before do
          target_file_security_descriptor.stub(:dacl_present?).and_return(false)
          target_file_security_descriptor.stub(:sacl_present?).and_return(false)
        end

        it "fixes up permissions and moves the file into place" do
          content_deployer.deploy(staging_file_path, target_file_path)
        end

      end

      context "and the target has a dacl and sacl" do
        let(:inherited_dacl_ace) { mock("Windows dacl ace (inherited)", :inherited? => true) }
        let(:not_inherited_dacl_ace) { mock("Windows dacl ace (not inherited)", :inherited? => false) }

        let(:original_target_file_dacl) { [inherited_dacl_ace, not_inherited_dacl_ace] }

        let(:inherited_sacl_ace) { mock("Windows sacl ace (inherited)", :inherited? => true) }
        let(:not_inherited_sacl_ace) { mock("Windows sacl ace (not inherited)", :inherited? => false) }
        let(:original_target_file_sacl) { [inherited_sacl_ace, not_inherited_sacl_ace] }

        let(:custom_dacl) { mock("Windows ACL for non-inherited dacl aces") }
        let(:custom_sacl) { mock("Windows ACL for non-inherited sacl aces") }

        before do
          target_file_security_descriptor.stub(:dacl_present?).and_return(true)
          target_file_security_descriptor.stub(:dacl_inherits?).and_return(dacl_inherits?)

          target_file_security_descriptor.stub(:dacl).and_return(original_target_file_dacl)
          Chef::ReservedNames::Win32::Security::ACL.
            should_receive(:create).
            with([not_inherited_dacl_ace]).
            and_return(custom_dacl)

          target_file_security_descriptor.stub(:sacl_present?).and_return(true)
          target_file_security_descriptor.stub(:sacl_inherits?).and_return(sacl_inherits?)

          target_file_security_descriptor.stub(:sacl).and_return(original_target_file_sacl)
          Chef::ReservedNames::Win32::Security::ACL.
            should_receive(:create).
            with([not_inherited_sacl_ace]).
            and_return(custom_sacl)

          updated_target_security_object.should_receive(:set_dacl).with(custom_dacl, dacl_inherits?)
          updated_target_security_object.should_receive(:set_sacl).with(custom_sacl, sacl_inherits?)
        end

        context "and the dacl and sacl don't inherit" do
          let(:dacl_inherits?) { false }
          let(:sacl_inherits?) { false }

          it "fixes up permissions and moves the file into place" do
            content_deployer.deploy(staging_file_path, target_file_path)
          end
        end

        context "and the dacl and sacl inherit" do
          let(:dacl_inherits?) { true }
          let(:sacl_inherits?) { true }

          it "fixes up permissions and moves the file into place" do
            content_deployer.deploy(staging_file_path, target_file_path)
          end
        end

      end

    end

  end
end


