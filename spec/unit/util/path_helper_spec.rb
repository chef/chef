#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/util/path_helper'
require 'spec_helper'

describe Chef::Util::PathHelper do
  PathHelper = Chef::Util::PathHelper

  [ false, true ].each do |is_windows|
    context "on #{is_windows ? "windows" : "unix"}" do
      before(:each) do
        allow(Chef::Platform).to receive(:windows?).and_return(is_windows)
      end

      describe "join" do
        it "joins components when some end with separators" do
          expected = PathHelper.cleanpath("/foo/bar/baz")
          expected = "C:#{expected}" if is_windows
          expect(PathHelper.join(is_windows ? 'C:\\foo\\' : "/foo/", "bar", "baz")).to eq(expected)
        end

        it "joins components when some end and start with separators" do
          expected = PathHelper.cleanpath("/foo/bar/baz")
          expected = "C:#{expected}" if is_windows
          expect(PathHelper.join(is_windows ? 'C:\\foo\\' : "/foo/", "bar/", "/baz")).to eq(expected)
        end

        it "joins components that don't end in separators" do
          expected = PathHelper.cleanpath("/foo/bar/baz")
          expected = "C:#{expected}" if is_windows
          expect(PathHelper.join(is_windows ? 'C:\\foo' : "/foo", "bar", "baz")).to eq(expected)
        end

        it "joins starting with '' resolve to absolute paths" do
          expect(PathHelper.join('', 'a', 'b')).to eq("#{PathHelper.path_separator}a#{PathHelper.path_separator}b")
        end

        it "joins ending with '' add a / to the end" do
          expect(PathHelper.join('a', 'b', '')).to eq("a#{PathHelper.path_separator}b#{PathHelper.path_separator}")
        end

        if is_windows
          it "joins components on Windows when some end with unix separators" do
            expect(PathHelper.join('C:\\foo/', "bar", "baz")).to eq('C:\\foo\\bar\\baz')
          end
        end
      end

      if is_windows
        it "path_separator is \\" do
          expect(PathHelper.path_separator).to eq('\\')
        end
      else
        it "path_separator is /" do
          expect(PathHelper.path_separator).to eq('/')
        end
      end

      if is_windows
        it "cleanpath changes slashes into backslashes and leaves backslashes alone" do
          expect(PathHelper.cleanpath('/a/b\\c/d/')).to eq('\\a\\b\\c\\d')
        end
        it "cleanpath does not remove leading double backslash" do
          expect(PathHelper.cleanpath('\\\\a/b\\c/d/')).to eq('\\\\a\\b\\c\\d')
        end
      else
        it "cleanpath removes extra slashes alone" do
          expect(PathHelper.cleanpath('/a///b/c/d/')).to eq('/a/b/c/d')
        end
      end

      describe "dirname" do
        it "dirname('abc') is '.'" do
          expect(PathHelper.dirname('abc')).to eq('.')
        end
        it "dirname('/') is '/'" do
          expect(PathHelper.dirname(PathHelper.path_separator)).to eq(PathHelper.path_separator)
        end
        it "dirname('a/b/c') is 'a/b'" do
          expect(PathHelper.dirname(PathHelper.join('a', 'b', 'c'))).to eq(PathHelper.join('a', 'b'))
        end
        it "dirname('a/b/c/') is 'a/b'" do
          expect(PathHelper.dirname(PathHelper.join('a', 'b', 'c', ''))).to eq(PathHelper.join('a', 'b'))
        end
        it "dirname('/a/b/c') is '/a/b'" do
          expect(PathHelper.dirname(PathHelper.join('', 'a', 'b', 'c'))).to eq(PathHelper.join('', 'a', 'b'))
        end
      end
    end
  end

  describe "validate_path" do
    context "on windows" do
      before(:each) do
        # pass by default
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(PathHelper).to receive(:printable?).and_return(true)
        allow(PathHelper).to receive(:windows_max_length_exceeded?).and_return(false)
      end

      it "returns the path if the path passes the tests" do
        expect(PathHelper.validate_path("C:\\ThisIsRigged")).to eql("C:\\ThisIsRigged")
      end

      it "does not raise an error if everything looks great" do
        expect { PathHelper.validate_path("C:\\cool path\\dude.exe") }.not_to raise_error
      end

      it "raises an error if the path has invalid characters" do
        allow(PathHelper).to receive(:printable?).and_return(false)
        expect { PathHelper.validate_path("Newline!\n") }.to raise_error(Chef::Exceptions::ValidationFailed)
      end

      it "Adds the \\\\?\\ prefix if the path exceeds MAX_LENGTH and does not have it" do
        long_path = "C:\\" + "a" * 250 + "\\" + "b" * 250
        prefixed_long_path = "\\\\?\\" + long_path
        allow(PathHelper).to receive(:windows_max_length_exceeded?).and_return(true)
        expect(PathHelper.validate_path(long_path)).to eql(prefixed_long_path)
      end
    end
  end

  describe "windows_max_length_exceeded?" do
    it "returns true if the path is too long (259 + NUL) for the API" do
      expect(PathHelper.windows_max_length_exceeded?("C:\\" + "a" * 250 + "\\" + "b" * 6)).to be_truthy
    end

    it "returns false if the path is not too long (259 + NUL) for the standard API" do
      expect(PathHelper.windows_max_length_exceeded?("C:\\" + "a" * 250 + "\\" + "b" * 5)).to be_falsey
    end

    it "returns false if the path is over 259 characters but uses the \\\\?\\ prefix" do
      expect(PathHelper.windows_max_length_exceeded?("\\\\?\\C:\\" + "a" * 250 + "\\" + "b" * 250)).to be_falsey
    end
  end

  describe "printable?" do
    it "returns true if the string contains no non-printable characters" do
      expect(PathHelper.printable?("C:\\Program Files (x86)\\Microsoft Office\\Files.lst")).to be_truthy
    end

    it "returns true when given 'abc' in unicode" do
      expect(PathHelper.printable?("\u0061\u0062\u0063")).to be_truthy
    end

    it "returns true when given japanese unicode" do
      expect(PathHelper.printable?("\uff86\uff87\uff88")).to be_truthy
    end

    it "returns false if the string contains a non-printable character" do
      expect(PathHelper.printable?("\my files\work\notes.txt")).to be_falsey
    end

    # This isn't necessarily a requirement, but here to be explicit about functionality.
    it "returns false if the string contains a newline or tab" do
      expect(PathHelper.printable?("\tThere's no way,\n\t *no* way,\n\t that you came from my loins.\n")).to be_falsey
    end
  end

  describe "canonical_path" do
    context "on windows", :windows_only do
      it "returns an absolute path with backslashes instead of slashes" do
        expect(PathHelper.canonical_path("\\\\?\\C:/windows/win.ini")).to eq("\\\\?\\c:\\windows\\win.ini")
      end

      it "adds the \\\\?\\ prefix if it is missing" do
        expect(PathHelper.canonical_path("C:/windows/win.ini")).to eq("\\\\?\\c:\\windows\\win.ini")
      end

      it "returns a lowercase path" do
        expect(PathHelper.canonical_path("\\\\?\\C:\\CASE\\INSENSITIVE")).to eq("\\\\?\\c:\\case\\insensitive")
      end
    end

    context "not on windows", :unix_only  do
      it "returns a canonical path" do
        expect(PathHelper.canonical_path("/etc//apache.d/sites-enabled/../sites-available/default")).to eq("/etc/apache.d/sites-available/default")
      end
    end
  end

  describe "paths_eql?" do
    it "returns true if the paths are the same" do
      allow(PathHelper).to receive(:canonical_path).with("bandit").and_return("c:/bandit/bandit")
      allow(PathHelper).to receive(:canonical_path).with("../bandit/bandit").and_return("c:/bandit/bandit")
      expect(PathHelper.paths_eql?("bandit", "../bandit/bandit")).to be_truthy
    end

    it "returns false if the paths are different" do
      allow(PathHelper).to receive(:canonical_path).with("bandit").and_return("c:/Bo/Bandit")
      allow(PathHelper).to receive(:canonical_path).with("../bandit/bandit").and_return("c:/bandit/bandit")
      expect(PathHelper.paths_eql?("bandit", "../bandit/bandit")).to be_falsey
    end
  end

  describe "escape_glob" do
    it "escapes characters reserved by glob" do
      path = "C:\\this\\*path\\[needs]\\escaping?"
      escaped_path = "C:\\\\this\\\\\\*path\\\\\\[needs\\]\\\\escaping\\?"
      expect(PathHelper.escape_glob(path)).to eq(escaped_path)
    end

    context "when given more than one argument" do
      it "joins, cleanpaths, and escapes characters reserved by glob" do
        args = ["this/*path", "[needs]", "escaping?"]
        escaped_path = if windows?
          "this\\\\\\*path\\\\\\[needs\\]\\\\escaping\\?"
        else
          "this/\\*path/\\[needs\\]/escaping\\?"
        end
        expect(PathHelper).to receive(:join).with(*args).and_call_original
        expect(PathHelper).to receive(:cleanpath).and_call_original
        expect(PathHelper.escape_glob(*args)).to eq(escaped_path)
      end
    end
  end

  describe "all_homes" do
    before do
      stub_const('ENV', env)
      allow(Chef::Platform).to receive(:windows?).and_return(is_windows)
    end

    context "on windows" do
      let (:is_windows) { true }
    end

    context "on unix" do
      let (:is_windows) { false }

      context "when HOME is not set" do
        let (:env) { {} }
        it "returns an empty array" do
          expect(PathHelper.all_homes).to eq([])
        end
      end
    end
  end
end
