#
# Author:: Lamont Granquist (<lamont@chef.io>)
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

require "tmpdir"
if windows?
  require "chef/win32/file"
end

# Filesystem stubs
def file_symlink_class
  if windows?
    Chef::ReservedNames::Win32::File
  else
    File
  end
end

def normalized_path
  File.expand_path(resource_path)
end

# forwards-vs-reverse slashes on windows sucks
def windows_path
  windows? ? normalized_path.tr("\\", "/") : normalized_path
end

# this is all getting a bit stupid, CHEF-4802 cut to remove all this
def setup_normal_file
  [ resource_path, normalized_path, windows_path].each do |path|
    allow(File).to receive(:file?).with(path).and_return(true)
    allow(File).to receive(:exists?).with(path).and_return(true)
    allow(File).to receive(:exist?).with(path).and_return(true)
    allow(File).to receive(:directory?).with(path).and_return(false)
    allow(File).to receive(:writable?).with(path).and_return(true)
    allow(file_symlink_class).to receive(:symlink?).with(path).and_return(false)
    allow(File).to receive(:realpath?).with(path).and_return(normalized_path)
  end
  allow(File).to receive(:directory?).with(enclosing_directory).and_return(true)
end

def setup_missing_file
  [ resource_path, normalized_path, windows_path].each do |path|
    allow(File).to receive(:file?).with(path).and_return(false)
    allow(File).to receive(:realpath?).with(path).and_return(resource_path)
    allow(File).to receive(:exists?).with(path).and_return(false)
    allow(File).to receive(:exist?).with(path).and_return(false)
    allow(File).to receive(:directory?).with(path).and_return(false)
    allow(File).to receive(:writable?).with(path).and_return(false)
    allow(file_symlink_class).to receive(:symlink?).with(path).and_return(false)
  end
  allow(File).to receive(:directory?).with(enclosing_directory).and_return(true)
end

def setup_symlink
  [ resource_path, normalized_path, windows_path].each do |path|
    allow(File).to receive(:file?).with(path).and_return(true)
    allow(File).to receive(:realpath?).with(path).and_return(normalized_path)
    allow(File).to receive(:exists?).with(path).and_return(true)
    allow(File).to receive(:exist?).with(path).and_return(true)
    allow(File).to receive(:directory?).with(path).and_return(false)
    allow(File).to receive(:writable?).with(path).and_return(true)
    allow(file_symlink_class).to receive(:symlink?).with(path).and_return(true)
    allow(file_symlink_class).to receive(:realpath).with(path).and_return(path)
  end
  allow(File).to receive(:directory?).with(enclosing_directory).and_return(true)
end

def setup_unwritable_file
  [ resource_path, normalized_path, windows_path].each do |path|
    allow(File).to receive(:file?).with(path).and_return(false)
    allow(File).to receive(:realpath?).with(path).and_raise(Errno::ENOENT)
    allow(File).to receive(:exists?).with(path).and_return(true)
    allow(File).to receive(:exist?).with(path).and_return(true)
    allow(File).to receive(:directory?).with(path).and_return(false)
    allow(File).to receive(:writable?).with(path).and_return(false)
    allow(file_symlink_class).to receive(:symlink?).with(path).and_return(false)
  end
  allow(File).to receive(:directory?).with(enclosing_directory).and_return(true)
end

def setup_missing_enclosing_directory
  [ resource_path, normalized_path, windows_path].each do |path|
    allow(File).to receive(:file?).with(path).and_return(false)
    allow(File).to receive(:realpath?).with(path).and_raise(Errno::ENOENT)
    allow(File).to receive(:exists?).with(path).and_return(false)
    allow(File).to receive(:exist?).with(path).and_return(false)
    allow(File).to receive(:directory?).with(path).and_return(false)
    allow(File).to receive(:writable?).with(path).and_return(false)
    allow(file_symlink_class).to receive(:symlink?).with(path).and_return(false)
  end
  allow(File).to receive(:directory?).with(enclosing_directory).and_return(false)
end

# A File subclass that we use as a replacement for Tempfile. Some versions of
# Tempfile call `File.exist?()` internally which will cause test failures if
# `File.exist?()` has been stubbed.
class BasicTempfile < ::File

  def self.make_tmp_path(basename)
    slug = "#{basename}-#{rand(1 << 128)}"
    File.join(Dir.tmpdir, slug)
  end

  def self.new(basename)
    super(make_tmp_path(basename), File::RDWR | File::CREAT | File::EXCL, 0600)
  end

  def unlink
    self.class.unlink(path)
  end

end

shared_examples_for Chef::Provider::File do

  let(:tempfile_path) do
  end

  let!(:tempfile) do
    BasicTempfile.new("rspec-shared-file-provider")
  end

  before(:each) do
    allow(content).to receive(:tempfile).and_return(tempfile)
    allow(File).to receive(:exist?).with(tempfile.path).and_call_original
    allow(File).to receive(:exists?).with(tempfile.path).and_call_original
  end

  after do
    tempfile.close if tempfile && !tempfile.closed?
    File.unlink(tempfile.path) rescue nil
  end

  it "should return a #{described_class}" do
    expect(provider).to be_a_kind_of(described_class)
  end

  it "should store the resource passed to new as new_resource" do
    expect(provider.new_resource).to eql(resource)
  end

  it "should store the node passed to new as node" do
    expect(provider.node).to eql(node)
  end

  context "when loading the current resource" do

    context "when running load_current_resource" do
      #
      # the content objects need the current_resource to be loaded (esp remote_file), so calling
      # for content inside of load_current_resource is totally crossing the streams...
      #
      it "should not try to load the content when the file is present" do
        setup_normal_file
        expect(provider).not_to receive(:tempfile)
        expect(provider).not_to receive(:content)
        provider.load_current_resource
      end

      it "should not try to load the content when the file is missing" do
        setup_missing_file
        expect(provider).not_to receive(:tempfile)
        expect(provider).not_to receive(:content)
        provider.load_current_resource
      end
    end

    context "when running load_current_resource and the file exists" do
      before do
        setup_normal_file
      end

      let(:tempfile_sha256) { "42971f0ddce0cb20cf7660a123ffa1a1543beb2f1e7cd9d65858764a27f3201d" }

      it "should load a current resource based on the one specified at construction" do
        provider.load_current_resource
        expect(provider.current_resource).to be_a_kind_of(Chef::Resource::File)
      end

      it "the loaded current_resource name should be the same as the resource name" do
        provider.load_current_resource
        expect(provider.current_resource.name).to eql(resource.name)
      end

      it "the loaded current_resource path should be the same as the resource path" do
        provider.load_current_resource
        expect(provider.current_resource.path).to eql(resource.path)
      end

      it "the loaded current_resource content should be nil" do
        provider.load_current_resource
        expect(provider.current_resource.content).to eql(nil)
      end

      it "it should call checksum if we are managing content" do
        expect(provider).to receive(:managing_content?).at_least(:once).and_return(true)
        expect(provider).to receive(:checksum).with(resource.path).and_return(tempfile_sha256)
        provider.load_current_resource
      end

      it "it should not call checksum if we are not managing content" do
        expect(provider).to receive(:managing_content?).at_least(:once).and_return(false)
        expect(provider).not_to receive(:checksum)
        provider.load_current_resource
      end
    end

    context "when running load_current_resource and the file does not exist" do
      before do
        setup_missing_file
      end

      it "the current_resource should be a Chef::Resource::File" do
        provider.load_current_resource
        expect(provider.current_resource).to be_a_kind_of(Chef::Resource::File)
      end

      it "the current_resource name should be the same as the resource name" do
        provider.load_current_resource
        expect(provider.current_resource.name).to eql(resource.name)
      end

      it "the current_resource path should be the same as the resource path" do
        provider.load_current_resource
        expect(provider.current_resource.path).to eql(resource.path)
      end

      it "the loaded current_resource content should be nil" do
        provider.load_current_resource
        expect(provider.current_resource.content).to eql(nil)
      end

      it "it should not call checksum if we are not managing content" do
        expect(provider).not_to receive(:managing_content?)
        expect(provider).not_to receive(:checksum)
        provider.load_current_resource
      end
    end

    context "examining file security metadata on Unix with a file that exists" do
      before do
        # fake that we're on unix even if we're on windows
        allow(ChefUtils).to receive(:windows?).and_return(false)
        # mock up the filesystem to behave like unix
        setup_normal_file
        stat_struct = double("::File.stat", mode: 0600, uid: 0, gid: 0, mtime: 10000)
        resource_real_path = File.realpath(resource.path)
        expect(File).to receive(:stat).with(resource_real_path).at_least(:once).and_return(stat_struct)
        allow(Etc).to receive(:getgrgid).with(0).and_return(double("Group Ent", name: "wheel"))
        allow(Etc).to receive(:getpwuid).with(0).and_return(double("User Ent", name: "root"))
      end

      context "when the new_resource does not specify any state" do
        before do
          provider.load_current_resource
        end

        it "should load the permissions into the current_resource" do
          expect(provider.current_resource.mode).to eq("0600")
          expect(provider.current_resource.owner).to eq("root")
          expect(provider.current_resource.group).to eq("wheel")
        end

        it "should not set the new_resource permissions" do
          expect(provider.new_resource.group).to be_nil
          expect(provider.new_resource.owner).to be_nil
          expect(provider.new_resource.mode).to be_nil
        end
      end

      context "when the new_resource explicitly specifies resource state as numbers" do
        before do
          resource.owner(1)
          resource.group(1)
          resource.mode(0644)
          provider.load_current_resource
        end

        it "should load the permissions into the current_resource as numbers" do
          # Mode is always loaded as string for reporting purposes.
          expect(provider.current_resource.mode).to eq("0600")
          expect(provider.current_resource.owner).to eq(0)
          expect(provider.current_resource.group).to eq(0)
        end

        it "should not set the new_resource permissions" do
          expect(provider.new_resource.group).to eq(1)
          expect(provider.new_resource.owner).to eq(1)
          expect(provider.new_resource.mode).to eq(0644)
        end
      end

      context "when the new_resource explicitly specifies resource state as symbols" do
        before do
          resource.owner("macklemore")
          resource.group("seattlehiphop")
          resource.mode("0321")
          provider.load_current_resource
        end

        it "should load the permissions into the current_resource as symbols" do
          expect(provider.current_resource.mode).to eq("0600")
          expect(provider.current_resource.owner).to eq("root")
          expect(provider.current_resource.group).to eq("wheel")
        end

        it "should not set the new_resource permissions" do
          expect(provider.new_resource.group).to eq("seattlehiphop")
          expect(provider.new_resource.owner).to eq("macklemore")
          expect(provider.new_resource.mode).to eq("0321")
        end
      end

    end

    context "examining file security metadata on Unix with a file that does not exist" do
      before do
        # fake that we're on unix even if we're on windows
        allow(ChefUtils).to receive(:windows?).and_return(false)
        setup_missing_file
      end

      context "when the new_resource does not specify any state" do
        before do
          provider.load_current_resource
        end

        it "the current_resource permissions should be nil" do
          expect(provider.current_resource.mode).to be_nil
          expect(provider.current_resource.owner).to be_nil
          expect(provider.current_resource.group).to be_nil
        end

        it "should not set the new_resource permissions" do
          expect(provider.new_resource.group).to be_nil
          expect(provider.new_resource.owner).to be_nil
          expect(provider.new_resource.mode).to be_nil
        end
      end

      context "when the new_resource explicitly specifies resource state" do
        before do
          resource.owner(63945)
          resource.group(51948)
          resource.mode(0123)
          provider.load_current_resource
        end

        it "the current_resource permissions should be nil" do
          expect(provider.current_resource.mode).to be_nil
          expect(provider.current_resource.owner).to be_nil
          expect(provider.current_resource.group).to be_nil
        end

        it "should not set the new_resource permissions" do
          expect(provider.new_resource.group).to eq(51948)
          expect(provider.new_resource.owner).to eq(63945)
          expect(provider.new_resource.mode).to eq(0123)
        end
      end
    end
  end

  context "when loading the new_resource after the run" do

    before do
      # fake that we're on unix even if we're on windows
      allow(ChefUtils).to receive(:windows?).and_return(false)
      # mock up the filesystem to behave like unix
      setup_normal_file
      stat_struct = double("::File.stat", mode: 0600, uid: 0, gid: 0, mtime: 10000)
      resource_real_path = File.realpath(resource.path)
      allow(File).to receive(:stat).with(resource_real_path).and_return(stat_struct)
      allow(Etc).to receive(:getgrgid).with(0).and_return(double("Group Ent", name: "wheel"))
      allow(Etc).to receive(:getpwuid).with(0).and_return(double("User Ent", name: "root"))
      provider.send(:load_resource_attributes_from_file, resource)
    end

    it "new_resource should record the new permission information" do
      expect(provider.new_resource.group).to eq("wheel")
      expect(provider.new_resource.owner).to eq("root")
      expect(provider.new_resource.mode).to eq("0600")
    end
  end

  context "when reporting security metadata on windows" do
    it "records the file owner" do
      skip
    end

    it "records rights for each user in the ACL" do
      skip
    end

    it "records deny_rights for each user in the ACL" do
      skip
    end
  end

  context "define_resource_requirements" do
    context "when the enclosing directory does not exist" do
      before { setup_missing_enclosing_directory }

      %i{create create_if_missing touch}.each do |action|
        context "action #{action}" do
          it "raises EnclosingDirectoryDoesNotExist" do
            expect { provider.run_action(action) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
          end

          it "does not raise an exception in why-run mode" do
            Chef::Config[:why_run] = true
            expect { provider.run_action(action) }.not_to raise_error
            Chef::Config[:why_run] = false
          end
        end
      end
    end

    context "when the file exists but is not deletable" do
      before { setup_unwritable_file }

      it "action delete raises InsufficientPermissions" do
        expect { provider.run_action(:delete) }.to raise_error(Chef::Exceptions::InsufficientPermissions)
      end

      it "action delete also raises InsufficientPermissions in why-run mode" do
        Chef::Config[:why_run] = true
        expect { provider.run_action(:delete) }.to raise_error(Chef::Exceptions::InsufficientPermissions)
        Chef::Config[:why_run] = false
      end
    end
  end

  context "action create" do
    it "should create the file, update its contents and then set the acls on the file" do
      setup_missing_file
      expect(provider).to receive(:do_create_file)
      expect(provider).to receive(:do_contents_changes)
      expect(provider).to receive(:do_acl_changes)
      expect(provider).to receive(:load_resource_attributes_from_file)
      provider.run_action(:create)
    end

    context "do_validate_content" do

      let(:tempfile_name) { "foo-bar-baz" }
      let(:backupfile) { "/tmp/failed_validations/#{tempfile_name}" }
      let(:tempfile) do
        t = double("Tempfile", path: "/tmp/#{tempfile_name}", closed?: true)
        allow(content).to receive(:tempfile).and_return(t)
        t
      end

      before do
        Chef::Config[:file_cache_path] = "/tmp"
        allow(File).to receive(:dirname).and_return(tempfile)
        allow(File).to receive(:basename).and_return(tempfile_name)
        allow(FileUtils).to receive(:mkdir_p).and_return(true)
        allow(FileUtils).to receive(:cp).and_return(true)
        setup_normal_file
      end

      context "with user-supplied verifications" do
        it "calls #verify on each verification with tempfile path" do
          provider.new_resource.verify windows? ? "REM" : "true"
          provider.new_resource.verify windows? ? "REM" : "true"
          allow(provider).to receive(:contents_changed?).and_return(true)
          provider.send(:do_validate_content)
        end

        it "raises an exception if any verification fails" do
          allow(File).to receive(:directory?).with("C:\\Windows\\system32/cmd.exe").and_return(false)
          allow(provider).to receive(:tempfile).and_return(tempfile)
          allow(provider).to receive(:contents_changed?).and_return(true)
          provider.new_resource.verify windows? ? "cmd.exe c exit 1" : "false"
          provider.new_resource.verify.each do |v|
            allow(v).to receive(:verify).and_return(false)
          end
          expect { provider.send(:do_validate_content) }.to raise_error(Chef::Exceptions::ValidationFailed)
        end

        it "does not run verifications when the contents did not change" do
          allow(File).to receive(:directory?).with("C:\\Windows\\system32/cmd.exe").and_return(false)
          allow(provider).to receive(:tempfile).and_return(tempfile)
          allow(provider).to receive(:contents_changed?).and_return(false)
          provider.new_resource.verify windows? ? "cmd.exe c exit 1" : "false"
          provider.new_resource.verify.each do |v|
            expect(v).not_to receive(:verify)
          end
          provider.send(:do_validate_content)
        end

        it "does not show verification for sensitive resources" do
          allow(File).to receive(:directory?).with("C:\\Windows\\system32/cmd.exe").and_return(false)
          allow(provider).to receive(:tempfile).and_return(tempfile)
          allow(provider).to receive(:contents_changed?).and_return(true)
          provider.new_resource.sensitive true
          provider.new_resource.verify windows? ? "cmd.exe c exit 1" : "false"
          provider.new_resource.verify.each do |v|
            allow(v).to receive(:verify).and_return(false)
          end
          expect { provider.send(:do_validate_content) }.to raise_error(Chef::Exceptions::ValidationFailed, /sensitive/)
        end
      end
    end

    context "do_create_file" do
      context "when the file exists" do
        before { setup_normal_file }
        it "should not create the file" do
          provider.load_current_resource
          expect(provider.deployment_strategy).not_to receive(:create).with(resource_path)
          provider.send(:do_create_file)
          expect(provider.send(:needs_creating?)).to eq(false)
        end
      end
      context "when the file does not exist" do
        before { setup_missing_file }
        it "should create the file" do
          provider.load_current_resource
          expect(provider.deployment_strategy).to receive(:create).with(resource_path)
          provider.send(:do_create_file)
          expect(provider.send(:needs_creating?)).to eq(true)
        end
      end
    end

    context "do_contents_changes" do
      context "when there is content to deploy" do
        before do
          setup_normal_file
          provider.load_current_resource
          tempfile = double("Tempfile", path: "/tmp/foo-bar-baz")
          allow(content).to receive(:tempfile).and_return(tempfile)
          expect(File).to receive(:exists?).with("/tmp/foo-bar-baz").and_return(true)
          expect(tempfile).to receive(:close).once
          expect(tempfile).to receive(:unlink).once
        end

        context "when the contents have changed" do
          let(:tempfile_path) { "/tmp/foo-bar-baz" }
          let(:tempfile_sha256) { "42971f0ddce0cb20cf7660a123ffa1a1543beb2f1e7cd9d65858764a27f3201d" }
          let(:diff_for_reporting) { "+++\n---\n+foo\n-bar\n" }
          before do
            allow(provider).to receive(:contents_changed?).and_return(true)
            diff = double("Diff", for_output: ["+++", "---", "+foo", "-bar"],
                                  for_reporting: diff_for_reporting )
            allow(diff).to receive(:diff).with(resource_path, tempfile_path).and_return(true)
            expect(provider).to receive(:diff).at_least(:once).and_return(diff)
            expect(provider).to receive(:checksum).with(tempfile_path).and_return(tempfile_sha256)
            allow(provider).to receive(:managing_content?).and_return(true)
            allow(provider).to receive(:checksum).with(resource_path).and_return(tempfile_sha256)
            expect(resource).not_to receive(:checksum).with(tempfile_sha256) # do not mutate the new resource
            expect(provider.deployment_strategy).to receive(:deploy).with(tempfile_path, normalized_path)
          end
          context "when the file was created" do
            before { expect(provider).to receive(:needs_creating?).at_least(:once).and_return(true) }
            it "does not backup the file" do
              expect(provider).not_to receive(:do_backup)
              provider.send(:do_contents_changes)
            end

            it "does not produce a diff for reporting" do
              provider.send(:do_contents_changes)
              expect(resource.diff).to be_nil
            end

            it "renders the final checksum correctly for reporting" do
              provider.send(:do_contents_changes)
              expect(resource.state_for_resource_reporter[:checksum]).to eql(tempfile_sha256)
            end
          end
          context "when the file was not created" do
            before do
              allow(provider).to receive(:do_backup) # stub do_backup
              expect(provider).to receive(:needs_creating?).at_least(:once).and_return(false)
            end

            it "backs up the file" do
              expect(provider).to receive(:do_backup)
              provider.send(:do_contents_changes)
            end

            it "produces a diff for reporting" do
              provider.send(:do_contents_changes)
              expect(resource.diff).to eq(diff_for_reporting)
            end

            it "renders the final checksum correctly for reporting" do
              provider.send(:do_contents_changes)
              expect(resource.state_for_resource_reporter[:checksum]).to eql(tempfile_sha256)
            end
          end
        end

        it "does nothing when the contents have not changed" do
          allow(provider).to receive(:contents_changed?).and_return(false)
          expect(provider).not_to receive(:diff)
          provider.send(:do_contents_changes)
        end
      end

      it "does nothing when there is no content to deploy (tempfile returned from contents is nil)" do
        expect(provider.send(:content)).to receive(:tempfile).at_least(:once).and_return(nil)
        expect(provider).not_to receive(:diff)
        expect { provider.send(:do_contents_changes) }.not_to raise_error
      end

      it "raises an exception when the content object returns a tempfile with a nil path" do
        tempfile = double("Tempfile", path: nil)
        expect(provider.send(:content)).to receive(:tempfile).at_least(:once).and_return(tempfile)
        expect { provider.send(:do_contents_changes) }.to raise_error(RuntimeError)
      end

      it "raises an exception when the content object returns a tempfile that does not exist" do
        tempfile = double("Tempfile", path: "/tmp/foo-bar-baz")
        expect(provider.send(:content)).to receive(:tempfile).at_least(:once).and_return(tempfile)
        expect(File).to receive(:exists?).with("/tmp/foo-bar-baz").and_return(false)
        expect { provider.send(:do_contents_changes) }.to raise_error(RuntimeError)
      end
    end

    context "do_acl_changes" do
      it "needs tests" do
        skip
      end
    end

    context "do_selinux" do
      context "when resource is updated" do
        before do
          setup_normal_file
          provider.load_current_resource
          allow(provider).to receive(:resource_updated?).and_return(true)
        end

        it "should check for selinux_enabled? by default" do
          expect(provider).to receive(:selinux_enabled?)
          provider.send(:do_selinux)
        end

        context "when selinux fixup is enabled in the config" do
          before do
            @original_selinux_fixup = Chef::Config[:enable_selinux_file_permission_fixup]
            Chef::Config[:enable_selinux_file_permission_fixup] = true
          end

          after do
            Chef::Config[:enable_selinux_file_permission_fixup] = @original_selinux_fixup
          end

          context "when selinux is enabled on the system" do
            before do
              expect(provider).to receive(:selinux_enabled?).and_return(true)
            end

            it "restores security context on the file" do
              expect(provider).to receive(:restore_security_context).with(normalized_path, false)
              provider.send(:do_selinux)
            end

            it "restores security context recursively when told so" do
              expect(provider).to receive(:restore_security_context).with(normalized_path, true)
              provider.send(:do_selinux, true)
            end
          end

          context "when selinux is disabled on the system" do
            before do
              expect(provider).to receive(:selinux_enabled?).and_return(false)
            end

            it "should not restore security context" do
              expect(provider).not_to receive(:restore_security_context)
              provider.send(:do_selinux)
            end
          end
        end

        context "when selinux fixup is disabled in the config" do
          before do
            @original_selinux_fixup = Chef::Config[:enable_selinux_file_permission_fixup]
            Chef::Config[:enable_selinux_file_permission_fixup] = false
          end

          after do
            Chef::Config[:enable_selinux_file_permission_fixup] = @original_selinux_fixup
          end

          it "should not check for selinux_enabled?" do
            expect(provider).not_to receive(:selinux_enabled?)
            provider.send(:do_selinux)
          end
        end
      end

      context "when resource is not updated" do
        before do
          allow(provider).to receive(:resource_updated?).and_return(false)
        end

        it "should not check for selinux_enabled?" do
          expect(provider).not_to receive(:selinux_enabled?)
          provider.send(:do_selinux)
        end
      end
    end

    context "in why run mode" do
      before { Chef::Config[:why_run] = true }
      after { Chef::Config[:why_run] = false }

      it "does not modify new_resource" do
        setup_missing_file
        expect(provider).not_to receive(:load_resource_attributes_from_file).with(provider.new_resource)
        provider.run_action(:create)
      end
    end
  end

  context "action delete" do
    context "when the file exists" do
      context "when the file is writable" do
        context "when the file is not a symlink" do
          before { setup_normal_file }
          it "should backup and delete the file and be updated by the last action" do
            expect(provider).to receive(:do_backup).at_least(:once).and_return(true)
            expect(File).to receive(:delete).with(resource_path).and_return(true)
            provider.run_action(:delete)
            expect(resource).to be_updated_by_last_action
          end
        end
        context "when the file is a symlink" do
          before { setup_symlink }
          it "should not backup the symlink" do
            expect(provider).not_to receive(:do_backup)
            expect(File).to receive(:delete).with(resource_path).and_return(true)
            provider.run_action(:delete)
            expect(resource).to be_updated_by_last_action
          end
        end
      end
      context "when the file is not writable" do
        before { setup_unwritable_file }
        it "should not try to backup or delete the file, and should not be updated by last action" do
          expect(provider).not_to receive(:do_backup)
          expect(File).not_to receive(:delete)
          expect { provider.run_action(:delete) }.to raise_error(Chef::Exceptions::InsufficientPermissions)
          expect(resource).not_to be_updated_by_last_action
        end
      end
    end

    context "when the file does not exist" do
      before { setup_missing_file }

      it "should not try to backup or delete the file, and should not be updated by last action" do
        expect(provider).not_to receive(:do_backup)
        expect(File).not_to receive(:delete)
        expect { provider.run_action(:delete) }.not_to raise_error
        expect(resource).not_to be_updated_by_last_action
      end
    end
  end

  context "action touch" do
    context "when the file does not exist" do
      before { setup_missing_file }
      it "should update the atime/mtime on action_touch" do
        expect(File).to receive(:utime).once
        expect(provider).to receive(:action_create)
        provider.run_action(:touch)
        expect(resource).to be_updated_by_last_action
      end
    end
    context "when the file exists" do
      before { setup_normal_file }
      it "should update the atime/mtime on action_touch" do
        expect(File).to receive(:utime).once
        expect(provider).to receive(:action_create)
        provider.run_action(:touch)
        expect(resource).to be_updated_by_last_action
      end
    end
  end

  context "action create_if_missing" do
    context "when the file does not exist" do
      before { setup_missing_file }
      it "should call action_create" do
        expect(provider).to receive(:action_create)
        provider.run_action(:create_if_missing)
      end
    end

    context "when the file exists" do
      before { setup_normal_file }
      it "should not call action_create" do
        expect(provider).not_to receive(:action_create)
        provider.run_action(:create_if_missing)
      end
    end

  end

end

shared_examples_for "a file provider with content field" do
  context "when testing managing_content?" do
    it "should be false when creating a file without content" do
      provider.action = :create
      allow(resource).to receive(:content).and_return(nil)
      allow(resource).to receive(:checksum).and_return(nil)
      expect(provider.send(:managing_content?)).to be_falsey
    end
    it "should be true when creating a file with content" do
      provider.action = :create
      allow(resource).to receive(:content).and_return("flurbleblobbleblooble")
      allow(resource).to receive(:checksum).and_return(nil)
      expect(provider.send(:managing_content?)).to be_truthy
    end
    it "should be true when checksum is set on the content (no matter how crazy)" do
      provider.action = :create_if_missing
      allow(resource).to receive(:checksum).and_return("1234123234234234")
      allow(resource).to receive(:content).and_return(nil)
      expect(provider.send(:managing_content?)).to be_truthy
    end
    it "should be false when action is create_if_missing" do
      provider.action = :create_if_missing
      allow(resource).to receive(:content).and_return("flurbleblobbleblooble")
      allow(resource).to receive(:checksum).and_return(nil)
      expect(provider.send(:managing_content?)).to be_falsey
    end
  end
end

shared_examples_for "a file provider with source field" do
  context "when testing managing_content?" do
    it "should be false when creating a file without content" do
      provider.action = :create
      allow(resource).to receive(:content).and_return(nil)
      allow(resource).to receive(:source).and_return(nil)
      allow(resource).to receive(:checksum).and_return(nil)
      expect(provider.send(:managing_content?)).to be_falsey
    end
    it "should be true when creating a file with content" do
      provider.action = :create
      allow(resource).to receive(:content).and_return(nil)
      allow(resource).to receive(:source).and_return("http://somewhere.com/something.php")
      allow(resource).to receive(:checksum).and_return(nil)
      expect(provider.send(:managing_content?)).to be_truthy
    end
    it "should be true when checksum is set on the content (no matter how crazy)" do
      provider.action = :create_if_missing
      allow(resource).to receive(:content).and_return(nil)
      allow(resource).to receive(:source).and_return(nil)
      allow(resource).to receive(:checksum).and_return("1234123234234234")
      expect(provider.send(:managing_content?)).to be_truthy
    end
    it "should be false when action is create_if_missing" do
      provider.action = :create_if_missing
      allow(resource).to receive(:content).and_return(nil)
      allow(resource).to receive(:source).and_return("http://somewhere.com/something.php")
      allow(resource).to receive(:checksum).and_return(nil)
      expect(provider.send(:managing_content?)).to be_falsey
    end
  end
end
