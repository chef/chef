#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'tmpdir'

describe Chef::Util::Diff, :uses_diff => true do
  before(:all) do
    @original_config = Chef::Config.hash_dup
  end

  after(:all) do
    Chef::Config.configuration = @original_config if @original_config
  end

  let!(:old_tempfile) { Tempfile.new("chef-util-diff-spec") }
  let!(:new_tempfile) { Tempfile.new("chef-util-diff-spec") }
  let!(:old_file) { old_tempfile.path }
  let!(:new_file) { new_tempfile.path }

  let(:plain_ascii) { "This is a text file.\nWith more than one line.\nAnd a \tTab.\nAnd lets make sure that other printable chars work too: ~!@\#$%^&*()`:\"<>?{}|_+,./;'[]\\-=\n" }
  # these are all byte sequences that are illegal in the other encodings... (but they may legally transcode)
  let(:utf_8) { "testing utf-8 unicode...\n\n\non a new line: \xE2\x80\x93\n" }  # unicode em-dash
  let(:latin_1) { "It is more metal.\nif you have an \xFDmlaut.\n" } # NB: changed to y-with-diaresis, but i'm American so I don't know the difference
  let(:shift_jis) { "I have no idea what this character is:\n \x83\x80.\n" } # seriously, no clue, but \x80 is nice and illegal in other encodings

  let(:differ) do  # subject
    differ = Chef::Util::Diff.new
    differ.diff(old_file, new_file)
    differ
  end

  it "should return a Chef::Util::Diff" do
    expect(differ).to be_a_kind_of(Chef::Util::Diff)
  end

  it "produces a diff even if the old_file does not exist" do
    old_tempfile.close
    old_tempfile.unlink
    expect(differ.for_output).to eql(["(no diff)"])
  end

  it "produces a diff even if the new_file does not exist" do
    new_tempfile.close
    new_tempfile.unlink
    expect(differ.for_output).to eql(["(no diff)"])
  end

  describe "when the two files exist with no content" do
    it "calling for_output should return the error message" do
      expect(differ.for_output).to eql(["(no diff)"])
    end

    it "calling for_reporting should be nil" do
      expect(differ.for_reporting).to be_nil
    end
  end

  describe "when diffs are disabled" do
    before do
      Chef::Config[:diff_disabled] = true
    end

    after do
      Chef::Config[:diff_disabled] = false
    end

    it "calling for_output should return the error message" do
      expect(differ.for_output).to eql( [ "(diff output suppressed by config)" ] )
    end

    it "calling for_reporting should be nil" do
      expect(differ.for_reporting).to be_nil
    end
  end

  describe "when the old_file has binary content" do
    before do
      old_tempfile.write("\x01\xff")
      old_tempfile.close
    end

    it "calling for_output should return the error message" do
      expect(differ.for_output).to eql( [ "(current file is binary, diff output suppressed)" ] )
    end

    it "calling for_reporting should be nil" do
      expect(differ.for_reporting).to be_nil
    end
  end

  describe "when the new_file has binary content" do
    before do
      new_tempfile.write("\x01\xff")
      new_tempfile.close
    end

    it "calling for_output should return the error message" do
      expect(differ.for_output).to eql( [ "(new content is binary, diff output suppressed)" ])
    end

    it "calling for_reporting should be nil" do
      expect(differ.for_reporting).to be_nil
    end
  end

  describe "when the default external encoding is UTF-8", :ruby_gte_19_only  do

    before do
      @saved_default_external = Encoding.default_external
      Encoding.default_external = Encoding::UTF_8
    end

    after do
      Encoding.default_external = @saved_default_external
    end

    describe "when a file has ASCII text" do
      before do
        new_tempfile.write(plain_ascii)
        new_tempfile.close
      end
      it "calling for_output should return a valid diff" do
        differ.for_output.join("\\n").should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
      end
      it "calling for_reporting should return a utf-8 string" do
        expect(differ.for_reporting.encoding).to equal(Encoding::UTF_8)
      end
    end

    describe "when a file has UTF-8 text" do
      before do
        new_tempfile.write(utf_8)
        new_tempfile.close
      end
      it "calling for_output should return a valid diff" do
        differ.for_output.join("\\n").should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
      end
      it "calling for_reporting should return a utf-8 string" do
        expect(differ.for_reporting.encoding).to equal(Encoding::UTF_8)
      end
    end

    describe "when a file has Latin-1 text" do
      before do
        new_tempfile.write(latin_1)
        new_tempfile.close
      end
      it "calling for_output should complain that the content is binary" do
        expect(differ.for_output).to eql( [ "(new content is binary, diff output suppressed)" ])
      end
      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end

    describe "when a file has Shift-JIS text" do
      before do
        new_tempfile.write(shift_jis)
        new_tempfile.close
      end
      it "calling for_output should complain that the content is binary" do
        expect(differ.for_output).to eql( [ "(new content is binary, diff output suppressed)" ])
      end
      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end

  end

  describe "when the default external encoding is Latin-1", :ruby_gte_19_only  do

    before do
      @saved_default_external = Encoding.default_external
      Encoding.default_external = Encoding::ISO_8859_1
    end

    after do
      Encoding.default_external = @saved_default_external
    end

    describe "when a file has ASCII text" do
      before do
        new_tempfile.write(plain_ascii)
        new_tempfile.close
      end
      it "calling for_output should return a valid diff" do
        differ.for_output.join("\\n").should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
      end
      it "calling for_reporting should return a utf-8 string" do
        expect(differ.for_reporting.encoding).to equal(Encoding::UTF_8)
      end
    end

    describe "when a file has UTF-8 text" do
      before do
        new_tempfile.write(utf_8)
        new_tempfile.close
      end
      it "calling for_output should complain that the content is binary" do
        expect(differ.for_output).to eql( [ "(new content is binary, diff output suppressed)" ])
      end
      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end

    describe "when a file has Latin-1 text" do
      before do
        new_tempfile.write(latin_1)
        new_tempfile.close
      end
      it "calling for_output should return a valid diff" do
        differ.for_output.join("\\n").should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
      end
      it "calling for_reporting should return a utf-8 string" do
        expect(differ.for_reporting.encoding).to equal(Encoding::UTF_8)
      end
    end

    describe "when a file has Shift-JIS text" do
      before do
        new_tempfile.write(shift_jis)
        new_tempfile.close
      end
      it "calling for_output should complain that the content is binary" do
        expect(differ.for_output).to eql( [ "(new content is binary, diff output suppressed)" ])
      end
      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end

  end
  describe "when the default external encoding is Shift_JIS", :ruby_gte_19_only  do

    before do
      @saved_default_external = Encoding.default_external
      Encoding.default_external = Encoding::Shift_JIS
    end

    after do
      Encoding.default_external = @saved_default_external
    end

    describe "when a file has ASCII text" do
      before do
        new_tempfile.write(plain_ascii)
        new_tempfile.close
      end
      it "calling for_output should return a valid diff" do
        differ.for_output.join("\\n").should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
      end
      it "calling for_reporting should return a utf-8 string" do
        expect(differ.for_reporting.encoding).to equal(Encoding::UTF_8)
      end
    end

    describe "when a file has UTF-8 text" do
      before do
        new_tempfile.write(utf_8)
        new_tempfile.close
      end
      it "calling for_output should complain that the content is binary" do
        expect(differ.for_output).to eql( [ "(new content is binary, diff output suppressed)" ])
      end
      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end

    describe "when a file has Latin-1 text" do
      before do
        new_tempfile.write(latin_1)
        new_tempfile.close
      end
      it "calling for_output should complain that the content is binary" do
        expect(differ.for_output).to eql( [ "(new content is binary, diff output suppressed)" ])
      end
      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end

    describe "when a file has Shift-JIS text" do
      before do
        new_tempfile.write(shift_jis)
        new_tempfile.close
      end
      it "calling for_output should return a valid diff" do
        differ.for_output.join("\\n").should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
      end
      it "calling for_reporting should return a utf-8 string" do
        expect(differ.for_reporting.encoding).to equal(Encoding::UTF_8)
      end
    end

  end

  describe "when testing the diff_filesize_threshold" do
    before do
      @diff_filesize_threshold_saved = Chef::Config[:diff_filesize_threshold]
      Chef::Config[:diff_filesize_threshold] = 10
    end

    after do
      Chef::Config[:diff_filesize_threshold] = @diff_filesize_threshold_saved
    end

    describe "when the old_file goes over the threshold" do
      before do
        old_tempfile.write("But thats what you get when Wu-Tang raised you")
        old_tempfile.close
      end

      it "calling for_output should return the error message" do
        expect(differ.for_output).to eql( [ "(file sizes exceed 10 bytes, diff output suppressed)" ])
      end

      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end

    describe "when the new_file goes over the threshold" do
      before do
        new_tempfile.write("But thats what you get when Wu-Tang raised you")
        new_tempfile.close
      end

      it "calling for_output should return the error message" do
        expect(differ.for_output).to eql( [ "(file sizes exceed 10 bytes, diff output suppressed)" ])
      end

      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end
  end

  describe "when generating a valid diff" do
    before do
      old_tempfile.write("foo")
      old_tempfile.close
      new_tempfile.write("bar")
      new_tempfile.close
    end

    it "calling for_output should return a unified diff" do
      differ.for_output.size.should eql(5)
      differ.for_output.join("\\n").should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
    end

    it "calling for_reporting should return a unified diff" do
      differ.for_reporting.should match(/\A--- .*\\n\+\+\+ .*\\n@@/m)
    end

    describe "when the diff output is too long" do

      before do
        @diff_output_threshold_saved = Chef::Config[:diff_output_threshold]
        Chef::Config[:diff_output_threshold] = 10
      end

      after do
        Chef::Config[:diff_output_threshold] = @diff_output_threshold_saved
      end

      it "calling for_output should return the error message" do
        expect(differ.for_output).to eql(["(long diff of over 10 characters, diff output suppressed)"])
      end

      it "calling for_reporting should be nil" do
        expect(differ.for_reporting).to be_nil
      end
    end
  end

  describe "when errors are thrown from shell_out" do
    before do
      differ.stub!(:shell_out).and_raise('boom')
      differ.diff(old_file, new_file)
    end

    it "calling for_output should return the error message" do
      expect(differ.for_output).to eql(["Could not determine diff. Error: boom"])
    end

    it "calling for_reporting should be nil" do
      expect(differ.for_reporting).to be_nil
    end
  end

  describe "when shell_out returns stderr output" do
    before do
      @result = mock('result', :stdout => "", :stderr => "boom")
      differ.stub!(:shell_out).and_return(@result)
      differ.diff(old_file, new_file)
    end

    it "calling for_output should return the error message" do
      expect(differ.for_output).to eql(["Could not determine diff. Error: boom"])
    end

    it "calling for_reporting should be nil" do
      expect(differ.for_reporting).to be_nil
    end
  end

  describe "when checking if files are binary or text" do

    it "should identify zero-length files as text" do
      Tempfile.open("chef-util-diff-spec") do |file|
        file.close
        differ.send(:is_binary?, file.path).should be_false
      end
    end

    it "should identify text files as text" do
      Tempfile.open("chef-util-diff-spec") do |file|
        file.write(plain_ascii)
        file.close
        differ.send(:is_binary?, file.path).should be_false
      end
    end

    it "should identify a null-terminated string files as binary" do
      Tempfile.open("chef-util-diff-spec") do |file|
        file.write("This is a binary file.\0")
        file.close
        differ.send(:is_binary?, file.path).should be_true
      end
    end

    it "should identify null-teriminated multi-line string files as binary" do
      Tempfile.open("chef-util-diff-spec") do |file|
        file.write("This is a binary file.\nNo Really\nit is\0")
        file.close
        differ.send(:is_binary?, file.path).should be_true
      end
    end

    describe "when the default external encoding is UTF-8", :ruby_gte_19_only  do

      before do
        @saved_default_external = Encoding.default_external
        Encoding.default_external = Encoding::UTF_8
      end

      after do
        Encoding.default_external = @saved_default_external
      end

      it "should identify normal ASCII as text" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(plain_ascii)
          file.close
          differ.send(:is_binary?, file.path).should be_false
        end
      end

      it "should identify UTF-8 as text" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(utf_8)
          file.close
          differ.send(:is_binary?, file.path).should be_false
        end
      end

      it "should identify Latin-1 that is invalid UTF-8 as binary" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(latin_1)
          file.close
          differ.send(:is_binary?, file.path).should be_true
        end
      end

      it "should identify Shift-JIS that is invalid UTF-8 as binary" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(shift_jis)
          file.close
          differ.send(:is_binary?, file.path).should be_true
        end
      end

    end

    describe "when the default external encoding is Latin-1", :ruby_gte_19_only do

      before do
        @saved_default_external = Encoding.default_external
        Encoding.default_external = Encoding::ISO_8859_1
      end

      after do
        Encoding.default_external = @saved_default_external
      end

      it "should identify normal ASCII as text" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(plain_ascii)
          file.close
          differ.send(:is_binary?, file.path).should be_false
        end
      end

      it "should identify UTF-8 that is invalid Latin-1 as binary" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(utf_8)
          file.close
          differ.send(:is_binary?, file.path).should be_true
        end
      end

      it "should identify Latin-1 as text" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(latin_1)
          file.close
          differ.send(:is_binary?, file.path).should be_false
        end
      end

      it "should identify Shift-JIS that is invalid Latin-1 as binary" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(shift_jis)
          file.close
          differ.send(:is_binary?, file.path).should be_true
        end
      end
    end

    describe "when the default external encoding is Shift-JIS", :ruby_gte_19_only do

      before do
        @saved_default_external = Encoding.default_external
        Encoding.default_external = Encoding::Shift_JIS
      end

      after do
        Encoding.default_external = @saved_default_external
      end

      it "should identify normal ASCII as text" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(plain_ascii)
          file.close
          differ.send(:is_binary?, file.path).should be_false
        end
      end
      it "should identify UTF-8 that is invalid Shift-JIS as binary" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(utf_8)
          file.close
          differ.send(:is_binary?, file.path).should be_true
        end
      end

      it "should identify Latin-1 that is invalid Shift-JIS as binary" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(latin_1)
          file.close
          differ.send(:is_binary?, file.path).should be_true
        end
      end

      it "should identify Shift-JIS as text" do
        Tempfile.open("chef-util-diff-spec") do |file|
          file.write(shift_jis)
          file.close
          differ.send(:is_binary?, file.path).should be_false
        end
      end

    end
  end

end


