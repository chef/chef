#
# Author:: Nuo Yan (<nuo@opscode.com>)
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

describe Chef::Util::FileEdit do

  before(:each) do

    @hosts_content=<<-HOSTS
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
fe80::1%lo0     localhost
HOSTS

    @tempfile = Tempfile.open('file_edit_spec')
    @tempfile.write(@hosts_content)
    @tempfile.close
    @fedit = Chef::Util::FileEdit.new(@tempfile.path)
  end

  after(:each) do
    @tempfile && @tempfile.close!
  end

  describe "initialiize" do
    it "should create a new Chef::Util::FileEdit object" do
      Chef::Util::FileEdit.new(@tempfile.path).should be_kind_of(Chef::Util::FileEdit)
    end

    it "should throw an exception if the input file does not exist" do
      lambda{Chef::Util::FileEdit.new("nonexistfile")}.should raise_error
    end

    it "should throw an exception if the input file is blank" do
      lambda do
        Chef::Util::FileEdit.new(File.join(CHEF_SPEC_DATA, "filedit", "blank"))
      end.should raise_error
    end
  end

  describe "search_file_replace" do
    it "should accept regex passed in as a string (not Regexp object) and replace the match if there is one" do
      @fedit.search_file_replace("localhost", "replacement")
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[0].should match(/replacement/)
    end

    it "should accept regex passed in as a Regexp object and replace the match if there is one" do
      @fedit.search_file_replace(/localhost/, "replacement")
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[0].should match(/replacement/)
    end

    it "should do nothing if there isn't a match" do
      @fedit.search_file_replace(/pattern/, "replacement")
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[0].should_not match(/replacement/)
    end
  end

  describe "search_file_replace_line" do
    it "should search for match and replace the whole line" do
      @fedit.search_file_replace_line(/localhost/, "replacement line")
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[0].should match(/replacement/)
      newfile[0].should_not match(/127/)
    end
  end

  describe "search_file_delete" do
    it "should search for match and delete the match" do
      @fedit.search_file_delete(/localhost/)
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[0].should_not match(/localhost/)
      newfile[0].should match(/127/)
    end
  end

  describe "search_file_delete_line" do
    it "should search for match and delete the matching line" do
      @fedit.search_file_delete_line(/localhost/)
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[0].should_not match(/localhost/)
      newfile[0].should match(/broadcasthost/)
    end
  end

  describe "insert_line_after_match" do
    it "should search for match and insert the given line after the matching line" do
      @fedit.insert_line_after_match(/localhost/, "new line inserted")
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[1].should match(/new/)
    end
  end

  describe "insert_line_if_no_match" do
    it "should search for match and insert the given line if no line match" do
      @fedit.insert_line_if_no_match(/pattern/, "new line inserted")
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile.last.should match(/new/)
    end

    it "should do nothing if there is a match" do
      @fedit.insert_line_if_no_match(/localhost/, "replacement")
      @fedit.write_file
      newfile = File.new(@tempfile.path).readlines
      newfile[1].should_not match(/replacement/)
    end
  end
end
