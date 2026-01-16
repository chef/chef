#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
      expect(File).to exist(File.join(@file_cache_path, "whiz"))
    end

    it "creates the cached file at the correct relative path" do
      expect(File).to receive(:open).with(File.join(@file_cache_path, "whiz", "bang"), "w", 416).and_yield(@io)
      Chef::FileCache.store("whiz/bang", "borkborkbork")
    end

  end

  describe "when storing a file" do
    before do
      allow(File).to receive(:open).and_yield(@io)
    end

    it "should print the contents to the file" do
      Chef::FileCache.store("whiz/bang", "borkborkbork")
      expect(@io.string).to eq("borkborkbork")
    end

  end

  describe "when loading cached files" do
    it "finds and reads the cached file" do
      FileUtils.mkdir_p(File.join(@file_cache_path, "whiz"))
      File.open(File.join(@file_cache_path, "whiz", "bang"), "w") { |f| f.print("borkborkbork") }
      expect(Chef::FileCache.load("whiz/bang")).to eq("borkborkbork")
    end

    it "should raise a Chef::Exceptions::FileNotFound if the file doesn't exist" do
      expect { Chef::FileCache.load("whiz/bang") }.to raise_error(Chef::Exceptions::FileNotFound)
    end
  end

  describe "when deleting cached files" do
    before(:each) do
      FileUtils.mkdir_p(File.join(@file_cache_path, "whiz"))
      File.open(File.join(@file_cache_path, "whiz", "bang"), "w") { |f| f.print("borkborkbork") }
    end

    it "unlinks the file" do
      Chef::FileCache.delete("whiz/bang")
      expect(File).not_to exist(File.join(@file_cache_path, "whiz", "bang"))
    end

  end

  describe "when listing files in the cache" do
    before(:each) do
      FileUtils.mkdir_p(File.join(@file_cache_path, "whiz"))
      FileUtils.touch(File.join(@file_cache_path, "whiz", "bang"))
      FileUtils.mkdir_p(File.join(@file_cache_path, "snappy"))
      FileUtils.touch(File.join(@file_cache_path, "snappy", "patter"))
    end

    it "should return the relative paths" do
      expect(Chef::FileCache.list.sort).to eq(%w{snappy/patter whiz/bang})
    end

    it "searches for cached files by globbing" do
      expect(Chef::FileCache.find("snappy/**/*")).to eq(%w{snappy/patter})
    end
  end

  describe "#find handles regex-unsafe unix paths" do
    before(:each) do
      # Dir.mktmpdir doesn't allow regex unsafe characters (the nerve!), so we'll have to fake file lookups
      @file_cache_path = "/tmp/[foo* ^bar]"
      escaped_file_cache_path = '/tmp/\[foo\* ^bar\]'
      Chef::Config[:file_cache_path] = @file_cache_path
      allow(Chef::Util::PathHelper).to receive(:escape_glob_dir).and_return(escaped_file_cache_path)
      allow(Dir).to receive(:[]).with(File.join(escaped_file_cache_path, "snappy/**/*")).and_return([
        File.join(@file_cache_path, "snappy"),
        File.join(@file_cache_path, "snappy", "patter"),
      ])
      allow(Dir).to receive(:[]).with(escaped_file_cache_path).and_return([
        @file_cache_path,
      ])
      [
        File.join(@file_cache_path, "snappy", "patter"),
        File.join(@file_cache_path, "whiz", "bang"),
      ].each do |f|
        allow(File).to receive(:file?).with(f).and_return(true)
      end
      [
        File.join(@file_cache_path, "snappy"),
        File.join(@file_cache_path, "whiz"),
      ].each do |f|
        allow(File).to receive(:file?).with(f).and_return(false)
      end
    end

    it "searches for cached files by globbing" do
      expect(Chef::FileCache.find("snappy/**/*")).to eq(%w{snappy/patter})
    end
  end

  describe "#find handles Windows paths" do
    before(:each) do
      allow(ChefUtils).to receive(:windows?).and_return(true)
      @file_cache_path = 'C:\tmp\fakecache'
      escaped_file_cache_path = "C:\\tmp\\fakecache"
      Chef::Config[:file_cache_path] = @file_cache_path
      allow(Chef::Util::PathHelper).to receive(:escape_glob_dir).and_return(escaped_file_cache_path)
      allow(Dir).to receive(:[]).with(File.join(escaped_file_cache_path, "snappy/**/*")).and_return([
        File.join(@file_cache_path, "snappy"),
        File.join(@file_cache_path, "snappy", "patter"),
      ])
      allow(Dir).to receive(:[]).with(escaped_file_cache_path).and_return([
        @file_cache_path,
      ])
      [
        File.join(@file_cache_path, "snappy", "patter"),
        File.join(@file_cache_path, "whiz", "bang"),
      ].each do |f|
        allow(File).to receive(:file?).with(f).and_return(true)
      end
      [
        File.join(@file_cache_path, "snappy"),
        File.join(@file_cache_path, "whiz"),
      ].each do |f|
        allow(File).to receive(:file?).with(f).and_return(false)
      end
    end
    it "searches for cached files by globbing" do
      expect(Chef::FileCache.find("snappy/**/*")).to eq(%w{snappy/patter})
    end
  end

  describe "when checking for the existence of a file" do
    before do
      FileUtils.mkdir_p(File.join(@file_cache_path, "whiz"))
    end

    it "has a key if the corresponding cache file exists" do
      FileUtils.touch(File.join(@file_cache_path, "whiz", "bang"))
      expect(Chef::FileCache).to have_key("whiz/bang")
    end

    it "doesn't have a key if the corresponding cache file doesn't exist" do
      expect(Chef::FileCache).not_to have_key("whiz/bang")
    end
  end
end
