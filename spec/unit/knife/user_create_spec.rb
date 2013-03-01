#
# Author:: Steven Danna (<steve@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

Chef::Knife::UserCreate.load_deps

describe Chef::Knife::UserCreate do
  before(:each) do
    @knife = Chef::Knife::UserCreate.new
    @knife.name_args = [ 'a_user' ]
    @knife.config[:user_password] = "foobar"
    @user = Chef::User.new
    @user.name "a_user"
    @user_with_private_key = Chef::User.new
    @user_with_private_key.name "a_user"
    @user_with_private_key.private_key 'private_key'
    @user.stub!(:create).and_return(@user_with_private_key)
    Chef::User.stub!(:new).and_return(@user)
    Chef::User.stub!(:from_hash).and_return(@user)
    @knife.stub!(:edit_data).and_return(@user.to_hash)
    @stdout = StringIO.new
    @stderr = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @knife.ui.stub!(:stderr).and_return(@stderr)
  end

  it "creates a new user" do
    Chef::User.should_receive(:new).and_return(@user)
    @user.should_receive(:create)
    @knife.run
    @stdout.string.should match /created user.+a_user/i
  end

  it "sets the password" do
    @knife.config[:user_password] = "a_password"
    @user.should_receive(:password).with("a_password")
    @knife.run
  end

  it "exits with an error if password is blank" do
    @knife.config[:user_password] = ''
    lambda { @knife.run }.should raise_error SystemExit
    @stderr.string.should match /You must specify a non-blank password/
  end

  it "sets the user name" do
    @user.should_receive(:name).with("a_user")
    @knife.run
  end

  it "sets the public key if given" do
    @knife.config[:user_key] = "/a/filename"
    File.stub(:read).with(File.expand_path("/a/filename")).and_return("a_key")
    @user.should_receive(:public_key).with("a_key")
    @knife.run
  end

  it "allows you to edit the data" do
    @knife.should_receive(:edit_data).with(@user)
    @knife.run
  end

  it "writes the private key to a file when --file is specified" do
    @knife.config[:file] = "/tmp/a_file"
    filehandle = mock("filehandle")
    filehandle.should_receive(:print).with('private_key')
    File.should_receive(:open).with("/tmp/a_file", "w").and_yield(filehandle)
    @knife.run
  end
end
