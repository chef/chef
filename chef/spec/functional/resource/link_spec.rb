#
# Author:: John Keiser (<jkeiser@opscode.com>)
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

require 'spec_helper'

describe Chef::Resource::Link, :focus do
#  include_context Chef::Resource::Link

  let(:file_base) { "file_spec" }
  let(:expected_content) { "Don't fear the ruby." }

  let(:to) do
    filename = File.join(Dir.tmpdir, make_tmpname("to_spec", nil))
    File.open(filename, "w") do |file|
      file.write(expected_content)
    end
    filename
  end
  let(:target_file) do
    File.join(Dir.tmpdir, make_tmpname("from_spec", nil))
  end

  after(:each) do
    FileUtils.rm_r(to) if File.exists?(to)
    FileUtils.rm_r(target_file) if File.exists?(target_file)
    FileUtils.rm_r(CHEF_SPEC_BACKUP_PATH) if File.exists?(CHEF_SPEC_BACKUP_PATH)
  end

  def create_resource
    resource = Chef::Resource::Link.new(target_file)
    resource.to(to)
    resource
  end

  let!(:resource) do
    create_resource
  end

  def self.successfully_symlinks_to_target
    it "links to the target file" do
      resource.run_action(:create)
      File.symlink?(target_file).should be_true
      File.readlink(target_file).should == to
    end
  end

  context "is symbolic" do
    context "when the link destination exists" do
      context "when the link does not yet exist" do
        successfully_symlinks_to_target
        it_behaves_like "a securable resource" do
          let(:path) { target_file }
        end
        context "with a relative link destination" do
          successfully_symlinks_to_target
          it_behaves_like "a securable resource" do
            let(:path) { target_file }
          end
        end
        context "with a relative link destination and link" do
          successfully_symlinks_to_target
          it_behaves_like "a securable resource" do
            let(:path) { target_file }
          end
        end
      end
      context "when the link already exists and is a symbolic link" do
        context "pointing at the target" do
          before(:each) do
            symlink_resource = create_resource
            symlink_resource.run_action(:create)
            File.symlink?(target_file).should be_true
            File.readlink(target_file).should == to
          end
        end
        context "pointing somewhere else" do
          before(:each) do
            other_target = File.join(Dir.tmpdir, make_tmpname("other_spec", nil))
            File.open(other_target, "w") { |file| file.write("eek") }
            symlink_resource = create_resource
            symlink_resource.to(other_target)
            symlink_resource.run_action(:create)
            File.symlink?(other_target).should be_true
            File.readlink(target_file).should == other_target
          end
        end
      end
      context "when the link already exists and is a file" do
      end
      context "when the link already exists and is a directory" do
      end
      context "when the link already exists and is not writeable to this user" do
      end
    end
    context "when the link destination exists and is a directory" do
    end
    context "when the link destination exists and is a symbolic link" do
    end
    context "when the link destination exists and is not readable to this user" do
    end
    context "when the link destination does not exist" do
      before(:each) do
        File.delete(to)
      end
      it "links to the target file" do
        resource.run_action(:create)
        File.symlink?(target_file).should be_true
        File.readlink(target_file).should == to
      end
      it_behaves_like "a securable resource" do
        let(:path) { target_file }
      end
    end
  end

  context "is a hard link" do
    before(:each) do
      resource.link_type(:hard)
    end
    context "when the link destination exists" do
      context "when the link does not yet exist" do
      end
      context "when the link already exists and is a symbolic link" do
        before(:each) do
          symlink_resource = create_resource
          symlink_resource.run_action(:create)
          File.exists?(target_file).should be_true
          File.symlink?(target_file).should be_true
        end
      end
      context "when the link already exists and is a file" do
      end
      context "when the link already exists and is a directory" do
      end
      context "when the link destination exists and is a symbolic link" do
      end
      context "when the link already exists and is not writeable to this user" do
      end
      context "and specifies security attributes" do
      end
    end
    context "when the link destination exists and is not readable to this user" do
    end
    context "when the link destination does not exist" do
      before(:each) do
        File.delete(to)
      end
    end
  end
end
