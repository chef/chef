#
# Author:: Stephen Delano (<stephen@opscode.com>)
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

require 'spec_helper'

require 'chef/cookbook_uploader'
require 'chef/cookbook_site_streaming_uploader'

describe Chef::Knife::CookbookSiteShare do

  before(:each) do
    @knife = Chef::Knife::CookbookSiteShare.new
    @knife.name_args = ['cookbook_name', 'AwesomeSausage']

    @cookbook = Chef::CookbookVersion.new('cookbook_name')

    @cookbook_loader = mock('Chef::CookbookLoader')
    @cookbook_loader.stub!(:cookbook_exists?).and_return(true)
    @cookbook_loader.stub!(:[]).and_return(@cookbook)
    Chef::CookbookLoader.stub!(:new).and_return(@cookbook_loader)

    @cookbook_uploader = Chef::CookbookUploader.new('herpderp', File.join(CHEF_SPEC_DATA, 'cookbooks'), :rest => "norest")
    Chef::CookbookUploader.stub!(:new).and_return(@cookbook_uploader)
    @cookbook_uploader.stub!(:validate_cookbooks).and_return(true)
    Chef::CookbookSiteStreamingUploader.stub!(:create_build_dir).and_return(Dir.mktmpdir)

    Chef::Mixin::Command.stub(:run_command).and_return(true)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe 'run' do

    before(:each) do
      @knife.stub!(:do_upload).and_return(true)
    end

    it 'should should print usage and exit when given no arguments' do
      @knife.name_args = []
      @knife.should_receive(:show_usage)
      @knife.ui.should_receive(:fatal)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should print usage and exit when given only 1 argument' do
      @knife.name_args = ['cookbook_name']
      @knife.should_receive(:show_usage)
      @knife.ui.should_receive(:fatal)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should check if the cookbook exists' do
      @cookbook_loader.should_receive(:cookbook_exists?)
      @knife.run
    end

    it "should exit and log to error if the cookbook doesn't exist" do
      @cookbook_loader.stub(:cookbook_exists?).and_return(false)
      @knife.ui.should_receive(:error)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should make a tarball of the cookbook' do
      Chef::Mixin::Command.should_receive(:run_command) { |args|
        args[:command].should match /tar -czf/
      }
      @knife.run
    end

    it 'should exit and log to error when the tarball creation fails' do
      Chef::Mixin::Command.stub!(:run_command).and_raise(Chef::Exceptions::Exec)
      @knife.ui.should_receive(:error)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should upload the cookbook and clean up the tarball' do
      @knife.should_receive(:do_upload)
      FileUtils.should_receive(:rm_rf)
      @knife.run
    end
  end

  describe 'do_upload' do

    before(:each) do
      @upload_response = mock('Net::HTTPResponse')
      Chef::CookbookSiteStreamingUploader.stub!(:post).and_return(@upload_response)

      @stdout = StringIO.new
      @stderr = StringIO.new
      @knife.ui.stub!(:stdout).and_return(@stdout)
      @knife.ui.stub!(:stderr).and_return(@stderr)
      File.stub(:open).and_return(true)
    end

    it 'should post the cookbook to "http://cookbooks.opscode.com"' do
      response_text = {:uri => 'http://cookbooks.opscode.com/cookbooks/cookbook_name'}.to_json
      @upload_response.stub!(:body).and_return(response_text)
      @upload_response.stub!(:code).and_return(201)
      Chef::CookbookSiteStreamingUploader.should_receive(:post).with(/cookbooks\.opscode\.com/, anything(), anything(), anything())
      @knife.run
    end

    it 'should alert the user when a version already exists' do
      response_text = {:error_messages => ['Version already exists']}.to_json
      @upload_response.stub!(:body).and_return(response_text)
      @upload_response.stub!(:code).and_return(409)
      lambda { @knife.run }.should raise_error(SystemExit)
      @stderr.string.should match(/ERROR(.+)cookbook already exists/)
    end

    it 'should pass any errors on to the user' do
      response_text = {:error_messages => ["You're holding it wrong"]}.to_json
      @upload_response.stub!(:body).and_return(response_text)
      @upload_response.stub!(:code).and_return(403)
      lambda { @knife.run }.should raise_error(SystemExit)
      @stderr.string.should match("ERROR(.*)You're holding it wrong")
    end

    it 'should print the body if no errors are exposed on failure' do
      response_text = {:system_error => "Your call was dropped", :reason => "There's a map for that"}.to_json
      @upload_response.stub!(:body).and_return(response_text)
      @upload_response.stub!(:code).and_return(500)
      @knife.ui.should_receive(:error).with(/#{Regexp.escape(response_text)}/)#.ordered
      @knife.ui.should_receive(:error).with(/Unknown error/)#.ordered
      lambda { @knife.run }.should raise_error(SystemExit)
    end

  end

end
