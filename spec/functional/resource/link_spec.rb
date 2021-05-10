#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require "spec_helper"

if windows?
  require "chef/win32/file" # probably need this in spec_helper
  require "chef/win32/security"
end

describe Chef::Resource::Link do
  let(:file_base) { "file_spec" }

  let(:expect_updated?) { true }
  let(:logger) { double("Mixlib::Log::Child").as_null_object }

  # We create the files in a different directory than tmp to exercise
  # different file deployment strategies more completely.
  let(:test_file_dir) do
    if windows?
      File.join(ENV["systemdrive"], "test-dir")
    else
      File.join(CHEF_SPEC_DATA, "test-dir")
    end
  end

  before do
    FileUtils.mkdir_p(test_file_dir)
  end

  after do
    FileUtils.rm_rf(test_file_dir)
  end

  let(:to) do
    File.join(test_file_dir, make_tmpname("to_spec"))
  end
  let(:target_file) do
    File.join(test_file_dir, make_tmpname("from_spec"))
  end

  after(:each) do

    cleanup_link(to) if File.exist?(to)
    cleanup_link(target_file) if File.exist?(target_file)
    cleanup_link(CHEF_SPEC_BACKUP_PATH) if File.exist?(CHEF_SPEC_BACKUP_PATH)
  rescue
    puts "Could not remove a file: #{$!}"

  end

  def user(user)
    node = Chef::Node.new
    node.consume_external_attrs(ohai.data, {})
    run_context = Chef::RunContext.new(node, {}, Chef::EventDispatch::Dispatcher.new)
    usr = Chef::Resource.resource_for_node(:user, node).new(user, run_context)
    usr.password("ComplexPass11!") if windows?
    usr
  end

  def cleanup_link(path)
    if windows? && File.directory?(path)
      # If the link target is a directory rm_rf doesn't work all the
      # time on windows.
      system "rmdir '#{path}'"
    else
      FileUtils.rm_rf(path)
    end
  end

  def canonicalize(path)
    windows? ? path.tr("/", "\\") : path
  end

  def symlink(a, b)
    if windows?
      Chef::ReservedNames::Win32::File.symlink(a, b)
    else
      File.symlink(a, b)
    end
  end

  def symlink?(file)
    if windows?
      Chef::ReservedNames::Win32::File.symlink?(file)
    else
      File.symlink?(file)
    end
  end

  def readlink(file)
    if windows?
      Chef::ReservedNames::Win32::File.readlink(file)
    else
      File.readlink(file)
    end
  end

  def link(a, b)
    if windows?
      Chef::ReservedNames::Win32::File.link(a, b)
    else
      File.link(a, b)
    end
  end

  let(:test_user) { windows? ? nil : ENV["USER"] }

  def expected_owner
    if windows?
      get_sid(test_user)
    else
      test_user
    end
  end

  def get_sid(value)
    if value.is_a?(String)
      Chef::ReservedNames::Win32::Security::SID.from_account(value)
    elsif value.is_a?(Chef::ReservedNames::Win32::Security::SID)
      value
    else
      raise "Must specify username or SID: #{value}"
    end
  end

  def chown(file, user)
    if windows?
      Chef::ReservedNames::Win32::Security::SecurableObject.new(file).owner = get_sid(user)
    else
      File.lchown(Etc.getpwnam(user).uid, Etc.getpwnam(user).gid, file)
    end
  end

  def owner(file)
    if windows?
      Chef::ReservedNames::Win32::Security::SecurableObject.new(file).security_descriptor.owner
    else
      Etc.getpwuid(File.lstat(file).uid).name
    end
  end

  def create_resource
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new(cookbook_repo))
    run_context = Chef::RunContext.new(node, cookbook_collection, events)
    allow(run_context).to receive(:logger).and_return(logger)
    resource = Chef::Resource::Link.new(target_file, run_context)
    resource.to(to)
    resource
  end

  let(:resource) do
    create_resource
  end

  describe "when supported on platform" do
    shared_examples_for "delete errors out" do
      it "delete errors out" do
        expect { resource.run_action(:delete) }.to raise_error(Chef::Exceptions::Link)
        expect(File.exist?(target_file) || symlink?(target_file)).to be_truthy
      end
    end

    shared_context "delete is noop" do
      describe "the :delete action" do
        before(:each) do
          @info = []
          allow(logger).to receive(:info) { |msg| @info << msg }
          resource.run_action(:delete)
        end

        it "leaves the file deleted" do
          expect(File.exist?(target_file)).to be_falsey
          expect(symlink?(target_file)).to be_falsey
        end
        it "does not mark the resource updated" do
          expect(resource).not_to be_updated
        end
        it "does not log that it deleted" do
          expect(@info.include?("link[#{target_file}] deleted")).to be_falsey
        end
      end
    end

    shared_context "delete succeeds" do
      describe "the :delete action" do
        before(:each) do
          @info = []
          allow(logger).to receive(:info) { |msg| @info << msg }
          resource.run_action(:delete)
        end

        it "deletes the file" do
          expect(File.exist?(target_file)).to be_falsey
          expect(symlink?(target_file)).to be_falsey
        end
        it "marks the resource updated" do
          expect(resource).to be_updated
        end
        it "logs that it deleted" do
          expect(@info.include?("link[#{target_file}] deleted")).to be_truthy
        end
      end
    end

    shared_context "create symbolic link succeeds" do
      describe "the :create action" do
        before(:each) do
          @info = []
          allow(logger).to receive(:info) { |msg| @info << msg }
          resource.run_action(:create)
        end

        it "links to the target file" do
          expect(symlink?(target_file)).to be_truthy
          expect(readlink(target_file)).to eq(canonicalize(to))
          expect(owner(target_file)).to eq(expected_owner) unless test_user.nil?
        end
        it "marks the resource updated" do
          expect(resource).to be_updated
        end
        it "logs that it created" do
          expect(@info.include?("link[#{target_file}] created")).to be_truthy
        end
      end
    end

    shared_context "create symbolic link is noop" do
      describe "the :create action" do
        before(:each) do
          @info = []
          allow(logger).to receive(:info) { |msg| @info << msg }
          resource.run_action(:create)
        end

        it "leaves the file linked" do
          expect(symlink?(target_file)).to be_truthy
          expect(readlink(target_file)).to eq(canonicalize(to))
          expect(owner(target_file)).to eq(expected_owner) unless test_user.nil?
        end
        it "does not mark the resource updated" do
          expect(resource).not_to be_updated
        end
        it "does not log that it created" do
          expect(@info.include?("link[#{target_file}] created")).to be_falsey
        end
      end
    end

    shared_context "create hard link succeeds" do
      describe "the :create action" do
        before(:each) do
          @info = []
          allow(logger).to receive(:info) { |msg| @info << msg }
          resource.run_action(:create)
        end
        it "preserves the hard link" do
          expect(File.exist?(target_file)).to be_truthy
          expect(symlink?(target_file)).to be_falsey
          # Writing to one hardlinked file should cause both
          # to have the new value.
          expect(IO.read(to)).to eq(IO.read(target_file))
          File.open(to, "w") { |file| file.write("wowzers") }
          expect(IO.read(target_file)).to eq("wowzers")
        end
        it "marks the resource updated" do
          expect(resource).to be_updated
        end
        it "logs that it created" do
          expect(@info.include?("link[#{target_file}] created")).to be_truthy
        end
      end
    end

    shared_context "create hard link is noop" do
      describe "the :create action" do
        before(:each) do
          @info = []
          allow(logger).to receive(:info) { |msg| @info << msg }
          resource.run_action(:create)
        end
        it "links to the target file" do
          expect(File.exist?(target_file)).to be_truthy
          expect(symlink?(target_file)).to be_falsey
          # Writing to one hardlinked file should cause both
          # to have the new value.
          expect(IO.read(to)).to eq(IO.read(target_file))
          File.open(to, "w") { |file| file.write("wowzers") }
          expect(IO.read(target_file)).to eq("wowzers")
        end
        it "does not mark the resource updated" do
          expect(resource).not_to be_updated
        end
        it "does not log that it created" do
          expect(@info.include?("link[#{target_file}] created")).to be_falsey
        end
      end
    end

    context "is symbolic" do

      context "when the link destination is a file" do
        before(:each) do
          File.open(to, "w") do |file|
            file.write("woohoo")
          end
        end
        context "and the link does not yet exist" do
          include_context "create symbolic link succeeds"
          include_context "delete is noop"
        end
        context "and the link already exists and is a symbolic link" do
          context "pointing at the target" do
            before(:each) do
              symlink(to, target_file)
              expect(symlink?(target_file)).to be_truthy
              expect(readlink(target_file)).to eq(canonicalize(to))
            end
            include_context "create symbolic link is noop"
            include_context "delete succeeds"
            it "the :delete action does not delete the target file" do
              resource.run_action(:delete)
              expect(File.exist?(to)).to be_truthy
            end
          end
          context "pointing somewhere else", :requires_root_or_running_windows do
            let(:test_user) { "test-link-user" }
            before do
              user(test_user).run_action(:create)
            end
            after do
              user(test_user).run_action(:remove)
            end
            before(:each) do
              resource.owner(test_user)
              @other_target = File.join(test_file_dir, make_tmpname("other_spec"))
              File.open(@other_target, "w") { |file| file.write("eek") }
              symlink(@other_target, target_file)
              chown(target_file, test_user)
              expect(symlink?(target_file)).to be_truthy
              expect(readlink(target_file)).to eq(canonicalize(@other_target))
              expect(owner(target_file)).to eq(expected_owner)
            end
            after(:each) do
              File.delete(@other_target)
            end
            include_context "create symbolic link succeeds"
            include_context "delete succeeds"
            it "the :delete action does not delete the target file" do
              resource.run_action(:delete)
              expect(File.exist?(to)).to be_truthy
            end
          end
          context "pointing nowhere" do
            before(:each) do
              nonexistent = File.join(test_file_dir, make_tmpname("nonexistent_spec"))
              symlink(nonexistent, target_file)
              expect(symlink?(target_file)).to be_truthy
              expect(readlink(target_file)).to eq(canonicalize(nonexistent))
            end
            include_context "create symbolic link succeeds"
            include_context "delete succeeds"
          end
        end
        context "and the link already exists and is a hard link to the file" do
          before(:each) do
            link(to, target_file)
            expect(File.exist?(target_file)).to be_truthy
            expect(symlink?(target_file)).to be_falsey
          end
          include_context "create symbolic link succeeds"
          it_behaves_like "delete errors out"
        end
        context "and the link already exists and is a file" do
          before(:each) do
            File.open(target_file, "w") { |file| file.write("eek") }
          end
          include_context "create symbolic link succeeds"
          it_behaves_like "delete errors out"
        end
        context "and the link already exists and is a directory" do
          before(:each) do
            Dir.mkdir(target_file)
          end
          it "create errors out" do
            if windows?
              expect { resource.run_action(:create) }.to raise_error(Errno::EACCES)
            elsif macos? || solaris? || freebsd? || aix?
              expect { resource.run_action(:create) }.to raise_error(Errno::EPERM)
            else
              expect { resource.run_action(:create) }.to raise_error(Errno::EISDIR)
            end
          end
          it_behaves_like "delete errors out"
        end

        it_behaves_like "a securable resource without existing target" do
          let(:path) { target_file }
          def allowed_acl(sid, expected_perms, _flags = 0)
            [ ACE.access_allowed(sid, expected_perms[:specific]) ]
          end

          def denied_acl(sid, expected_perms, _flags = 0)
            [ ACE.access_denied(sid, expected_perms[:specific]) ]
          end

          def parent_inheritable_acls
            dummy_file_path = File.join(test_file_dir, "dummy_file")
            FileUtils.touch(dummy_file_path)
            dummy_desc = get_security_descriptor(dummy_file_path)
            FileUtils.rm_rf(dummy_file_path)
            dummy_desc
          end
        end
      end
      context "when the link destination is a directory" do
        before(:each) do
          Dir.mkdir(to)
        end
        # On Windows, readlink fails to open the link.  FILE_FLAG_OPEN_REPARSE_POINT
        # might help, from http://msdn.microsoft.com/en-us/library/windows/desktop/aa363858(v=vs.85).aspx
        context "and the link does not yet exist" do
          include_context "create symbolic link succeeds"
          include_context "delete is noop"
        end
        context "and the link already exists and points to a different directory" do
          before(:each) do
            other_dir = File.join(test_file_dir, make_tmpname("other_dir"))
            Dir.mkdir(other_dir)
            symlink(other_dir, target_file)
          end
          include_context "create symbolic link succeeds"
          include_context "delete succeeds"
        end
        context "and the link already exists and points at the target" do
          before do
            symlink(to, target_file)
          end
          include_context "create symbolic link is noop"
          include_context "delete succeeds"
        end
      end
      context "when the link destination is a symbolic link" do
        context "to a file that exists" do
          before(:each) do
            @other_target = File.join(test_file_dir, make_tmpname("other_spec"))
            File.open(@other_target, "w") { |file| file.write("eek") }
            symlink(@other_target, to)
            expect(symlink?(to)).to be_truthy
            expect(readlink(to)).to eq(canonicalize(@other_target))
          end
          after(:each) do
            File.delete(@other_target)
          end
          context "and the link does not yet exist" do
            include_context "create symbolic link succeeds"
            include_context "delete is noop"
          end
          context "and the destination itself has another symbolic link" do
            context "to a link that exist" do
              before do
                symlink(to, target_file)
              end
              include_context "create symbolic link is noop"
              include_context "delete succeeds"
            end
            context "to a link that does not exist" do
              include_context "create symbolic link succeeds"
              include_context "delete is noop"
            end
          end
        end
        context "to a file that does not exist" do
          before(:each) do
            @other_target = File.join(test_file_dir, make_tmpname("other_spec"))
            symlink(@other_target, to)
            expect(symlink?(to)).to be_truthy
            expect(readlink(to)).to eq(canonicalize(@other_target))
          end
          context "and the link does not yet exist" do
            include_context "create symbolic link succeeds"
            include_context "delete is noop"
          end
          context "and the destination itself has another symbolic link" do
            context "to a link that exist" do
              before do
                symlink(to, target_file)
              end
              include_context "create symbolic link is noop"
              include_context "delete succeeds"
            end
            context "to a link that does not exist" do
              include_context "create symbolic link succeeds"
              include_context "delete is noop"
            end
          end
        end
      end
      context "when the link destination does not exist" do
        include_context "create symbolic link succeeds"
        include_context "delete is noop"
      end

      {
        "../" => "with a relative link destination",
        "" => "with a bare filename for the link destination",
      }.each do |prefix, desc|
        context desc do
          let(:to) { "#{prefix}#{File.basename(absolute_to)}" }
          let(:absolute_to) { File.join(test_file_dir, make_tmpname("to_spec")) }
          before(:each) do
            resource.to(to)
          end
          context "when the link does not yet exist" do
            include_context "create symbolic link succeeds"
            include_context "delete is noop"
          end
          context "when the link already exists and points at the target" do
            before(:each) do
              symlink(to, target_file)
              expect(symlink?(target_file)).to be_truthy
              expect(readlink(target_file)).to eq(canonicalize(to))
            end
            include_context "create symbolic link is noop"
            include_context "delete succeeds"
          end
          context "when the link already exists and points at the target with an absolute path" do
            before(:each) do
              symlink(absolute_to, target_file)
              expect(symlink?(target_file)).to be_truthy
              expect(readlink(target_file)).to eq(canonicalize(absolute_to))
            end
            include_context "create symbolic link succeeds"
            include_context "delete succeeds"
          end
        end
      end
    end

    context "is a hard link" do
      before(:each) do
        resource.link_type(:hard)
      end

      context "when the link destination is a file" do
        before(:each) do
          File.open(to, "w") do |file|
            file.write("woohoo")
          end
        end
        context "and the link does not yet exist" do
          include_context "create hard link succeeds"
          include_context "delete is noop"
        end
        context "and the link already exists and is a symbolic link pointing at the same file" do
          before(:each) do
            symlink(to, target_file)
            expect(symlink?(target_file)).to be_truthy
            expect(readlink(target_file)).to eq(canonicalize(to))
          end
          include_context "create hard link succeeds"
          it_behaves_like "delete errors out"
        end
        context "and the link already exists and is a hard link to the file" do
          before(:each) do
            link(to, target_file)
            expect(File.exist?(target_file)).to be_truthy
            expect(symlink?(target_file)).to be_falsey
          end
          include_context "create hard link is noop"
          include_context "delete succeeds"
          it "the :delete action does not delete the target file" do
            resource.run_action(:delete)
            expect(File.exist?(to)).to be_truthy
          end
        end
        context "and the link already exists and is a file" do
          before(:each) do
            File.open(target_file, "w") { |file| file.write("tomfoolery") }
          end
          include_context "create hard link succeeds"
          it_behaves_like "delete errors out"
        end
        context "and the link already exists and is a directory" do
          before(:each) do
            Dir.mkdir(target_file)
          end
          it "errors out" do
            if windows?
              expect { resource.run_action(:create) }.to raise_error(Errno::EACCES)
            elsif macos? || solaris? || freebsd? || aix?
              expect { resource.run_action(:create) }.to raise_error(Errno::EPERM)
            else
              expect { resource.run_action(:create) }.to raise_error(Errno::EISDIR)
            end
          end
          it_behaves_like "delete errors out"
        end
        context "and specifies security attributes" do
          before(:each) do
            resource.owner(windows? ? "Guest" : "nobody")
          end
          it "ignores them" do
            resource.run_action(:create)
            if windows?
              expect(Chef::ReservedNames::Win32::Security.get_named_security_info(target_file).owner).not_to eq(SID.Guest)
            else
              expect(File.lstat(target_file).uid).not_to eq(Etc.getpwnam("nobody").uid)
            end
          end
        end
      end
      context "when the link destination is a directory" do
        before(:each) do
          Dir.mkdir(to)
        end
        context "and the link does not yet exist" do
          it "create errors out" do
            expect { resource.run_action(:create) }.to raise_error(windows? ? Chef::Exceptions::Win32APIError : Errno::EPERM)
          end
          include_context "delete is noop"
        end
      end
      context "when the link destination is a symbolic link" do
        context "to a real file" do
          before(:each) do
            @other_target = File.join(test_file_dir, make_tmpname("other_spec"))
            File.open(@other_target, "w") { |file| file.write("eek") }
            symlink(@other_target, to)
            expect(symlink?(to)).to be_truthy
            expect(readlink(to)).to eq(canonicalize(@other_target))
          end
          after(:each) do
            File.delete(@other_target)
          end
          context "and the link does not yet exist" do
            it "links to the target file" do
              skip("macOS/FreeBSD/AIX/Solaris symlink? and readlink working on hard links to symlinks") if macos? || freebsd? || aix? || solaris?
              resource.run_action(:create)
              expect(File.exist?(target_file)).to be_truthy
              # macOS gets angry about this sort of link. Bug in macOS, IMO.
              expect(symlink?(target_file)).to be_truthy
              expect(readlink(target_file)).to eq(canonicalize(@other_target))
            end
            include_context "delete is noop"
          end
        end
        context "to a nonexistent file" do
          before(:each) do
            @other_target = File.join(test_file_dir, make_tmpname("other_spec"))
            symlink(@other_target, to)
            expect(symlink?(to)).to be_truthy
            expect(readlink(to)).to eq(canonicalize(@other_target))
          end
          context "and the link does not yet exist" do
            it "links to the target file" do
              skip("macOS/FreeBSD/AIX/Solaris fails to create hardlinks to broken symlinks") if macos? || freebsd? || aix? || solaris?
              resource.run_action(:create)
              expect(File.exist?(target_file) || File.symlink?(target_file)).to be_truthy
              expect(symlink?(target_file)).to be_truthy
              expect(readlink(target_file)).to eq(canonicalize(@other_target))
            end
            include_context "delete is noop"
          end
        end
      end

      context "when the link destination does not exist" do
        context "and the link does not yet exist" do
          it "create errors out" do
            expect { resource.run_action(:create) }.to raise_error(Errno::ENOENT)
          end
          include_context "delete is noop"
        end
      end
    end
  end
end
