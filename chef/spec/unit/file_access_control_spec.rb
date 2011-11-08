#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Chef::FileAccessControl do
  before do
    @resource = Chef::Resource::File.new('/tmp/a_file.txt')
    @resource.owner('toor')
    @resource.group('wheel')
    @resource.mode('0400')
    @file_to_manage = '/tmp/different_file.txt'
    @fac = Chef::FileAccessControl.new(@resource, @file_to_manage)
  end

  it "has a resource" do
    @fac.resource.should equal(@resource)
  end

  it "has a file to manage" do
    @fac.file.should == '/tmp/different_file.txt'
  end

  it "is not modified yet" do
    @fac.should_not be_modified
  end

  it "determines the uid of the owner specified by the resource" do
    Etc.should_receive(:getpwnam).with('toor').and_return(OpenStruct.new(:uid => 2342))
    @fac.target_uid.should == 2342
  end

  it "raises a Chef::Exceptions::UserIDNotFound error when Etc can't find the user's name" do
    Etc.should_receive(:getpwnam).with('toor').and_raise(ArgumentError)
    lambda { @fac.target_uid }.should raise_error(Chef::Exceptions::UserIDNotFound, "cannot determine user id for 'toor', does the user exist on this system?")
  end

  it "does not attempt to resolve the uid if the user is not specified" do
    resource = Chef::Resource::File.new("a file")
    fac = Chef::FileAccessControl.new(resource, @file_to_manage)
    fac.target_uid.should be_nil
  end

  it "raises an ArgumentError if the resource's owner is set to something wack" do
    @resource.instance_variable_set(:@owner, :diaf)
    lambda { @fac.target_uid }.should raise_error(ArgumentError)
  end

  it "uses the resource's uid for the target uid when the resource's owner is specified by an integer" do
    @resource.owner(2342)
    @fac.target_uid.should == 2342
  end

  it "wraps uids to their negative complements to correctly handle negative uids" do
    # More: Mac OS X (at least) has negative UIDs for 'nobody' and some other
    # users. Ruby doesn't believe in negative UIDs so you get the diminished radix
    # complement (i.e., it wraps around the maximum size of C unsigned int) of these
    # uids. So we have to get ruby and negative uids to smoke the peace pipe
    # with each other.
    @resource.owner('nobody')
    Etc.should_receive(:getpwnam).with('nobody').and_return(OpenStruct.new(:uid => (4294967294)))
    @fac.target_uid.should == -2
  end

  it "does not wrap uids to their negative complements beyond -9" do
    # More: when OSX userIDs are created by ActiveDirectory sync, it tends to use huge numbers
    #  which had been incorrectly wrapped.  It does not look like the OSX IDs go below -2
    @resource.owner('bigdude')
    Etc.should_receive(:getpwnam).with('bigdude').and_return(OpenStruct.new(:uid => (4294967286)))
    @fac.target_uid.should == 4294967286
  end

  it "sets the file's owner as specified in the resource when the current owner is incorrect" do
    @resource.owner(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:uid => 1234))
    File.should_receive(:chown).with(2342, nil, '/tmp/different_file.txt')
    @fac.set_owner
    @fac.should be_modified
  end

  it "doesn't set the file's owner if it already matches" do
    @resource.owner(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:uid => 2342))
    File.should_not_receive(:chown)
    @fac.set_owner
    @fac.should_not be_modified
  end

  it "determines the gid of the group specified by the resource" do
    Etc.should_receive(:getgrnam).with('wheel').and_return(OpenStruct.new(:gid => 2342))
    @fac.target_gid.should == 2342
  end

  it "uses a user specified gid as the gid" do
    @resource.group(2342)
    @fac.target_gid.should == 2342
  end

  it "raises a Chef::Exceptions::GroupIDNotFound error when Etc can't find the user's name" do
    Etc.should_receive(:getgrnam).with('wheel').and_raise(ArgumentError)
    lambda { @fac.target_gid }.should raise_error(Chef::Exceptions::GroupIDNotFound, "cannot determine group id for 'wheel', does the group exist on this system?")
  end

  it "does not attempt to resolve a gid when none is supplied" do
    resource = Chef::Resource::File.new('crab')
    fac = Chef::FileAccessControl.new(resource, 'somefile')
    fac.target_gid.should be_nil
  end

  it "raises an error when the supplied group name is an alien" do
    @resource.instance_variable_set(:@group, :failburger)
    lambda { @fac.target_gid }.should raise_error(ArgumentError)
  end

  it "sets the file's group as specified in the resource when the group is not correct" do
    @resource.group(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:gid => 815))
    File.should_receive(:chown).with(nil, 2342, '/tmp/different_file.txt')
    @fac.set_group
    @fac.should be_modified
  end

  it "doesnt set the file's group if it is already correct" do
    @resource.group(2342)
    @fac.stub!(:stat).and_return(OpenStruct.new(:gid => 2342))
    File.should_not_receive(:chown)
    @fac.set_group
    @fac.should_not be_modified
  end

  it "uses the supplied mode as octal when it's a string" do
    @resource.mode('444')
    @fac.target_mode.should == 292 # octal 444 => decimal 292
  end

  it "uses the supplied mode verbatim when it's an integer" do
    @resource.mode(00444)
    @fac.target_mode.should == 292
  end

  it "does not try to determine the mode when none is given" do
    resource = Chef::Resource::File.new('blahblah')
    fac = Chef::FileAccessControl.new(resource, 'afile')
    fac.target_mode.should be_nil
  end

  it "sets the file's mode as specified in the resource when the current modes are incorrect" do
    # stat returns modes like 0100644 (octal) => 33188 (decimal)
    @fac.stub!(:stat).and_return(OpenStruct.new(:mode => 33188))
    File.should_receive(:chmod).with(256, '/tmp/different_file.txt')
    @fac.set_mode
    @fac.should be_modified
  end

  it "does not set the file's mode when the current modes are correct" do
    @fac.stub!(:stat).and_return(OpenStruct.new(:mode => 0100400))
    File.should_not_receive(:chmod)
    @fac.set_mode
    @fac.should_not be_modified
  end

  it "sets all access controls on a file" do
    @fac.stub!(:stat).and_return(OpenStruct.new(:owner => 99, :group => 99, :mode => 0100444))
    @resource.mode(0400)
    @resource.owner(0)
    @resource.group(0)
    File.should_receive(:chmod).with(0400, '/tmp/different_file.txt')
    File.should_receive(:chown).with(0, nil, '/tmp/different_file.txt')
    File.should_receive(:chown).with(nil, 0, '/tmp/different_file.txt')
    @fac.set_all
    @fac.should be_modified
  end

end
