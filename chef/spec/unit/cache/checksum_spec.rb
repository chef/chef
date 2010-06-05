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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Cache::Checksum do
  
  before do
    @cache = Chef::Cache::Checksum.instance
    @cache.reset!("Memory", {})
  end
  
  it "proxies the class method checksum_for_file to the instance" do
    @cache.should_receive(:checksum_for_file).with("a_file_or_a_fail")
    Chef::Cache::Checksum.checksum_for_file("a_file_or_a_fail")
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
