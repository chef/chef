#
# Author:: Nuo Yan (<nuo@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
require "tempfile"

describe Chef::Util::FileEdit do

  let(:starting_content) do
    <<-EOF
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
fe80::1%lo0     localhost
    EOF
  end

  let(:localhost_replaced) do
    <<-EOF
127.0.0.1       replacement
255.255.255.255 broadcasthost
::1             replacement
fe80::1%lo0     replacement
    EOF
  end

  let(:localhost_line_replaced) do
    <<-EOF
replacement line
255.255.255.255 broadcasthost
replacement line
replacement line
    EOF
  end

  let(:localhost_deleted) do
    # sensitive to deliberate trailing whitespace
    "127.0.0.1       \n255.255.255.255 broadcasthost\n::1             \nfe80::1%lo0     \n"
  end

  let(:localhost_line_deleted) do
    <<-EOF
255.255.255.255 broadcasthost
    EOF
  end

  let(:append_after_all_localhost) do
    <<-EOF
127.0.0.1       localhost
new line inserted
255.255.255.255 broadcasthost
::1             localhost
new line inserted
fe80::1%lo0     localhost
new line inserted
    EOF
  end

  let(:append_after_content) do
    <<-EOF
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
fe80::1%lo0     localhost
new line inserted
    EOF
  end

  let(:append_twice) do
    <<-EOF
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
fe80::1%lo0     localhost
once
twice
    EOF
  end

  let(:target_file) do
    f = Tempfile.open("file_edit_spec")
    f.write(starting_content)
    f.close
    f
  end

  let(:fedit) { Chef::Util::FileEdit.new(target_file.path) }

  after(:each) do
    target_file.close!
  end

  describe "initialiize" do
    it "should create a new Chef::Util::FileEdit object" do
      expect(fedit).to be_instance_of(Chef::Util::FileEdit)
    end

    it "should throw an exception if the input file does not exist" do
      expect { Chef::Util::FileEdit.new("nonexistfile") }.to raise_error(ArgumentError)
    end

    # CHEF-5018: people have monkey patched this and it has accidentally been broken
    it "should read the contents into memory as an array" do
      expect(fedit.send(:editor).lines).to be_instance_of(Array)
    end
  end

  describe "when the file is blank" do
    let(:hosts_content) { "" }

    it "should not throw an exception" do
      expect { fedit }.not_to raise_error
    end
  end

  def edited_file_contents
    IO.read(target_file.path)
  end

  describe "search_file_replace" do
    it "should accept regex passed in as a string (not Regexp object) and replace the match if there is one" do
      fedit.search_file_replace("localhost", "replacement")
      expect(fedit.unwritten_changes?).to be_truthy
      fedit.write_file
      expect(edited_file_contents).to eq(localhost_replaced)
    end

    it "should accept regex passed in as a Regexp object and replace the match if there is one" do
      fedit.search_file_replace(/localhost/, "replacement")
      expect(fedit.unwritten_changes?).to be_truthy
      fedit.write_file
      expect(edited_file_contents).to eq(localhost_replaced)
    end

    it "should do nothing if there isn't a match" do
      fedit.search_file_replace(/pattern/, "replacement")
      expect(fedit.unwritten_changes?).to be_falsey
      fedit.write_file
      expect(edited_file_contents).to eq(starting_content)
    end
  end

  describe "search_file_replace_line" do
    it "should search for match and replace the whole line" do
      fedit.search_file_replace_line(/localhost/, "replacement line")
      expect(fedit.unwritten_changes?).to be_truthy
      fedit.write_file
      expect(edited_file_contents).to eq(localhost_line_replaced)
    end
  end

  describe "search_file_delete" do
    it "should search for match and delete the match" do
      fedit.search_file_delete(/localhost/)
      expect(fedit.unwritten_changes?).to be_truthy
      fedit.write_file
      expect(edited_file_contents).to eq(localhost_deleted)
    end
  end

  describe "search_file_delete_line" do
    it "should search for match and delete the matching line" do
      fedit.search_file_delete_line(/localhost/)
      expect(fedit.unwritten_changes?).to be_truthy
      fedit.write_file
      expect(edited_file_contents).to eq(localhost_line_deleted)
    end
  end

  describe "insert_line_after_match" do
    it "should search for match and insert the given line after the matching line" do
      fedit.insert_line_after_match(/localhost/, "new line inserted")
      expect(fedit.unwritten_changes?).to be_truthy
      fedit.write_file
      expect(edited_file_contents).to eq(append_after_all_localhost)
    end
  end

  describe "insert_line_if_no_match" do
    it "should search for match and insert the given line if no line match" do
      fedit.insert_line_if_no_match(/pattern/, "new line inserted")
      expect(fedit.unwritten_changes?).to be_truthy
      fedit.write_file
      expect(edited_file_contents).to eq(append_after_content)
    end

    it "should do nothing if there is a match" do
      fedit.insert_line_if_no_match(/localhost/, "replacement")
      expect(fedit.unwritten_changes?).to be_falsey
      fedit.write_file
      expect(edited_file_contents).to eq(starting_content)
    end

    it "should work more than once" do
      fedit.insert_line_if_no_match(/missing/, "once")
      fedit.insert_line_if_no_match(/missing/, "twice")
      fedit.write_file
      expect(edited_file_contents).to eq(append_twice)
    end
  end

  describe "file_edited" do
    it "should return true if a file got edited" do
      fedit.insert_line_if_no_match(/pattern/, "new line inserted")
      fedit.write_file
      expect(fedit.file_edited?).to be_truthy
    end
  end
end
