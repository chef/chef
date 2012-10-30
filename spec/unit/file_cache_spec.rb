#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::FileCache do
  before do
    @file_cache_path = Dir.mktmpdir
    Chef::Config[:file_cache_path] = @file_cache_path
    @io = StringIO.new
  end

  after do
    FileUtils.rm_rf(Chef::Config[:file_cache_path])
  end

  describe "when the relative path to the cache file doesn't exist" do
    it "creates intermediate directories as needed" do
      Chef::FileCache.store("whiz/bang", "I found a poop")
      File.should exist(File.join(@file_cache_path, 'whiz'))
    end

    it "creates the cached file at the correct relative path" do
      File.should_receive(:open).with(File.join(@file_cache_path, 'whiz', 'bang'), "w",416).and_yield(@io)
      Chef::FileCache.store("whiz/bang", "borkborkbork")
    end

  end
  
  describe "when storing a file" do
    before do
      File.stub!(:open).and_yield(@io)
    end

    it "should print the contents to the file" do
      Chef::FileCache.store("whiz/bang", "borkborkbork")
      @io.string.should == "borkborkbork"
    end

  end

  describe "when loading cached files" do
    it "finds and reads the cached file" do
      FileUtils.mkdir_p(File.join(@file_cache_path, 'whiz'))
      File.open(File.join(@file_cache_path, 'whiz', 'bang'), 'w') { |f| f.print("borkborkbork") }
      Chef::FileCache.load('whiz/bang').should == 'borkborkbork'
    end

    it "should raise a Chef::Exceptions::FileNotFound if the file doesn't exist" do
      lambda { Chef::FileCache.load('whiz/bang') }.should raise_error(Chef::Exceptions::FileNotFound)
    end
  end

  describe "when deleting cached files" do
    before(:each) do
      FileUtils.mkdir_p(File.join(@file_cache_path, 'whiz'))
      File.open(File.join(@file_cache_path, 'whiz', 'bang'), 'w') { |f| f.print("borkborkbork") }
    end

    it "unlinks the file" do
      Chef::FileCache.delete("whiz/bang")
      File.should_not exist(File.join(@file_cache_path, 'whiz', 'bang'))
    end

  end

  describe "when listing files in the cache" do
    before(:each) do
      FileUtils.mkdir_p(File.join(@file_cache_path, 'whiz'))
      FileUtils.touch(File.join(@file_cache_path, 'whiz', 'bang'))
      FileUtils.mkdir_p(File.join(@file_cache_path, 'snappy'))
      FileUtils.touch(File.join(@file_cache_path, 'snappy', 'patter'))
    end

    it "should return the relative paths" do
      Chef::FileCache.list.sort.should == %w{snappy/patter whiz/bang}
    end

    it "searches for cached files by globbing" do
      Chef::FileCache.find('snappy/**/*').should == %w{snappy/patter}
    end

  end

  describe "when checking for the existence of a file" do
    before do
      FileUtils.mkdir_p(File.join(@file_cache_path, 'whiz'))
    end

    it "has a key if the corresponding cache file exists" do
      FileUtils.touch(File.join(@file_cache_path, 'whiz', 'bang'))
      Chef::FileCache.should have_key("whiz/bang")
    end

    it "doesn't have a key if the corresponding cache file doesn't exist" do
      Chef::FileCache.should_not have_key("whiz/bang")
    end
  end
end
