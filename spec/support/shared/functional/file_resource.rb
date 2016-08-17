#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

shared_context "deploying with move" do
  before do
    Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH
    Chef::Config[:file_atomic_update] = true
  end
end

shared_context "deploying with copy" do
  before do
    Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH
    Chef::Config[:file_atomic_update] = false
  end
end

shared_context "deploying via tmpdir" do
  before do
    Chef::Config[:file_staging_uses_destdir] = false
    Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH
  end
end

shared_context "deploying via destdir" do
  before do
    Chef::Config[:file_staging_uses_destdir] = true
    Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH
  end
end

shared_examples_for "a file with the wrong content" do
  before do
    # Assert starting state is as expected
    expect(File).to exist(path)
    # Kinda weird, in this case @expected_checksum is the cksum of the file
    # with incorrect content.
    expect(sha256_checksum(path)).to eq(@expected_checksum)
  end

  describe "when diff is disabled" do

    include_context "diff disabled"

    context "when running action :create" do
      context "with backups enabled" do
        before do
          resource.run_action(:create)
        end

        it "overwrites the file with the updated content when the :create action is run" do
          expect(File.stat(path).mtime).to be > @expected_mtime
          expect(sha256_checksum(path)).not_to eq(@expected_checksum)
        end

        it "backs up the existing file" do
          expect(Dir.glob(backup_glob).size).to equal(1)
        end

        it "is marked as updated by last action" do
          expect(resource).to be_updated_by_last_action
        end

        it "should restore the security contexts on selinux", :selinux_only do
          expect(selinux_security_context_restored?(path)).to be_truthy
        end
      end

      context "with backups disabled" do
        before do
          resource.backup(0)
          resource.run_action(:create)
        end

        it "should not attempt to backup the existing file if :backup == 0" do
          expect(Dir.glob(backup_glob).size).to equal(0)
        end

        it "should restore the security contexts on selinux", :selinux_only do
          expect(selinux_security_context_restored?(path)).to be_truthy
        end
      end

      context "with a checksum that does not match the content to deploy" do
        before do
          resource.checksum("aAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaA")
        end

        it "raises an exception" do
          expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::ChecksumMismatch)
        end
      end
    end

    describe "when running action :create_if_missing" do
      before do
        resource.run_action(:create_if_missing)
      end

      it "doesn't overwrite the file when the :create_if_missing action is run" do
        expect(File.stat(path).mtime).to eq(@expected_mtime)
        expect(sha256_checksum(path)).to eq(@expected_checksum)
      end

      it "is not marked as updated" do
        expect(resource).not_to be_updated_by_last_action
      end

      it "should restore the security contexts on selinux", :selinux_only do
        expect(selinux_security_context_restored?(path)).to be_truthy
      end
    end

    describe "when running action :delete" do
      before do
        resource.run_action(:delete)
      end

      it "deletes the file" do
        expect(File).not_to exist(path)
      end

      it "is marked as updated by last action" do
        expect(resource).to be_updated_by_last_action
      end
    end

  end

  context "when diff is enabled" do
    describe "sensitive attribute" do
      context "should be insensitive by default" do
        it { expect(resource.sensitive).to(be_falsey) }
      end

      context "when set" do
        before { resource.sensitive(true) }

        it "should be set on the resource" do
          expect(resource.sensitive).to(be_truthy)
        end

        context "when running :create action" do
          let(:provider) { resource.provider_for_action(:create) }
          let(:reporter_messages) { provider.instance_variable_get("@converge_actions").actions[0][0] }

          before do
            provider.run_action
          end

          it "should suppress the diff" do
            expect(resource.diff).to(include("suppressed sensitive resource"))
            expect(reporter_messages[1]).to eq("suppressed sensitive resource")
          end

          it "should still include the updated checksums" do
            expect(reporter_messages[0]).to include("update content in file")
          end
        end
      end
    end
  end
end

shared_examples_for "a file with the correct content" do
  before do
    # Assert starting state is as expected
    expect(File).to exist(path)
    expect(sha256_checksum(path)).to eq(@expected_checksum)
  end

  include_context "diff disabled"

  describe "when running action :create" do
    before do
      resource.run_action(:create)
    end
    it "does not overwrite the original when the :create action is run" do
      expect(sha256_checksum(path)).to eq(@expected_checksum)
    end

    it "does not update the mtime of the file when the :create action is run" do
      expect(File.stat(path).mtime).to eq(@expected_mtime)
    end

    it "is not marked as updated by last action" do
      expect(resource).not_to be_updated_by_last_action
    end

    it "should restore the security contexts on selinux", :selinux_only do
      expect(selinux_security_context_restored?(path)).to be_truthy
    end
  end

  describe "when running action :create_if_missing" do
    before do
      resource.run_action(:create_if_missing)
    end

    it "doesn't overwrite the file when the :create_if_missing action is run" do
      expect(sha256_checksum(path)).to eq(@expected_checksum)
    end

    it "is not marked as updated by last action" do
      expect(resource).not_to be_updated_by_last_action
    end

    it "should restore the security contexts on selinux", :selinux_only do
      expect(selinux_security_context_restored?(path)).to be_truthy
    end
  end

  describe "when running action :delete" do
    before do
      resource.run_action(:delete)
    end

    it "deletes the file when the :delete action is run" do
      expect(File).not_to exist(path)
    end

    it "is marked as updated by last action" do
      expect(resource).to be_updated_by_last_action
    end
  end
end

shared_examples_for "a file resource" do
  describe "when deploying with :move" do

    include_context "deploying with move"

    describe "when deploying via tmpdir" do

      include_context "deploying via tmpdir"

      it_behaves_like "a configured file resource"
    end

    describe "when deploying via destdir" do

      include_context "deploying via destdir"

      it_behaves_like "a configured file resource"
    end
  end

  describe "when deploying with :copy" do

    include_context "deploying with copy"

    describe "when deploying via tmpdir" do

      include_context "deploying via tmpdir"

      it_behaves_like "a configured file resource"
    end

    describe "when deploying via destdir" do

      include_context "deploying via destdir"

      it_behaves_like "a configured file resource"
    end
  end

  describe "when running under why run" do

    before do
      Chef::Config[:why_run] = true
      Chef::Config[:ssl_verify_mode] = :verify_none
    end

    after do
      Chef::Config[:why_run] = false
    end

    context "and the resource has a path with a missing intermediate directory" do
      # CHEF-3978

      let(:path) do
        File.join(test_file_dir, "intermediate_dir", make_tmpname(file_base))
      end

      it "successfully doesn't create the file" do
        resource.run_action(:create) # should not raise
        expect(File).not_to exist(path)
      end
    end

  end

  describe "when setting atomic_update" do
    it "booleans should work" do
      expect { resource.atomic_update(true) }.not_to raise_error
      expect { resource.atomic_update(false) }.not_to raise_error
    end

    it "anything else should raise an error" do
      expect { resource.atomic_update(:copy) }.to raise_error(ArgumentError)
      expect { resource.atomic_update(:move) }.to raise_error(ArgumentError)
      expect { resource.atomic_update(958) }.to raise_error(ArgumentError)
    end
  end

end

shared_examples_for "file resource not pointing to a real file" do
  def symlink?(file_path)
    if windows?
      Chef::ReservedNames::Win32::File.symlink?(file_path)
    else
      File.symlink?(file_path)
    end
  end

  def real_file?(file_path)
    !symlink?(file_path) && File.file?(file_path)
  end

  before do
    Chef::Config[:ssl_verify_mode] = :verify_none
  end

  describe "when force_unlink is set to true" do
    it ":create unlinks the target" do
      expect(real_file?(path)).to be_falsey
      resource.force_unlink(true)
      resource.run_action(:create)
      expect(real_file?(path)).to be_truthy
      expect(binread(path)).to eq(expected_content)
      expect(resource).to be_updated_by_last_action
    end
  end

  describe "when force_unlink is set to false" do
    it ":create raises an error" do
      expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::FileTypeMismatch)
    end
  end

  describe "when force_unlink is not set (default)" do
    it ":create raises an error" do
      expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::FileTypeMismatch)
    end
  end
end

shared_examples_for "a configured file resource" do

  include_context "diff disabled"

  before do
    Chef::Log.level = :info
    Chef::Config[:ssl_verify_mode] = :verify_none
  end

   # note the stripping of the drive letter from the tmpdir on windows
  let(:backup_glob) { File.join(CHEF_SPEC_BACKUP_PATH, test_file_dir.sub(/^([A-Za-z]:)/, ""), "#{file_base}*") }

  # Most tests update the resource, but a few do not. We need to test that the
  # resource is marked updated or not correctly, but the test contexts are
  # composed between correct/incorrect content and correct/incorrect
  # permissions. We override this "let" definition in the context where content
  # and permissions are correct.
  let(:expect_updated?) { true }

  include Chef::Mixin::ShellOut

  def selinux_security_context_restored?(path)
    @restorecon_path = which("restorecon") if @restorecon_path.nil?
    restorecon_test_command = "#{@restorecon_path} -n -v #{path}"
    cmdresult = shell_out(restorecon_test_command)
    # restorecon will print the required changes to stdout if any is
    # needed
    cmdresult.stdout.empty?
  end

  def binread(file)
    content = File.open(file, "rb") do |f|
      f.read
    end
    content.force_encoding(Encoding::BINARY) if "".respond_to?(:force_encoding)
    content
  end

  context "when the target file is a symlink", :not_supported_on_win2k3 do
    let(:symlink_target) do
      File.join(CHEF_SPEC_DATA, "file-test-target")
    end

    describe "when configured not to manage symlink's target" do
      before(:each) do
        # configure not to manage symlink source
        resource.manage_symlink_source(false)

        # create symlinks for test context
        FileUtils.touch(symlink_target)

        if windows?
          Chef::ReservedNames::Win32::File.symlink(symlink_target, path)
        else
          File.symlink(symlink_target, path)
        end
      end

      after(:each) do
        FileUtils.rm_rf(symlink_target)
        FileUtils.rm_rf(path)
      end

      describe "when symlink target has correct content" do
        before(:each) do
          File.open(symlink_target, "wb") { |f| f.print expected_content }
        end

        it_behaves_like "file resource not pointing to a real file"
      end

      describe "when symlink target has the wrong content" do
        before(:each) do
          File.open(symlink_target, "wb") { |f| f.print "This is so wrong!!!" }
        end

        after(:each) do
          # symlink should never be followed
          expect(binread(symlink_target)).to eq("This is so wrong!!!")
        end

        it_behaves_like "file resource not pointing to a real file"
      end
    end

    # Unix-only for now. Windows behavior may differ because of how ACL
    # management handles symlinks. Since symlinks are rare on Windows and this
    # feature primarily exists to support the case where a well-known file
    # (e.g., resolv.conf) has been converted to a symlink, we're okay with the
    # discrepancy.
    context "when configured to manage the symlink source", :unix_only do

      before do
        resource.manage_symlink_source(true)
      end

      context "but the symlink is part of a loop" do
        let(:link1_path) { File.join(CHEF_SPEC_DATA, "points-to-link2") }
        let(:link2_path) { File.join(CHEF_SPEC_DATA, "points-to-link1") }

        before do
          # point resource at link1:
          resource.path(link1_path)
          # create symlinks for test context
          File.symlink(link1_path, link2_path)
          File.symlink(link2_path, link1_path)
        end

        after(:each) do
          FileUtils.rm_rf(link1_path)
          FileUtils.rm_rf(link2_path)
        end

        it "raises an InvalidSymlink error" do
          expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::InvalidSymlink)
        end

        it "issues a warning/assumption in whyrun mode" do
          begin
            Chef::Config[:why_run] = true
            resource.run_action(:create) # should not raise
          ensure
            Chef::Config[:why_run] = false
          end
        end
      end

      context "but the symlink points to a nonexistent file" do
        let(:link_path) { File.join(CHEF_SPEC_DATA, "points-to-nothing") }
        let(:not_existent_source) { File.join(CHEF_SPEC_DATA, "i-am-not-here") }

        before do
          resource.path(link_path)
          # create symlinks for test context
          File.symlink(not_existent_source, link_path)
          FileUtils.rm_rf(not_existent_source)
        end

        after(:each) do
          FileUtils.rm_rf(link_path)
        end
        it "raises an InvalidSymlink error" do
          expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::InvalidSymlink)
        end

        it "issues a warning/assumption in whyrun mode" do
          begin
            Chef::Config[:why_run] = true
            resource.run_action(:create) # should not raise
          ensure
            Chef::Config[:why_run] = false
          end
        end
      end

      context "but the symlink is points to a non-file fs entry" do
        let(:link_path) { File.join(CHEF_SPEC_DATA, "points-to-dir") }
        let(:not_a_file_path) { File.join(CHEF_SPEC_DATA, "dir-at-end-of-symlink") }

        before do
          # point resource at link1:
          resource.path(link_path)
          # create symlinks for test context
          File.symlink(not_a_file_path, link_path)
          Dir.mkdir(not_a_file_path)
        end

        after(:each) do
          FileUtils.rm_rf(link_path)
          FileUtils.rm_rf(not_a_file_path)
        end

        it "raises an InvalidSymlink error" do
          expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::FileTypeMismatch)
        end

        it "issues a warning/assumption in whyrun mode" do
          begin
            Chef::Config[:why_run] = true
            resource.run_action(:create) # should not raise
          ensure
            Chef::Config[:why_run] = false
          end
        end
      end

      context "when the symlink source is a real file" do

        let(:wrong_content) { "this is the wrong content" }
        let(:link_path) { File.join(CHEF_SPEC_DATA, "points-to-real-file") }

        before do
          # point resource at link:
          resource.path(link_path)
          # create symlinks for test context
          File.symlink(path, link_path)
        end

        after(:each) do
          # shared examples should not change our test setup of a file resource
          # pointing at a symlink:
          expect(resource.path).to eq(link_path)
          FileUtils.rm_rf(link_path)
        end

        context "and the permissions are incorrect" do
          before do
            # Create source (real) file
            File.open(path, "wb") { |f| f.write(expected_content) }
          end

          include_context "setup broken permissions"

          include_examples "a securable resource with existing target"

          it "does not replace the symlink with a real file" do
            resource.run_action(:create)
            expect(File).to be_symlink(link_path)
          end

        end

        context "and the content is incorrect" do
          before do
            # Create source (real) file
            File.open(path, "wb") { |f| f.write(wrong_content) }
          end

          it "marks the resource as updated" do
            resource.run_action(:create)
            expect(resource).to be_updated_by_last_action
          end

          it "does not replace the symlink with a real file" do
            resource.run_action(:create)
            expect(File).to be_symlink(link_path)
          end
        end

        context "and the content and permissions are correct" do
          let(:expect_updated?) { false }

          before do
            # Create source (real) file
            File.open(path, "wb") { |f| f.write(expected_content) }
          end
          include_context "setup correct permissions"

          include_examples "a securable resource with existing target"

        end

      end

      context "when the symlink points to a symlink which points to a real file" do

        let(:wrong_content) { "this is the wrong content" }
        let(:link_to_file_path) { File.join(CHEF_SPEC_DATA, "points-to-real-file") }
        let(:link_to_link_path) { File.join(CHEF_SPEC_DATA, "points-to-next-link") }

        before do
          # point resource at link:
          resource.path(link_to_link_path)
          # create symlinks for test context
          File.symlink(path, link_to_file_path)
          File.symlink(link_to_file_path, link_to_link_path)

          # Create source (real) file
          File.open(path, "wb") { |f| f.write(wrong_content) }
        end

        include_context "setup broken permissions"

        include_examples "a securable resource with existing target"

        after(:each) do
          # shared examples should not change our test setup of a file resource
          # pointing at a symlink:
          expect(resource.path).to eq(link_to_link_path)
          FileUtils.rm_rf(link_to_file_path)
          FileUtils.rm_rf(link_to_link_path)
        end

        it "does not replace the symlink with a real file" do
          resource.run_action(:create)
          expect(File).to be_symlink(link_to_link_path)
          expect(File).to be_symlink(link_to_file_path)
        end

      end
    end
  end

  context "when the target file does not exist" do
    before(:each) do
      FileUtils.rm_rf(path)
    end

    after(:each) do
      FileUtils.rm_rf(path)
    end

    def symlink?(file_path)
      if windows?
        Chef::ReservedNames::Win32::File.symlink?(file_path)
      else
        File.symlink?(file_path)
      end
    end

    def real_file?(file_path)
      !symlink?(file_path) && File.file?(file_path)
    end

    describe "when force_unlink is set to true" do
      it ":create updates the target" do
        resource.force_unlink(true)
        resource.run_action(:create)
        expect(real_file?(path)).to be_truthy
        expect(binread(path)).to eq(expected_content)
        expect(resource).to be_updated_by_last_action
      end
    end

    describe "when force_unlink is set to false" do
      it ":create updates the target" do
        resource.force_unlink(true)
        resource.run_action(:create)
        expect(real_file?(path)).to be_truthy
        expect(binread(path)).to eq(expected_content)
        expect(resource).to be_updated_by_last_action
      end
    end

    describe "when force_unlink is not set (default)" do
      it ":create updates the target" do
        resource.force_unlink(true)
        resource.run_action(:create)
        expect(real_file?(path)).to be_truthy
        expect(binread(path)).to eq(expected_content)
        expect(resource).to be_updated_by_last_action
      end
    end
  end

  context "when the target file is a directory" do
    before(:each) do
      FileUtils.mkdir_p(path)
    end

    after(:each) do
      FileUtils.rm_rf(path)
    end

    it_behaves_like "file resource not pointing to a real file"
  end

  context "when the target file is a blockdev", :unix_only, :requires_root, :not_supported_on_solaris do
    include Chef::Mixin::ShellOut
    let(:path) do
      File.join(CHEF_SPEC_DATA, "testdev")
    end

    before(:each) do
      result = shell_out("mknod #{path} b 1 2")
      result.stderr.empty?
    end

    after(:each) do
      FileUtils.rm_rf(path)
    end

    it_behaves_like "file resource not pointing to a real file"
  end

  context "when the target file is a chardev", :unix_only, :requires_root, :not_supported_on_solaris do
    include Chef::Mixin::ShellOut
    let(:path) do
      File.join(CHEF_SPEC_DATA, "testdev")
    end

    before(:each) do
      result = shell_out("mknod #{path} c 1 2")
      result.stderr.empty?
    end

    after(:each) do
      FileUtils.rm_rf(path)
    end

    it_behaves_like "file resource not pointing to a real file"
  end

  context "when the target file is a pipe", :unix_only do
    include Chef::Mixin::ShellOut
    let(:path) do
      File.join(CHEF_SPEC_DATA, "testpipe")
    end

    before(:each) do
      result = shell_out("mkfifo #{path}")
      result.stderr.empty?
    end

    after(:each) do
      FileUtils.rm_rf(path)
    end

    it_behaves_like "file resource not pointing to a real file"
  end

  context "when the target file is a socket", :unix_only do
    require "socket"

    # It turns out that the path to a socket can have at most ~104
    # bytes. Therefore we are creating our sockets in tmpdir so that
    # they have a shorter path.
    let(:test_socket_dir) { File.join(Dir.tmpdir, "sockets") }

    before do
      FileUtils.mkdir_p(test_socket_dir)
    end

    after do
      FileUtils.rm_rf(test_socket_dir)
    end

    let(:path) do
      File.join(test_socket_dir, "testsocket")
    end

    before(:each) do
      expect(path.bytesize).to be <= 104
      UNIXServer.new(path)
    end

    after(:each) do
      FileUtils.rm_rf(path)
    end

    it_behaves_like "file resource not pointing to a real file"
  end

  # Regression test for http://tickets.opscode.com/browse/CHEF-4082
  context "when notification is configured" do
    describe "when path is specified with normal separator" do
      before do
        @notified_resource = Chef::Resource.new("punk", resource.run_context)
        resource.notifies(:run, @notified_resource, :immediately)
        resource.run_action(:create)
      end

      it "should notify the other resources correctly" do
        expect(resource).to be_updated_by_last_action
        expect(resource.run_context.immediate_notifications(resource).length).to eq(1)
      end
    end

    describe "when path is specified with windows separator", :windows_only do
      let(:path) do
        File.join(test_file_dir, make_tmpname(file_base)).gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR)
      end

      before do
        @notified_resource = Chef::Resource.new("punk", resource.run_context)
        resource.notifies(:run, @notified_resource, :immediately)
        resource.run_action(:create)
      end

      it "should notify the other resources correctly" do
        expect(resource).to be_updated_by_last_action
        expect(resource.run_context.immediate_notifications(resource).length).to eq(1)
      end
    end
  end

  context "when the target file does not exist" do
    before do
      # Assert starting state is expected
      expect(File).not_to exist(path)
    end

    describe "when running action :create" do
      before do
        resource.run_action(:create)
      end

      it "creates the file when the :create action is run" do
        expect(File).to exist(path)
      end

      it "creates the file with the correct content when the :create action is run" do
        expect(binread(path)).to eq(expected_content)
      end

      it "is marked as updated by last action" do
        expect(resource).to be_updated_by_last_action
      end

      it "should restore the security contexts on selinux", :selinux_only do
        expect(selinux_security_context_restored?(path)).to be_truthy
      end
    end

    describe "when running action :create_if_missing" do
      before do
        resource.run_action(:create_if_missing)
      end

      it "creates the file with the correct content" do
        expect(binread(path)).to eq(expected_content)
      end

      it "is marked as updated by last action" do
        expect(resource).to be_updated_by_last_action
      end

      it "should restore the security contexts on selinux", :selinux_only do
        expect(selinux_security_context_restored?(path)).to be_truthy
      end
    end

    describe "when running action :delete" do
      before do
        resource.run_action(:delete)
      end

      it "deletes the file when the :delete action is run" do
        expect(File).not_to exist(path)
      end

      it "is not marked updated by last action" do
        expect(resource).not_to be_updated_by_last_action
      end
    end
  end

  # Set up the context for security tests
  def allowed_acl(sid, expected_perms)
    [ ACE.access_allowed(sid, expected_perms[:specific]) ]
  end

  def denied_acl(sid, expected_perms)
    [ ACE.access_denied(sid, expected_perms[:specific]) ]
  end

  def parent_inheritable_acls
    dummy_file_path = File.join(test_file_dir, "dummy_file")
    FileUtils.touch(dummy_file_path)
    dummy_desc = get_security_descriptor(dummy_file_path)
    FileUtils.rm_rf(dummy_file_path)
    dummy_desc
  end

  it_behaves_like "a securable resource without existing target"

  context "when the target file has the wrong content" do
    before(:each) do
      File.open(path, "wb") { |f| f.print "This is so wrong!!!" }
      now = Time.now.to_i
      File.utime(now - 9000, now - 9000, path)

      @expected_mtime = File.stat(path).mtime
      @expected_checksum = sha256_checksum(path)
    end

    describe "and the target file has the correct permissions" do
      include_context "setup correct permissions"

      it_behaves_like "a file with the wrong content"

      it_behaves_like "a securable resource with existing target"
    end

    context "and the target file has incorrect permissions" do
      include_context "setup broken permissions"

      it_behaves_like "a file with the wrong content"

      it_behaves_like "a securable resource with existing target"
    end
  end

  context "when the target file has the correct content" do
    before(:each) do
      File.open(path, "wb") { |f| f.print expected_content }
      now = Time.now.to_i
      File.utime(now - 9000, now - 9000, path)

      @expected_mtime = File.stat(path).mtime
      @expected_checksum = sha256_checksum(path)
    end

    describe "and the target file has the correct permissions" do

      # When permissions and content are correct, chef should do nothing and
      # the resource should not be marked updated.
      let(:expect_updated?) { false }

      include_context "setup correct permissions"

      it_behaves_like "a file with the correct content"

      it_behaves_like "a securable resource with existing target"
    end

    context "and the target file has incorrect permissions" do
      include_context "setup broken permissions"

      it_behaves_like "a file with the correct content"

      it_behaves_like "a securable resource with existing target"
    end
  end

  # Regression test for http://tickets.opscode.com/browse/CHEF-4419
  context "when the path starts with '/' and target file exists", :windows_only do
    let(:path) do
      File.join(test_file_dir[2..test_file_dir.length], make_tmpname(file_base))
    end

    before do
      File.open(path, "wb") { |f| f.print expected_content }
      now = Time.now.to_i
      File.utime(now - 9000, now - 9000, path)

      @expected_mtime = File.stat(path).mtime
      @expected_checksum = sha256_checksum(path)
    end

    describe ":create action should run without any updates" do
      before do
        # Assert starting state is as expected
        expect(File).to exist(path)
        expect(sha256_checksum(path)).to eq(@expected_checksum)
        resource.run_action(:create)
      end

      it "does not overwrite the original when the :create action is run" do
        expect(sha256_checksum(path)).to eq(@expected_checksum)
      end

      it "does not update the mtime of the file when the :create action is run" do
        expect(File.stat(path).mtime).to eq(@expected_mtime)
      end

      it "is not marked as updated by last action" do
        expect(resource).not_to be_updated_by_last_action
      end
    end
  end

end

shared_context Chef::Resource::File do
  if windows?
    require "chef/win32/file"
  end

  # We create the files in a different directory than tmp to exercise
  # different file deployment strategies more completely.
  let(:test_file_dir) do
    if windows?
      File.join(ENV["systemdrive"], "test-dir")
    else
      File.join(CHEF_SPEC_DATA, "test-dir")
    end
  end

  let(:path) do
    File.join(test_file_dir, make_tmpname(file_base))
  end

  before do
    FileUtils.rm_rf(test_file_dir)
    FileUtils.mkdir_p(test_file_dir)
  end

  after(:each) do
    FileUtils.rm_r(path) if File.exists?(path)
    FileUtils.rm_r(CHEF_SPEC_BACKUP_PATH) if File.exists?(CHEF_SPEC_BACKUP_PATH)
  end

  after do
    FileUtils.rm_rf(test_file_dir)
  end
end
