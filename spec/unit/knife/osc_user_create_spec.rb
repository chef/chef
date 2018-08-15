#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

Chef::Knife::OscUserCreate.load_deps

# DEPRECATION NOTE
# This code only remains to support users still operating with
# Open Source Chef Server 11 and should be removed once support
# for OSC 11 ends. New development should occur in user_create_spec.rb.

describe Chef::Knife::OscUserCreate do
  before(:each) do
    @knife = Chef::Knife::OscUserCreate.new

    @stdout = StringIO.new
    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)

    @knife.name_args = [ "a_user" ]
    @knife.config[:user_password] = "foobar"
    @user = Chef::User.new
    @user.name "a_user"
    @user_with_private_key = Chef::User.new
    @user_with_private_key.name "a_user"
    @user_with_private_key.private_key "private_key"
    allow(@user).to receive(:create).and_return(@user_with_private_key)
    allow(Chef::User).to receive(:new).and_return(@user)
    allow(Chef::User).to receive(:from_hash).and_return(@user)
    allow(@knife).to receive(:edit_hash).and_return(@user.to_hash)
  end

  it "creates a new user" do
    expect(Chef::User).to receive(:new).and_return(@user)
    expect(@user).to receive(:create)
    @knife.run
    expect(@stderr.string).to match /created user.+a_user/i
  end

  it "sets the password" do
    @knife.config[:user_password] = "a_password"
    expect(@user).to receive(:password).with("a_password")
    @knife.run
  end

  it "exits with an error if password is blank" do
    @knife.config[:user_password] = ""
    expect { @knife.run }.to raise_error SystemExit
    expect(@stderr.string).to match /You must specify a non-blank password/
  end

  it "sets the user name" do
    expect(@user).to receive(:name).with("a_user")
    @knife.run
  end

  it "sets the public key if given" do
    @knife.config[:user_key] = "/a/filename"
    allow(File).to receive(:read).with(File.expand_path("/a/filename")).and_return("a_key")
    expect(@user).to receive(:public_key).with("a_key")
    @knife.run
  end

  it "allows you to edit the data" do
    expect(@knife).to receive(:edit_hash).with(@user)
    @knife.run
  end

  it "writes the private key to a file when --file is specified" do
    @knife.config[:file] = "/tmp/a_file"
    filehandle = double("filehandle")
    expect(filehandle).to receive(:print).with("private_key")
    expect(File).to receive(:open).with("/tmp/a_file", "w").and_yield(filehandle)
    @knife.run
  end
end
