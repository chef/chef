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

shared_examples_for "a content deploy strategy" do

  # Ruby 1.8 has no binread
  def binread(file)
    if IO.respond_to?(:binread)
      IO.binread(file)
    else
      IO.read(file)
    end
  end

  def normalize_mode(mode_int)
    ( mode_int & 07777).to_s(8)
  end

  let(:sandbox_dir) do
    basename = make_tmpname("content-deploy-tests")
    full_path = File.join(CHEF_SPEC_DATA, basename)
    FileUtils.mkdir_p(full_path)
    full_path
  end

  after do
    FileUtils.rm_rf(sandbox_dir) if File.exist?(sandbox_dir)
  end

  let(:content_deployer) { described_class.new }
  let(:target_file_path) { File.join(sandbox_dir, "cp-deploy-strategy-target-file.txt") }


  describe "creating the file" do

    ##
    # UNIX Context
    let(:default_mode) { normalize_mode(0100666 - File.umask) }

    it "touches the file to create it (UNIX)", :unix_only do
      content_deployer.create(target_file_path)
      File.should exist(target_file_path)
      file_info = File.stat(target_file_path)
      file_info.should be_owned
      file_info.should be_file
      normalize_mode(file_info.mode).should == default_mode
    end

    ##
    # Window Context
    let(:parent_dir) { File.dirname(target_file_path) }

    let(:parent_security_descriptor) do
      security_obj = Chef::ReservedNames::Win32::Security::SecurableObject.new(parent_dir)
      security_obj.security_descriptor(true)
    end

    let(:masks) do
      Chef::ReservedNames::Win32::API::Security
    end

    def ace_inherits?(ace)
      flags = ace.flags
      (flags & masks::OBJECT_INHERIT_ACE) !=0
    end

    let(:parent_inheritable_aces) do
      inheritable_aces = parent_security_descriptor.dacl.select do |ace|
        ace_inherits?(ace)
      end
    end

    # Win2003 has annoying differences in ACL inheritance behavior that make
    # the default ACLs substantially different from those created on subsequent
    # windows versions. The behaviors here are also covered by resource-level
    # tests so we'll skip win2k3 here to keep the tests simple.
    it "touches the file to create it (Windows)", :windows_only, :not_supported_on_win2k3 do
      content_deployer.create(target_file_path)
      File.should exist(target_file_path)
      file_info = File.stat(target_file_path)
      file_info.should be_owned
      file_info.should be_file

      parent_aces = parent_inheritable_aces
      security_obj = Chef::ReservedNames::Win32::Security::SecurableObject.new(target_file_path)

      security_descriptor = security_obj.security_descriptor(true)
      security_descriptor.dacl.each_with_index do |ace, index|
        ace.inherited?.should be_true
        ace.mask.should == parent_aces[index].mask
      end

    end
  end

  describe "updating the file" do

    let(:staging_dir) { Dir.mktmpdir }

    let(:staging_file_content) { "this is the expected content" }

    let(:staging_file_path) do
      path = File.join(staging_dir, "cp-deploy-strategy-staging-file.txt")
      File.open(path, "w+", 0600) { |f| f.print(staging_file_content) }
      path
    end

    def unix_invariant_properies(stat_struct)
      unix_invariants.inject({}) do |property_map, property|
        property_map[property] = stat_struct.send(property)
        property_map
      end
    end

    def win_invariant_properties(sec_obj)
      descriptor = sec_obj.security_descriptor(true)
      security_descriptor_invariants.inject({}) do |prop_map, property|
        prop_map[property] = descriptor.send(property)
        prop_map
       end
    end

    before do
      content_deployer.create(target_file_path)
    end

    it "maintains invariant properties on UNIX", :unix_only do
      original_info = File.stat(target_file_path)
      content_deployer.deploy(staging_file_path, target_file_path)
      updated_info = File.stat(target_file_path)

      unix_invariant_properies(original_info).should == unix_invariant_properies(updated_info)
    end

    it "maintains invariant properties on Windows", :windows_only do
      original_info = Chef::ReservedNames::Win32::Security::SecurableObject.new(target_file_path)
      content_deployer.deploy(staging_file_path, target_file_path)
      updated_info = Chef::ReservedNames::Win32::Security::SecurableObject.new(target_file_path)

      win_invariant_properties(original_info).should == win_invariant_properties(updated_info)
    end

    it "updates the target with content from staged" do
      content_deployer.deploy(staging_file_path, target_file_path)
      binread(target_file_path).should == staging_file_content
    end

    context "when the owner of the target file is not the owner of the staging file", :requires_root do

      before do
        File.chown(1337, 1337, target_file_path)
      end

      it "copies the staging file's content" do
        original_info = File.stat(target_file_path)
        content_deployer.deploy(staging_file_path, target_file_path)
        updated_info = File.stat(target_file_path)

        unix_invariant_properies(original_info).should == unix_invariant_properies(updated_info)
      end

    end

  end
end

describe Chef::FileContentManagement::Deploy::Cp do

  let(:unix_invariants) do
    [
      :uid,
      :gid,
      :mode,
      :ino
    ]
  end

  let(:security_descriptor_invariants) do
    [
      :owner,
      :group,
      :dacl
    ]
  end

  it_should_behave_like "a content deploy strategy"

end

describe Chef::FileContentManagement::Deploy::MvUnix, :unix_only do

  let(:unix_invariants) do
    [
      :uid,
      :gid,
      :mode
    ]
  end

  it_should_behave_like "a content deploy strategy"
end

# On Unix we won't have loaded the file, avoid undefined constant errors:
class Chef::FileContentManagement::Deploy::MvWindows ; end

describe Chef::FileContentManagement::Deploy::MvWindows, :windows_only do

  context "when a file has no sacl" do

    let(:security_descriptor_invariants) do
      [
       :owner,
       :group,
       :dacl
      ]
    end

    it_should_behave_like "a content deploy strategy"
  end

end
