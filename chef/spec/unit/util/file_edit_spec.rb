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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

module Home
  PATH = File.expand_path(File.dirname(__FILE__))
  DATA = File.join(PATH, "..", "..", "data", "fileedit")
  HOSTS = File.join(DATA, "hosts")
  HOSTS_OLD = File.join(DATA, "hosts.old")
end

describe Chef::Util::FileEdit, "initialiize" do
  it "should create a new Chef::Util::FileEdit object" do
    Chef::Util::FileEdit.new(Home::HOSTS).should be_kind_of(Chef::Util::FileEdit)
  end

  it "should throw an exception if the input file does not exist" do
    lambda{Chef::Util::FileEdit.new("nonexistfile")}.should raise_error
  end

  it "should throw an exception if the input file is blank" do
    lambda{Chef::Util::FileEdit.new(Home::DATA + "/blank")}.should raise_error
  end

end

describe Chef::Util::FileEdit, "search_file_replace" do

  it "should accept regex passed in as a string (not Regexp object) and replace the match if there is one" do
    helper_method(Home::HOSTS, "localhost", true)
  end


  it "should accept regex passed in as a Regexp object and replace the match if there is one" do
    helper_method(Home::HOSTS, /localhost/, true)
  end


  it "should do nothing if there isn't a match" do
    helper_method(Home::HOSTS, /pattern/, false)
  end


  def helper_method(filename, regex, value)
    fedit = Chef::Util::FileEdit.new(filename)
    fedit.search_file_replace(regex, "replacement")
    fedit.write_file
    (File.exist? filename+".old").should be(value)
    if value == true
      newfile = File.new(filename).readlines
      newfile[0].should match(/replacement/)
      File.delete(Home::HOSTS)
      File.rename(Home::HOSTS_OLD, Home::HOSTS)
    end
  end

end

describe Chef::Util::FileEdit, "search_file_replace_line" do

  it "should search for match and replace the whole line" do
    fedit = Chef::Util::FileEdit.new(Home::HOSTS)
    fedit.search_file_replace_line(/localhost/, "replacement line")
    fedit.write_file
    newfile = File.new(Home::HOSTS).readlines
    newfile[0].should match(/replacement/)
    newfile[0].should_not match(/127/)
    File.delete(Home::HOSTS)
    File.rename(Home::HOSTS_OLD, Home::HOSTS)
  end

end

describe Chef::Util::FileEdit, "search_file_delete" do
  it "should search for match and delete the match" do
    fedit = Chef::Util::FileEdit.new(Home::HOSTS)
    fedit.search_file_delete(/localhost/)
    fedit.write_file
    newfile = File.new(Home::HOSTS).readlines
    newfile[0].should_not match(/localhost/)
    newfile[0].should match(/127/)
    File.delete(Home::HOSTS)
    File.rename(Home::HOSTS_OLD, Home::HOSTS)
  end
end

describe Chef::Util::FileEdit, "search_file_delete_line" do
  it "should search for match and delete the matching line" do
    fedit = Chef::Util::FileEdit.new(Home::HOSTS)
    fedit.search_file_delete_line(/localhost/)
    fedit.write_file
    newfile = File.new(Home::HOSTS).readlines
    newfile[0].should_not match(/localhost/)
    newfile[0].should match(/broadcasthost/)
    File.delete(Home::HOSTS)
    File.rename(Home::HOSTS_OLD, Home::HOSTS)
  end
end

describe Chef::Util::FileEdit, "insert_line_after_match" do
  it "should search for match and insert the given line after the matching line" do
    fedit = Chef::Util::FileEdit.new(Home::HOSTS)
    fedit.insert_line_after_match(/localhost/, "new line inserted")
    fedit.write_file
    newfile = File.new(Home::HOSTS).readlines
    newfile[1].should match(/new/)
    File.delete(Home::HOSTS)
    File.rename(Home::HOSTS_OLD, Home::HOSTS)
  end

end






