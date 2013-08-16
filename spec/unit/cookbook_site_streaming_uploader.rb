#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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

require 'chef/cookbook_site_streaming_uploader'

class FakeTempfile
  def initialize(basename)
    @basename = basename
  end

  def close
  end

  def path
    "#{@basename}.ZZZ"
  end

end

describe Chef::CookbookSiteStreamingUploader do

  describe "create_build_dir" do

    before(:each) do
      @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, 'cookbooks'))
      @loader = Chef::CookbookLoader.new(@cookbook_repo)
      @loader.load_cookbooks
      File.stub(:unlink).and_return()
    end

    it "should create the cookbook tmp dir" do
      cookbook = @loader[:openldap]
      files_count = Dir.glob(File.join(@cookbook_repo, cookbook.name.to_s, '**', '*'), File::FNM_DOTMATCH).count { |file| File.file?(file) }

      Tempfile.should_receive(:new).with("chef-#{cookbook.name}-build").and_return(FakeTempfile.new("chef-#{cookbook.name}-build"))
      FileUtils.should_receive(:mkdir_p).exactly(files_count + 1).times
      FileUtils.should_receive(:cp).exactly(files_count).times
      Chef::CookbookSiteStreamingUploader.create_build_dir(cookbook)
    end

  end # create_build_dir

  describe "make_request" do

    before(:each) do
      @uri = "http://cookbooks.dummy.com/api/v1/cookbooks"
      @secret_filename = File.join(CHEF_SPEC_DATA, 'ssl/private_key.pem')
      @rsa_key = File.read(@secret_filename)
      response = Net::HTTPResponse.new('1.0', '200', 'OK')
      Net::HTTP.any_instance.stub(:request).and_return(response)
    end

    it "should send an http request" do
      Net::HTTP.any_instance.should_receive(:request)
      Chef::CookbookSiteStreamingUploader.make_request(:post, @uri, 'bill', @secret_filename)
    end

    it "should read the private key file" do
      File.should_receive(:read).with(@secret_filename).and_return(@rsa_key)
      Chef::CookbookSiteStreamingUploader.make_request(:post, @uri, 'bill', @secret_filename)
    end

    it "should add the authentication signed header" do
      Mixlib::Authentication::SigningObject.any_instance.should_receive(:sign).and_return({})
      Chef::CookbookSiteStreamingUploader.make_request(:post, @uri, 'bill', @secret_filename)
    end

    it "should be able to send post requests" do
      post = Net::HTTP::Post.new(@uri, {})

      Net::HTTP::Post.should_receive(:new).once.and_return(post)
      Net::HTTP::Put.should_not_receive(:new)
      Net::HTTP::Get.should_not_receive(:new)
      Chef::CookbookSiteStreamingUploader.make_request(:post, @uri, 'bill', @secret_filename)
    end

    it "should be able to send put requests" do
      put = Net::HTTP::Put.new(@uri, {})

      Net::HTTP::Post.should_not_receive(:new)
      Net::HTTP::Put.should_receive(:new).once.and_return(put)
      Net::HTTP::Get.should_not_receive(:new)
      Chef::CookbookSiteStreamingUploader.make_request(:put, @uri, 'bill', @secret_filename)
    end

    it "should be able to receive files to attach as argument" do
      Chef::CookbookSiteStreamingUploader.make_request(:put, @uri, 'bill', @secret_filename, {
        :myfile => File.new(File.join(CHEF_SPEC_DATA, 'config.rb')), # a dummy file
      })
    end

    it "should be able to receive strings to attach as argument" do
      Chef::CookbookSiteStreamingUploader.make_request(:put, @uri, 'bill', @secret_filename, {
        :mystring => 'Lorem ipsum',
      })
    end

    it "should be able to receive strings and files as argument at the same time" do
      Chef::CookbookSiteStreamingUploader.make_request(:put, @uri, 'bill', @secret_filename, {
        :myfile1 => File.new(File.join(CHEF_SPEC_DATA, 'config.rb')),
        :mystring1 => 'Lorem ipsum',
        :myfile2 => File.new(File.join(CHEF_SPEC_DATA, 'config.rb')),
        :mystring2 => 'Dummy text',
      })
    end

  end # make_request

  describe "StreamPart" do
    before(:each) do
      @file = File.new(File.join(CHEF_SPEC_DATA, 'config.rb'))
      @stream_part = Chef::CookbookSiteStreamingUploader::StreamPart.new(@file, File.size(@file))
    end

    it "should create a StreamPart" do
      @stream_part.should be_instance_of(Chef::CookbookSiteStreamingUploader::StreamPart)
    end

    it "should expose its size" do
      @stream_part.size.should eql(File.size(@file))
    end

    it "should read with offset and how_much" do
      content = @file.read(4)
      @file.rewind
      @stream_part.read(0, 4).should eql(content)
    end

  end # StreamPart

  describe "StringPart" do
    before(:each) do
      @str = 'What a boring string'
      @string_part = Chef::CookbookSiteStreamingUploader::StringPart.new(@str)
    end

    it "should create a StringPart" do
      @string_part.should be_instance_of(Chef::CookbookSiteStreamingUploader::StringPart)
    end

    it "should expose its size" do
      @string_part.size.should eql(@str.size)
    end

    it "should read with offset and how_much" do
      @string_part.read(2, 4).should eql(@str[2, 4])
    end

  end # StringPart

end

