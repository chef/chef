#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

describe Chef::ChecksumCache do
  before(:each) do
    Chef::Config[:cache_type] = "Memory"
    Chef::Config[:cache_options] = { }
    @cache = Chef::ChecksumCache.instance
    @cache.reset!
  end

  describe "loading the moneta backend" do
    it "should build a Chef::ChecksumCache object" do
      @cache.should be_a_kind_of(Chef::ChecksumCache)
    end

    it "should set up a Moneta Cache adaptor" do
      @cache.moneta.should be_a_kind_of(Moneta::Memory)
    end

    it "should raise an exception if it cannot load the moneta adaptor" do
      Chef::Log.should_receive(:fatal).with(/^Could not load Moneta back end/)
      lambda {
        c = Chef::ChecksumCache.instance.reset!('WTF')
      }.should raise_error(LoadError)
    end
  end

  describe "when caching checksums of cookbook files and templates" do

    before do
      @cache.reset!("Memory", {})
    end

    it "proxies the class method checksum_for_file to the instance" do
      @cache.should_receive(:checksum_for_file).with("a_file_or_a_fail")
      Chef::ChecksumCache.checksum_for_file("a_file_or_a_fail")
    end

    it "returns a cached checksum value" do
      @cache.moneta["chef-file-riseofthemachines"] = {"mtime" => "12345", "checksum" => "123abc"}
      fstat = mock("File.stat('riseofthemachines')", :mtime => Time.at(12345))
      File.should_receive(:stat).with("riseofthemachines").and_return(fstat)
      @cache.checksum_for_file("riseofthemachines").should == "123abc"
    end

    it "gives nil for a cache miss" do
      @cache.moneta["chef-file-riseofthemachines"] = {"mtime" => "12345", "checksum" => "123abc"}
      fstat = mock("File.stat('riseofthemachines')", :mtime => Time.at(555555))
      @cache.lookup_checksum("chef-file-riseofthemachines", fstat).should be_nil
    end

    it "treats a non-matching mtime as a cache miss" do
      @cache.moneta["chef-file-riseofthemachines"] = {"mtime" => "12345", "checksum" => "123abc"}
      fstat = mock("File.stat('riseofthemachines')", :mtime => Time.at(555555))
      @cache.lookup_checksum("chef-file-riseofthemachines", fstat).should be_nil
    end

    it "computes a checksum of a file" do
      fixture_file = CHEF_SPEC_DATA + "/checksum/random.txt"
      expected = "09ee9c8cc70501763563bcf9c218d71b2fbf4186bf8e1e0da07f0f42c80a3394"
      @cache.send(:checksum_file, fixture_file, Digest::SHA256.new).should == expected
    end

    it "computes a checksum and stores it in the cache" do
      fstat = mock("File.stat('riseofthemachines')", :mtime => Time.at(555555))
      @cache.should_receive(:checksum_file).with("riseofthemachines", an_instance_of(Digest::SHA256)).and_return("ohai2uChefz")
      @cache.generate_checksum("chef-file-riseofthemachines", "riseofthemachines", fstat).should == "ohai2uChefz"
      @cache.lookup_checksum("chef-file-riseofthemachines", fstat).should == "ohai2uChefz"
    end

    it "returns a generated checksum if there is no cached value" do
      fixture_file = CHEF_SPEC_DATA + "/checksum/random.txt"
      expected = "09ee9c8cc70501763563bcf9c218d71b2fbf4186bf8e1e0da07f0f42c80a3394"
      @cache.checksum_for_file(fixture_file).should == expected
    end

    it "generates a key from a file name" do
      file = "/this/is/a/test/random.rb"
      @cache.generate_key(file).should == "chef-file--this-is-a-test-random-rb"
    end

    it "generates a key from a file name and group" do
      file = "/this/is/a/test/random.rb"
      @cache.generate_key(file, "spec").should == "spec-file--this-is-a-test-random-rb"
    end

    it "returns a cached checksum value using a user defined key" do
      key = @cache.generate_key("riseofthemachines", "specs")
      @cache.moneta[key] = {"mtime" => "12345", "checksum" => "123abc"}
      fstat = mock("File.stat('riseofthemachines')", :mtime => Time.at(12345))
      File.should_receive(:stat).with("riseofthemachines").and_return(fstat)
      @cache.checksum_for_file("riseofthemachines", key).should == "123abc"
    end

    it "generates a checksum from a non-file IO object" do
      io = StringIO.new("riseofthemachines\nriseofthechefs\n")
      expected_md5 = '0e157ac1e2dd73191b76067fb6b4bceb'
      @cache.generate_md5_checksum(io).should == expected_md5
    end

  end

  describe "when cleaning up after outdated checksums" do

    before do
      Chef::ChecksumCache.reset_cache_validity
    end

    it "initially has no valid cached checksums" do
      Chef::ChecksumCache.valid_cached_checksums.should be_empty
    end

    it "adds a checksum to the list of valid cached checksums when it's created" do
      @cache.checksum_for_file(File.join(CHEF_SPEC_DATA, 'checksum', 'random.txt'))
      Chef::ChecksumCache.valid_cached_checksums.should have(1).valid_checksum
    end

    it "adds a checksum to the list of valid cached checksums when it's read" do
      @cache.checksum_for_file(File.join(CHEF_SPEC_DATA, 'checksum', 'random.txt'))
      Chef::ChecksumCache.reset_cache_validity
      @cache.checksum_for_file(File.join(CHEF_SPEC_DATA, 'checksum', 'random.txt'))
      Chef::ChecksumCache.valid_cached_checksums.should have(1).valid_checksum
    end

    context "with an existing set of cached checksums" do
      before do
        Chef::Config[:cache_type] = "BasicFile"
        Chef::Config[:cache_options] = {:path => File.join(CHEF_SPEC_DATA, "checksum_cache")}

        @expected_cached_checksums = ["chef-file--tmp-chef-rendered-template20100929-10863-600hhz-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-6m8zdk-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-ahd2gq-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-api8ux-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-b0r1m1-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-bfygsi-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-el14l6-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-ivrl3y-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-kkbs85-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-ory1ux-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-pgsq76-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-ra8uim-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-t7k1g-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-t8g0sv-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-ufy6g3-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-x2d6j9-0",
                                      "chef-file--tmp-chef-rendered-template20100929-10863-xi0l6h-0"]
        @expected_cached_checksums.sort!
      end

      after do
        Chef::Config[:cache_type] = "Memory"
        Chef::Config[:cache_options] = { }
        @cache = Chef::ChecksumCache.instance
        @cache.reset!
      end

      it "lists all of the cached checksums in the cache directory" do
        Chef::ChecksumCache.all_cached_checksums.keys.sort.should == @expected_cached_checksums
      end

      it "clears all of the checksums not marked valid from the checksums directory" do
        valid_cksum_key = "chef-file--tmp-chef-rendered-template20100929-10863-ivrl3y-0"
        valid_cksum_file = File.join(CHEF_SPEC_DATA, "checksum_cache", valid_cksum_key)
        @expected_cached_checksums.delete(valid_cksum_key)

        Chef::ChecksumCache.valid_cached_checksums << valid_cksum_key

        Chef::ChecksumCache.should_not_receive(:remove_unused_checksum).with(valid_cksum_file)
        @expected_cached_checksums.each do |cksum_key|
          full_path_to_cksum = File.join(CHEF_SPEC_DATA, "checksum_cache", cksum_key)
          Chef::ChecksumCache.should_receive(:remove_unused_checksum).with(full_path_to_cksum)
        end

        Chef::ChecksumCache.cleanup_checksum_cache
      end

      it "cleans all 0byte checksum files when it encounters a Marshal error" do
        @cache.moneta.stub!(:fetch).and_raise(ArgumentError)
        # This cache file is 0 bytes, raises an argument error when
        # attempting to Marshal.load
        File.should_receive(:unlink).with(File.join(CHEF_SPEC_DATA, "checksum_cache", "chef-file--tmp-chef-rendered-template20100929-10863-6m8zdk-0"))
        @cache.lookup_checksum("chef-file--tmp-chef-rendered-template20100929-10863-6m8zdk-0", "foo")
      end
    end

  end

end

