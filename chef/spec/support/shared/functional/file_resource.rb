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

shared_examples_for "a file with the wrong content" do
  it "overwrites the file with the updated content when the :create action is run" do
    Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH
    sleep 1
    resource.run_action(:create)
    File.stat(path).mtime.should > @expected_mtime
    sha256_checksum(path).should_not == @expected_checksum
  end

  it "doesn't overwrite the file when the :create_if_missing action is run" do
    sleep 1
    resource.run_action(:create_if_missing)
    File.stat(path).mtime.should == @expected_mtime
    sha256_checksum(path).should == @expected_checksum
  end

  it "should backup the existing file" do
    Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH
    resource.run_action(:create)
    Dir.glob(backup_glob).size.should equal(1)
  end

  it "should not attempt to backup the existing file if :backup == 0" do
    Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH
    resource.backup(0)
    resource.run_action(:create)
    Dir.glob(backup_glob).size.should equal(0)
  end

  it "deletes the file when the :delete action is run" do
    resource.run_action(:delete)
    File.should_not exist(path)
  end
end

shared_examples_for "a file with the correct content" do
  it "does not overwrite the original when the :create action is run" do
    resource.run_action(:create)
    sha256_checksum(path).should == @expected_checksum
  end

  it "does not update the mtime/atime of the file when the :create action is run" do
    sleep 1
    File.stat(path).mtime.should == @expected_mtime
    File.stat(path).atime.should be_within(2).of(@expected_atime)
  end

  it "doesn't overwrite the file when the :create_if_missing action is run" do
    resource.run_action(:create_if_missing)
    sha256_checksum(path).should == @expected_checksum
  end

  it "deletes the file when the :delete action is run" do
    resource.run_action(:delete)
    File.should_not exist(path)
  end
end

shared_examples_for "a file resource" do
   # note the stripping of the drive letter from the tmpdir on windows
  let(:backup_glob) { File.join(CHEF_SPEC_BACKUP_PATH, Dir.tmpdir.sub(/^([A-Za-z]:)/, ""), "#{file_base}*") }

  def binread(file)
    content = File.open(file, "rb") do |f|
      f.read
    end
    content.force_encoding(Encoding::BINARY) if "".respond_to?(:force_encoding)
    content
  end

  context "when the target file does not exist" do
    it "creates the file when the :create action is run" do
      resource.run_action(:create)
      File.should exist(path)
    end

    it "creates the file with the correct content when the :create action is run" do
      resource.run_action(:create)
      binread(path).should == expected_content
    end

    it "creates the file with the correct content when the :create_if_missing action is run" do
      resource.run_action(:create_if_missing)
      binread(path).should == expected_content
    end

    it "deletes the file when the :delete action is run" do
      resource.run_action(:delete)
      File.should_not exist(path)
    end
  end

  # Set up the context for security tests
  def allowed_acl(sid, expected_perms)
    [ ACE.access_allowed(sid, expected_perms[:specific]) ]
  end

  def denied_acl(sid, expected_perms)
    [ ACE.access_denied(sid, expected_perms[:specific]) ]
  end


  context "when the target file has the wrong content" do
    before(:each) do
      File.open(path, "wb") { |f| f.print "This is so wrong!!!" }
      @expected_mtime = File.stat(path).mtime
      @expected_checksum = sha256_checksum(path)
    end

    describe "and the target file has the correct permissions" do
      include_context "setup correct permissions"

      it_behaves_like "a file with the wrong content"

      it_behaves_like "a securable resource"
    end

    context "and the target file has incorrect permissions" do
      include_context "setup broken permissions"

      it_behaves_like "a file with the wrong content"
  
      it_behaves_like "a securable resource"
    end
  end

  context "when the target file has the correct content" do
    before(:each) do
      File.open(path, "wb") { |f| f.print expected_content }
      @expected_mtime = File.stat(path).mtime
      @expected_atime = File.stat(path).atime
      @expected_checksum = sha256_checksum(path)
    end

    describe "and the target file has the correct permissions" do
      include_context "setup correct permissions"

      it_behaves_like "a file with the correct content"

      it_behaves_like "a securable resource"
    end

    context "and the target file has incorrect permissions" do
      include_context "setup broken permissions"

      it_behaves_like "a file with the correct content"
  
      it_behaves_like "a securable resource"
    end
  end

end

shared_context Chef::Resource::File  do
  let(:path) do
    File.join(Dir.tmpdir, make_tmpname(file_base, nil))
  end

  after(:each) do
    FileUtils.rm_r(path) if File.exists?(path)
    FileUtils.rm_r(CHEF_SPEC_BACKUP_PATH) if File.exists?(CHEF_SPEC_BACKUP_PATH)
  end
end
