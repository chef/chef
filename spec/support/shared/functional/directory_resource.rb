#
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

shared_examples_for "a directory resource" do

  include_context "diff disabled"

  let(:expect_updated?) { true }

  context "when the target directory does not exist" do
    before do
      # assert pre-condition
      expect(File).not_to exist(path)
    end

    describe "when running action :create" do
      context "and the recursive option is not set" do
        before do
          resource.run_action(:create)
        end

        it "creates the directory when the :create action is run" do
          expect(File).to exist(path)
        end

        it "is marked updated by last action" do
          expect(resource).to be_updated_by_last_action
        end
      end

      context "and the recursive option is set" do
        before do
          expect(File).not_to exist(path)

          resource.recursive(true)
          @recursive_path = File.join(path, "red-headed-stepchild")
          resource.path(@recursive_path)
          resource.run_action(:create)
        end

        it "recursively creates required directories" do
          expect(File).to exist(path)
          expect(File).to exist(@recursive_path)
        end

        it "is marked updated by last action" do
          expect(resource).to be_updated_by_last_action
        end
      end
    end

    # Set up the context for security tests
    def allowed_acl(sid, expected_perms, flags = 0)
      acl = [ ACE.access_allowed(sid, expected_perms[:specific], flags) ]
      if expected_perms[:generic]
        acl << ACE.access_allowed(sid, expected_perms[:generic], (Chef::ReservedNames::Win32::API::Security::SUBFOLDERS_AND_FILES_ONLY))
      end
      acl
    end

    def denied_acl(sid, expected_perms, flags = 0)
      acl = [ ACE.access_denied(sid, expected_perms[:specific], flags) ]
      if expected_perms[:generic]
        acl << ACE.access_denied(sid, expected_perms[:generic], (Chef::ReservedNames::Win32::API::Security::SUBFOLDERS_AND_FILES_ONLY))
      end
      acl
    end

    def parent_inheritable_acls
      dummy_directory_path = File.join(test_file_dir, "dummy_directory")
      dummy_directory = FileUtils.mkdir_p(dummy_directory_path)
      dummy_desc = get_security_descriptor(dummy_directory_path)
      FileUtils.rm_rf(dummy_directory_path)
      dummy_desc
    end

    it_behaves_like "a securable resource without existing target"
  end

  context "when the target directory exists" do
    before(:each) do
      # For resources such as remote_directory, simply creating the base
      # directory isn't enough to test that the system is in the desired state,
      # so we run the resource twice--otherwise the updated_by_last_action test
      # will fail.
      resource.dup.run_action(:create)
      expect(File).to exist(path)

      resource.run_action(:create)
    end

    describe "when running action :create" do
      before do
        resource.run_action(:create)
      end

      it "does not re-create the directory" do
        expect(File).to exist(path)
      end

      it "is not marked updated by last action" do
        expect(resource).not_to be_updated_by_last_action
      end
    end

    describe "when running action :delete" do
      context "without the recursive option" do
        before do
          resource.run_action(:delete)
        end

        it "deletes the directory" do
          expect(File).not_to exist(path)
        end

        it "is marked as updated by last action" do
          expect(resource).to be_updated_by_last_action
        end
      end

      context "with the recursive option" do
        before do
          FileUtils.mkdir(File.join(path, "red-headed-stepchild"))
          resource.recursive(true)
          resource.run_action(:delete)
        end

        it "recursively deletes directories" do
          expect(File).not_to exist(path)
        end
      end
    end
  end

end

shared_context Chef::Resource::Directory do
  # We create the  directory than tmp to exercise different file
  # deployment strategies more completely.
  let(:test_file_dir) do
    if windows?
      File.join(ENV["systemdrive"], "test-dir")
    else
      File.join(CHEF_SPEC_DATA, "test-dir")
    end
  end

  let(:path) do
    File.join(test_file_dir, make_tmpname(directory_base))
  end

  before do
    FileUtils.mkdir_p(test_file_dir)
  end

  after do
    FileUtils.rm_rf(test_file_dir)
  end

  after(:each) do
    FileUtils.rm_r(path) if File.exist?(path)
  end
end
