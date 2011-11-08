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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require 'digest/md5'

describe Chef::Provider::RemoteDirectory do
  before do
    @resource = Chef::Resource::RemoteDirectory.new("/tmp/tafty")
    # in CHEF_SPEC_DATA/cookbooks/openldap/files/default/remotedir
    @resource.source "remotedir"
    @resource.cookbook('openldap')

    @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, @cookbook_repo) }

    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new(@cookbook_repo))
    @run_context = Chef::RunContext.new(@node, @cookbook_collection)

    @provider = Chef::Provider::RemoteDirectory.new(@resource, @run_context)
    @provider.current_resource = @resource.clone
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
      directory_resource = @provider.send(:resource_for_directory, "/tmp/intermediate_dir")
      directory_resource.path.should  == "/tmp/intermediate_dir"
      directory_resource.mode.should  == "0750"
      directory_resource.group.should == "wheel"
      directory_resource.owner.should == "root"
      directory_resource.recursive.should be_true
    end

    it "configures access control on files in the directory" do
      @resource.cookbook "berlin_style_tasty_cupcakes"
      cookbook_file = @provider.send(:cookbook_file_resource,
                                    "/target/destination/path.txt",
                                    "relative/source/path.txt")
      cookbook_file.cookbook_name.should  == "berlin_style_tasty_cupcakes"
      cookbook_file.source.should         == "remotedir_root/relative/source/path.txt"
      cookbook_file.mode.should           == "0640"
      cookbook_file.group.should          == "staff"
      cookbook_file.owner.should          == "toor"
      cookbook_file.backup.should         == 23
    end
  end

  describe "when creating the remote directory" do
    before do
      @node[:platform] = :just_testing
      @node[:platform_version] = :just_testing

      @destination_dir = Dir.tmpdir + '/remote_directory_test'
      @resource.path(@destination_dir)
    end

    after {FileUtils.rm_rf(@destination_dir)}

    it "transfers the directory with all contents" do
      @provider.action_create
      File.exist?(@destination_dir + '/remote_dir_file1.txt').should be_true
      File.exist?(@destination_dir + '/remote_dir_file2.txt').should be_true
      File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file1.txt').should be_true
      File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file2.txt').should be_true
      File.exist?(@destination_dir + '/remotesubdir/.a_dotfile').should be_true
      File.exist?(@destination_dir + '/.a_dotdir/.a_dotfile_in_a_dotdir').should be_true
    end

    describe "with purging enabled" do
      before {@resource.purge(true)}

      it "removes existing files if purge is true" do
        @provider.action_create
        FileUtils.touch(@destination_dir + '/marked_for_death.txt')
        FileUtils.touch(@destination_dir + '/remotesubdir/marked_for_death_again.txt')
        @provider.action_create

        File.exist?(@destination_dir + '/remote_dir_file1.txt').should be_true
        File.exist?(@destination_dir + '/remote_dir_file2.txt').should be_true
        File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file1.txt').should be_true
        File.exist?(@destination_dir + '/remotesubdir/remote_subdir_file2.txt').should be_true

        File.exist?(@destination_dir + '/marked_for_death.txt').should be_false
        File.exist?(@destination_dir + '/remotesubdir/marked_for_death_again.txt').should be_false
      end

      it "removes files in subdirectories before files above" do
        @provider.action_create
        FileUtils.mkdir_p(@destination_dir + '/a/multiply/nested/directory/')
        FileUtils.touch(@destination_dir + '/a/foo.txt')
        FileUtils.touch(@destination_dir + '/a/multiply/bar.txt')
        FileUtils.touch(@destination_dir + '/a/multiply/nested/baz.txt')
        FileUtils.touch(@destination_dir + '/a/multiply/nested/directory/qux.txt')
        @provider.action_create
        ::File.exist?(@destination_dir + '/a/foo.txt').should be_false
        ::File.exist?(@destination_dir + '/a/multiply/bar.txt').should be_false
        ::File.exist?(@destination_dir + '/a/multiply/nested/baz.txt').should be_false
        ::File.exist?(@destination_dir + '/a/multiply/nested/directory/qux.txt').should be_false
      end
    end

    describe "with overwrite disabled" do
      before {@resource.purge(false)}
      before {@resource.overwrite(false)}

      it "leaves modifications alone" do
        @provider.action_create
        file1 = File.open(@destination_dir + '/remote_dir_file1.txt', 'a')
        file1.puts "blah blah blah"
        file1.close
        subdirfile1 = File.open(@destination_dir + '/remotesubdir/remote_subdir_file1.txt', 'a')
        subdirfile1.puts "blah blah blah"
        subdirfile1.close
        file1md5 = Digest::MD5.hexdigest(File.read(@destination_dir + '/remote_dir_file1.txt'))
        subdirfile1md5 = Digest::MD5.hexdigest(File.read(@destination_dir + '/remotesubdir/remote_subdir_file1.txt'))
        @provider.action_create
        file1md5.eql?(Digest::MD5.hexdigest(File.read(@destination_dir + '/remote_dir_file1.txt'))).should be_true
        subdirfile1md5.eql?(Digest::MD5.hexdigest(File.read(@destination_dir + '/remotesubdir/remote_subdir_file1.txt'))).should be_true
      end
    end

  end
end
