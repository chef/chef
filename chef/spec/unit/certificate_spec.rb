#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

require 'chef/certificate'
require 'ostruct'
require 'tempfile'

class FakeFile
  attr_accessor :data

  def write(arg)
    @data = arg
  end
end

describe Chef::Certificate do
  describe "generate_signing_ca" do
    before(:each) do
      Chef::Config[:signing_ca_user] = nil
      Chef::Config[:signing_ca_group] = nil
      FileUtils.stub!(:mkdir_p).and_return(true)
      FileUtils.stub!(:chown).and_return(true)
      File.stub!(:open).and_return(true)
      File.stub!(:exists?).and_return(false)
      @ca_cert = FakeFile.new 
      @ca_key = FakeFile.new 
    end

    it "should generate a ca certificate" do
      File.should_receive(:open).with(Chef::Config[:signing_ca_cert], "w").and_yield(@ca_cert)
      Chef::Certificate.generate_signing_ca
      @ca_cert.data.should =~ /BEGIN CERTIFICATE/
    end
    
    it "should generate an RSA private key" do
      File.should_receive(:open).with(Chef::Config[:signing_ca_key], File::WRONLY|File::EXCL|File::CREAT, 0600).and_yield(@ca_key)
      FileUtils.should_not_receive(:chown)
      Chef::Certificate.generate_signing_ca
      @ca_key.data.should =~ /BEGIN RSA PRIVATE KEY/
    end

    it "should generate an RSA private key with user and group" do
      Chef::Config[:signing_ca_user] = "funky"
      Chef::Config[:signing_ca_group] = "fresh"
      File.should_receive(:open).with(Chef::Config[:signing_ca_key], File::WRONLY|File::EXCL|File::CREAT, 0600).and_yield(@ca_key)
      FileUtils.should_receive(:chown).with(Chef::Config[:signing_ca_user], Chef::Config[:signing_ca_group], Chef::Config[:signing_ca_key])
      Chef::Certificate.generate_signing_ca
      @ca_key.data.should =~ /BEGIN RSA PRIVATE KEY/
    end
  end

  describe "generate_keypair" do
    it "should return a client certificate" do
      public_key, private_key = Chef::Certificate.gen_keypair("oasis")
      public_key.to_s.should =~ /(BEGIN RSA PUBLIC KEY|BEGIN PUBLIC KEY)/
      private_key.to_s.should =~ /BEGIN RSA PRIVATE KEY/
    end
  end
end
