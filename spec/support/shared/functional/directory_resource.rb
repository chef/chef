#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

  let(:expect_updated?) {true}

  context "when the target directory does not exist" do
    before do
      # assert pre-condition
      File.should_not exist(path)
    end

    describe "when running action :create" do
      context "and the recursive option is not set" do
        before do
          resource.run_action(:create)
        end

        it "creates the directory when the :create action is run" do
          File.should exist(path)
        end

        it "is marked updated by last action" do
          resource.should be_updated_by_last_action
        end
      end

      context "and the recursive option is set" do
        before do
          File.should_not exist(path)

          resource.recursive(true)
          @recursive_path = File.join(path, 'red-headed-stepchild')
          resource.path(@recursive_path)
          resource.run_action(:create)
        end

        it "recursively creates required directories" do
          File.should exist(path)
          File.should exist(@recursive_path)
        end

        it "is marked updated by last action" do
          resource.should be_updated_by_last_action
        end
      end
    end
  end

  context "when the target directory exists" do
    before(:each) do
      # For resources such as remote_directory, simply creating the base
      # directory isn't enough to test that the system is in the desired state,
      # so we run the resource twice--otherwise the updated_by_last_action test
      # will fail.
      resource.dup.run_action(:create)
      File.should exist(path)

      resource.run_action(:create)
    end

    describe "when running action :create" do
      before do
        resource.run_action(:create)
      end

      it "does not re-create the directory" do
        File.should exist(path)
      end

      it "is not marked updated by last action" do
        resource.should_not be_updated_by_last_action
      end
    end

    describe "when running action :delete" do
      context "without the recursive option" do
        before do
          resource.run_action(:delete)
        end

        it "deletes the directory" do
          File.should_not exist(path)
        end

        it "is marked as updated by last action" do
          resource.should be_updated_by_last_action
        end
      end

      context "with the recursive option" do
        before do
          FileUtils.mkdir(File.join(path, 'red-headed-stepchild'))
          resource.recursive(true)
          resource.run_action(:delete)
        end

        it "recursively deletes directories" do
          File.should_not exist(path)
        end
      end
    end
  end

  # Set up the context for security tests
  def allowed_acl(sid, expected_perms)
    [
      ACE.access_allowed(sid, expected_perms[:specific]),
      ACE.access_allowed(sid, expected_perms[:generic], (Chef::ReservedNames::Win32::API::Security::INHERIT_ONLY_ACE | Chef::ReservedNames::Win32::API::Security::CONTAINER_INHERIT_ACE | Chef::ReservedNames::Win32::API::Security::OBJECT_INHERIT_ACE))
    ]
  end

  def denied_acl(sid, expected_perms)
    [
      ACE.access_denied(sid, expected_perms[:specific]),
      ACE.access_denied(sid, expected_perms[:generic], (Chef::ReservedNames::Win32::API::Security::INHERIT_ONLY_ACE | Chef::ReservedNames::Win32::API::Security::CONTAINER_INHERIT_ACE | Chef::ReservedNames::Win32::API::Security::OBJECT_INHERIT_ACE))
    ]
  end

  it_behaves_like "a securable resource"
end

shared_context Chef::Resource::Directory do
  let(:path) do
    File.join(Dir.tmpdir, make_tmpname(directory_base, nil))
  end

  after(:each) do
    FileUtils.rm_r(path) if File.exists?(path)
  end
end
