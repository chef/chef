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
require 'models/sandbox_file'

describe ChefServerApi::SandboxFile do
  before do
    @input = StringIO.new
    @params = {:sandbox_id => '1234', :checksum => '2342'}
    @sandbox_file = ChefServerApi::SandboxFile.new(@input, @params)
  end

  describe "when first created" do
    it "gets a sandbox guid from the parameters" do
      @sandbox_file.sandbox_id.should == '1234'
    end

    it "gets a checksum from the provided parameters" do
      @sandbox_file.expected_checksum.should == '2342'
    end

    it "returns the parameters that idendify the resource in the api" do
      @sandbox_file.resource_params.should == {:sandbox_id => '1234', :checksum => '2342'}
    end

    it "loads an existing sandbox from couchdb" do
      Chef::Sandbox.should_receive(:cdb_load).with('1234').once.and_return(:ohai2u)
      @sandbox_file.sandbox.should == :ohai2u
      @sandbox_file.sandbox.should == :ohai2u
    end

    # BadRequest in the controller
    it "is invalid if no sandbox_id is given" do
      @params.delete(:sandbox_id)
      sandbox_file = ChefServerApi::SandboxFile.new(@input, @params)
      sandbox_file.invalid_params?.should_not be_false
      sandbox_file.invalid_params?.should == "Cannot upload file with checksum '2342': you must provide a sandbox_id"
    end

    # BadRequest in the controller
    it "is invalid if no expected checksum is given" do
      @params.delete(:checksum)
      sandbox_file = ChefServerApi::SandboxFile.new(@input, @params)
      sandbox_file.invalid_params?.should_not be_false
      sandbox_file.invalid_params?.should == "Cannot upload file to sandbox '1234': you must provide the file's checksum"
    end

    it "considers the params valid when both the checksum and sandbox_id are provided" do
      @sandbox_file.invalid_params?.should be_false
    end

    # NotFound in the controller
    it "is invalid if the provided sandbox_id doesn't exist in the database" do
      err = Chef::Exceptions::CouchDBNotFound.new "Cannot find sandbox 1234 in CouchDB!"
      Chef::Sandbox.should_receive(:cdb_load).with('1234').once.and_raise(err)
      @sandbox_file.invalid_sandbox?.should == "Cannot find sandbox with id '1234' in the database"
    end

    # NotFound in the controller
    it "is invalid if the sandbox exists, but the given checksum isn't a member of it" do
      sandbox = Chef::Sandbox.new('1234')
      sandbox.checksums << 'not-2342'
      Chef::Sandbox.should_receive(:cdb_load).with('1234').once.and_return(sandbox)
      @sandbox_file.invalid_sandbox?.should == "Cannot upload file: checksum '2342' isn't a part of sandbox '1234'"
    end

    it "is valid when the sandbox exists and the checksum is a member of it" do
      sandbox = Chef::Sandbox.new('1234')
      sandbox.checksums << '2342'
      Chef::Sandbox.should_receive(:cdb_load).with('1234').once.and_return(sandbox)
      @sandbox_file.invalid_sandbox?.should be_false
    end
    
  end

  context "when created with valid parameters and a valid sandbox" do
    before do
      @sandbox = Chef::Sandbox.new('1234')
      @sandbox_file.stub!(:sandbox).and_return(@sandbox)
      @input.string.replace("riseofthemachines\nriseofthechefs\n")
    end

    it "checksums the uploaded data" do
      @sandbox_file.actual_checksum.should == '0e157ac1e2dd73191b76067fb6b4bceb'
    end

    # BadRequest in the controller
    it "considers the uploaded file invalid if its checksum doesn't match" do
      message = "Uploaded file is invalid: expected a md5 sum '2342', but it was '0e157ac1e2dd73191b76067fb6b4bceb'"
      @sandbox_file.invalid_file?.should == message
    end

    it "is valid if the expected and actual checksums match" do
      @sandbox_file.expected_checksum.replace('0e157ac1e2dd73191b76067fb6b4bceb')
      @sandbox_file.invalid_file?.should be_false
    end

    context "and a string io for input" do
      it "writes the StringIO's contents to a tempfile, then moves it into place" do
        @tempfile = StringIO.new
        @tempfile.stub!(:path).and_return("/tmpfile/source")
        Tempfile.should_receive(:open).with("sandbox").and_yield(@tempfile)
        FileUtils.should_receive(:mv).with("/tmpfile/source", "/tmp/final_home")
        @sandbox_file.commit_to('/tmp/final_home')
        @tempfile.string.should == "riseofthemachines\nriseofthechefs\n"
      end

      it "calls #read and not #string on the rack input [CHEF-1363 regression test]" do
        @input.should_not_receive(:string)
        @tempfile = StringIO.new
        @tempfile.stub!(:path).and_return("/tmpfile/source")
        Tempfile.stub!(:open).and_yield(@tempfile)
        FileUtils.stub!(:mv)
        @sandbox_file.commit_to('/tmp/final_home')
      end
    end

    context "and a tempfile for input" do
      it "moves the tempfile into place" do
        @input.stub!(:path).and_return('/existing/tempfile')
        FileUtils.should_receive(:mv).with("/existing/tempfile", "/tmp/final_home")
        @sandbox_file.commit_to('/tmp/final_home')
      end
    end
    
  end

end
