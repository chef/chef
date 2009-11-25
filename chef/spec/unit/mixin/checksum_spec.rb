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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require 'chef/mixin/checksum'
require 'stringio'

class Chef::CMCCheck 
  extend Chef::Mixin::Checksum
end

describe Chef::Mixin::Checksum do
  before(:each) do
    Chef::Config[:cache_type] = "Memory"
    Chef::Config[:cache_options] = { }
    @filename = "jimmy"
    @file = StringIO.new("If you don't know why won't you say so, if you don't know why would you say so")
    @stat = mock("File::Stat", { :mtime => Time.at(0) })
    @digest = "9b568281f587b1dfbdb1ce666bd17716195de949c5af05e3397faa0031c712be"
    File.stub!(:open).and_return(@file)
    File.stub!(:stat).and_return(@stat)
  end

  describe "checksum" do
    it "should call stat() on the file" do
      File.should_receive(:stat).and_return(@stat)
      Chef::CMCCheck.checksum(@filename)
    end

    it "should create a valid cache key" do
      @filename.should_receive(:gsub).with(/(#{File::SEPARATOR}|\.)/, '-')
      Chef::CMCCheck.checksum(@filename)
    end

    it "should check the Chef::Cache for the file" do
      c = Chef::Cache.new
      c.should_receive(:fetch).with("chef-file#{@filename}").and_return(nil)
      Chef::Cache.stub!(:new).and_return(c)
      Chef::CMCCheck.checksum(@filename)
    end

    describe "when the cache is not empty, and the mtime is the same" do
      it "should return the cached mtime" do
        c = Chef::Cache.new
        c.store("chef-file#{@filename}", { "mtime" => @stat.mtime.to_f, "checksum" => "monkeyboot" })
        Chef::Cache.stub!(:new).and_return(c)
        Chef::CMCCheck.checksum(@filename).should == "monkeyboot" 
      end
    end

    [ "mtime is different", "cache is empty" ].each do |reason|
      describe "when the #{reason}" do
        if reason == "mtime is different"
          before(:each) do 
            @c = Chef::Cache.new
            @c.store("chef-file#{@filename}", { "mtime" => 10.0, "checksum" => "monkeyboot" })
            Chef::Cache.stub!(:new).and_return(@c)
          end
        else
          before(:each) do 
            @c = Chef::Cache.new
            @c.stub!(:fetch).and_return(nil)
            Chef::Cache.stub!(:new).and_return(@c)
          end
        end

        it "should read the file" do
          File.should_receive(:open).with(@filename).and_return(@file)
          @file.should_receive(:each)
          Chef::CMCCheck.checksum(@filename)
        end

        it "should update the digest with each line" do
          digest = mock("Digest", { :hexdigest => "woot" })
          digest.should_receive("update").with(@file.gets)
          @file.rewind
          Digest::SHA256.stub!(:new).and_return(digest)
          Chef::CMCCheck.checksum(@filename)
        end

        it "should store the latest checksum" do
          @c.should_receive(:store).with("chef-file#{@filename}", { "mtime" => 0.0, "checksum" => @digest })
          Chef::CMCCheck.checksum(@filename)
        end

        it "should return the digest checksum" do
          Chef::CMCCheck.checksum(@filename).should == @digest
        end
      end
    end
  end

end

