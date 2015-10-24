#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2010 Daniel DeLeo
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
require 'digest/md5'
require 'tmpdir'
require 'chef/mixin/file_class'

class Chef::CFCCheck
  include Chef::Mixin::FileClass
end

describe Chef::Provider::RemoteDirectory do
  before do
    allow_any_instance_of(Chef::FileAccessControl).to receive(:set_all)

    @resource = Chef::Resource::RemoteDirectory.new(File.join(Dir.tmpdir, "tafty"))
    # in CHEF_SPEC_DATA/cookbooks/openldap/files/default/remotedir
    @resource.source "remotedir"
    @resource.cookbook('openldap')

    @cookbook_repo = ::File.expand_path(::File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.fetch_from_disk(@cookbook_repo)

    @node = Chef::Node.new
    cl = Chef::CookbookLoader.new(@cookbook_repo)
    cl.load_cookbooks
    @cookbook_collection = Chef::CookbookCollection.new(cl)

    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @provider = Chef::Provider::RemoteDirectory.new(@resource, @run_context)
    @provider.current_resource = @resource.clone
  end

  describe "when the contents of the directory changed on the first run and not on the second run" do
    before do
      @resource_second_run = @resource.clone
      @provider_second_run = Chef::Provider::RemoteDirectory.new(@resource_second_run, @run_context)
      @provider.run_action(:create)
      @provider_second_run.run_action(:create)
    end
    it "identifies that the state has changed the after first run" do
      @provider_second_run.new_resource.updated_by_last_action? == true
    end
    it "identifies that the state has not changed after the second run" do
      @provider_second_run.new_resource.updated_by_last_action? == false
    end
  end

  describe "when access control is configured on the resource" do
    before do
      @resource.mode  "0750"
      @resource.group "wheel"
      @resource.owner "root"

      @resource.files_mode  "0640"
      @resource.files_group "staff"
      @resource.files_owner "toor"
      @resource.files_backup 23

      @resource.source "remotedir_root"
    end

    it "configures access control on intermediate directorys" do
      directory_resource = @provider.send(:directory_resource, File.join(Dir.tmpdir, "intermediate_dir"))
      expect(directory_resource.path).to  eq(File.join(Dir.tmpdir, "intermediate_dir"))
      expect(directory_resource.mode).to  eq("0750")
      expect(directory_resource.group).to eq("wheel")
      expect(directory_resource.owner).to eq("root")
      expect(directory_resource.recursive).to be_truthy
    end

    it "configures access control on files in the directory" do
      @resource.cookbook "berlin_style_tasty_cupcakes"
      cookbook_file = @provider.send(:cookbook_file_resource,
                                    "/target/destination/path.txt",
                                    "relative/source/path.txt")
      expect(cookbook_file.cookbook_name).to  eq("berlin_style_tasty_cupcakes")
      expect(cookbook_file.source).to         eq("remotedir_root/relative/source/path.txt")
      expect(cookbook_file.mode).to           eq("0640")
      expect(cookbook_file.group).to          eq("staff")
      expect(cookbook_file.owner).to          eq("toor")
      expect(cookbook_file.backup).to         eq(23)
    end
  end

  describe "when creating the remote directory" do
    before do
      @node.automatic_attrs[:platform] = :just_testing
      @node.automatic_attrs[:platform_version] = :just_testing

      @destination_dir = Dir.mktmpdir << "/remote_directory_test"
      @resource.path(@destination_dir)
    end

    after {FileUtils.rm_rf(@destination_dir)}

    # CHEF-3552
    it "creates the toplevel directory without error " do
      @resource.recursive(false)
      @provider.run_action(:create)
      expect(::File.exist?(@destination_dir)).to be_truthy
    end

    it "transfers the directory with all contents" do
      @provider.run_action(:create)
      expect(::File.exist?(@destination_dir + '/remote_dir_file1.txt')).to be_truthy
      expect(::File.exist?(@destination_dir + '/remote_dir_file2.txt')).to be_truthy
      expect(::File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file1.txt')).to be_truthy
      expect(::File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file2.txt')).to be_truthy
      expect(::File.exist?(@destination_dir + '/remotesubdir/.a_dotfile')).to be_truthy
      expect(::File.exist?(@destination_dir + '/.a_dotdir/.a_dotfile_in_a_dotdir')).to be_truthy
    end

    describe "only if it is missing" do
      it "should not overwrite existing files" do
        @resource.overwrite(true)
        @provider.run_action(:create)

        File.open(@destination_dir + '/remote_dir_file1.txt', 'a') {|f| f.puts "blah blah blah" }
        File.open(@destination_dir + '/remotesubdir/remote_subdir_file1.txt', 'a') {|f| f.puts "blah blah blah" }
        file1md5 = Digest::MD5.hexdigest(File.read(@destination_dir + '/remote_dir_file1.txt'))
        subdirfile1md5 = Digest::MD5.hexdigest(File.read(@destination_dir + '/remotesubdir/remote_subdir_file1.txt'))

        @provider.run_action(:create_if_missing)

        expect(file1md5.eql?(Digest::MD5.hexdigest(File.read(@destination_dir + '/remote_dir_file1.txt')))).to be_truthy
        expect(subdirfile1md5.eql?(Digest::MD5.hexdigest(File.read(@destination_dir + '/remotesubdir/remote_subdir_file1.txt')))).to be_truthy
      end
    end

    describe "with purging enabled" do
      before {@resource.purge(true)}

      it "removes existing files if purge is true" do
        @provider.run_action(:create)
        FileUtils.touch(@destination_dir + '/marked_for_death.txt')
        FileUtils.touch(@destination_dir + '/remotesubdir/marked_for_death_again.txt')
        @provider.run_action(:create)

        expect(::File.exist?(@destination_dir + '/remote_dir_file1.txt')).to be_truthy
        expect(::File.exist?(@destination_dir + '/remote_dir_file2.txt')).to be_truthy
        expect(::File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file1.txt')).to be_truthy
        expect(::File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file2.txt')).to be_truthy

        expect(::File.exist?(@destination_dir + '/marked_for_death.txt')).to be_falsey
        expect(::File.exist?(@destination_dir + '/remotesubdir/marked_for_death_again.txt')).to be_falsey
      end

      it "removes files in subdirectories before files above" do
        @provider.run_action(:create)
        FileUtils.mkdir_p(@destination_dir + '/a/multiply/nested/directory/')
        FileUtils.touch(@destination_dir + '/a/foo.txt')
        FileUtils.touch(@destination_dir + '/a/multiply/bar.txt')
        FileUtils.touch(@destination_dir + '/a/multiply/nested/baz.txt')
        FileUtils.touch(@destination_dir + '/a/multiply/nested/directory/qux.txt')
        @provider.run_action(:create)
        expect(::File.exist?(@destination_dir + '/a/foo.txt')).to be_falsey
        expect(::File.exist?(@destination_dir + '/a/multiply/bar.txt')).to be_falsey
        expect(::File.exist?(@destination_dir + '/a/multiply/nested/baz.txt')).to be_falsey
        expect(::File.exist?(@destination_dir + '/a/multiply/nested/directory/qux.txt')).to be_falsey
      end

      it "removes directory symlinks properly", :not_supported_on_win2k3 do
        symlinked_dir_path = @destination_dir + '/symlinked_dir'
        @provider.action = :create
        @provider.run_action

        @fclass = Chef::CFCCheck.new

        Dir.mktmpdir do |tmp_dir|
          begin
            @fclass.file_class.symlink(tmp_dir.dup, symlinked_dir_path)
            expect(::File.exist?(symlinked_dir_path)).to be_truthy

            @provider.run_action

            expect(::File.exist?(symlinked_dir_path)).to be_falsey
            expect(::File.exist?(tmp_dir)).to be_truthy
          rescue Chef::Exceptions::Win32APIError
            skip "This must be run as an Administrator to create symlinks"
          end
        end
      end
    end

    describe "with overwrite disabled" do
      before {@resource.purge(false)}
      before {@resource.overwrite(false)}

      it "leaves modifications alone" do
        @provider.run_action(:create)
        ::File.open(@destination_dir + '/remote_dir_file1.txt', 'a') {|f| f.puts "blah blah blah" }
        ::File.open(@destination_dir + '/remotesubdir/remote_subdir_file1.txt', 'a') {|f| f.puts "blah blah blah" }
        file1md5 = Digest::MD5.hexdigest(::File.read(@destination_dir + '/remote_dir_file1.txt'))
        subdirfile1md5 = Digest::MD5.hexdigest(::File.read(@destination_dir + '/remotesubdir/remote_subdir_file1.txt'))
        @provider.run_action(:create)
        expect(file1md5.eql?(Digest::MD5.hexdigest(::File.read(@destination_dir + '/remote_dir_file1.txt')))).to be_truthy
        expect(subdirfile1md5.eql?(Digest::MD5.hexdigest(::File.read(@destination_dir + '/remotesubdir/remote_subdir_file1.txt')))).to be_truthy
      end
    end

  end
end
