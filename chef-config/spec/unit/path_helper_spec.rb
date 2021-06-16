#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef-config/path_helper"
require "spec_helper"

RSpec.describe ChefConfig::PathHelper do

  let(:path_helper) { described_class }

  context "common functionality" do
    context "join" do
      it "joins starting with '' resolve to absolute paths" do
        expect(path_helper.join("", "a", "b")).to eq("#{path_helper.path_separator}a#{path_helper.path_separator}b")
      end

      it "joins ending with '' add a / to the end" do
        expect(path_helper.join("a", "b", "")).to eq("a#{path_helper.path_separator}b#{path_helper.path_separator}")
      end
    end

    context "dirname" do
      it "dirname('abc') is '.'" do
        expect(path_helper.dirname("abc")).to eq(".")
      end
      it "dirname('/') is '/'" do
        expect(path_helper.dirname(path_helper.path_separator)).to eq(path_helper.path_separator)
      end
      it "dirname('a/b/c') is 'a/b'" do
        expect(path_helper.dirname(path_helper.join("a", "b", "c"))).to eq(path_helper.join("a", "b"))
      end
      it "dirname('a/b/c/') is 'a/b'" do
        expect(path_helper.dirname(path_helper.join("a", "b", "c", ""))).to eq(path_helper.join("a", "b"))
      end
      it "dirname('/a/b/c') is '/a/b'" do
        expect(path_helper.dirname(path_helper.join("", "a", "b", "c"))).to eq(path_helper.join("", "a", "b"))
      end
    end
  end

  context "forcing windows/non-windows" do
    context "forcing windows" do
      it "path_separator is \\" do
        expect(path_helper.path_separator(windows: true)).to eq("\\")
      end

      context "platform-specific #join behavior" do
        it "joins components on Windows when some end with unix separators" do
          expected = "C:\\foo\\bar\\baz"
          expect(path_helper.join('C:\\foo/', "bar", "baz", windows: true)).to eq(expected)
        end

        it "joins components when some end with separators" do
          expected = "C:\\foo\\bar\\baz"
          expect(path_helper.join('C:\\foo\\', "bar", "baz", windows: true)).to eq(expected)
        end

        it "joins components when some end and start with separators" do
          expected = "C:\\foo\\bar\\baz"
          expect(path_helper.join('C:\\foo\\', "bar/", "/baz", windows: true)).to eq(expected)
        end

        it "joins components that don't end in separators" do
          expected = "C:\\foo\\bar\\baz"
          expect(path_helper.join('C:\\foo', "bar", "baz", windows: true)).to eq(expected)
        end
      end

      it "cleanpath changes slashes into backslashes and leaves backslashes alone" do
        expect(path_helper.cleanpath('/a/b\\c/d/', windows: true)).to eq('\\a\\b\\c\\d')
      end

      it "cleanpath does not remove leading double backslash" do
        expect(path_helper.cleanpath('\\\\a/b\\c/d/', windows: true)).to eq('\\\\a\\b\\c\\d')
      end
    end

    context "forcing unix" do
      it "path_separator is /" do
        expect(path_helper.path_separator(windows: false)).to eq("/")
      end

      it "cleanpath removes extra slashes alone" do
        expect(path_helper.cleanpath("/a///b/c/d/", windows: false)).to eq("/a/b/c/d")
      end

      context "platform-specific #join behavior" do
        it "joins components when some end with separators" do
          expected = "/foo/bar/baz"
          expect(path_helper.join("/foo/", "bar", "baz", windows: false)).to eq(expected)
        end

        it "joins components when some end and start with separators" do
          expected = "/foo/bar/baz"
          expect(path_helper.join("/foo/", "bar/", "/baz", windows: false)).to eq(expected)
        end

        it "joins components that don't end in separators" do
          expected = "/foo/bar/baz"
          expect(path_helper.join("/foo", "bar", "baz", windows: false)).to eq(expected)
        end
      end

      it "cleanpath changes backslashes into slashes and leaves slashes alone" do
        expect(path_helper.cleanpath('/a/b\\c/d/', windows: false)).to eq("/a/b/c/d")
      end

      it "cleanpath does not remove leading double backslash" do
        expect(path_helper.cleanpath('\\\\a/b\\c/d/', windows: false)).to eq("//a/b/c/d")
      end
    end
  end

  context "on windows", :windows_only do

    before(:each) do
      allow(ChefUtils).to receive(:windows?).and_return(true)
    end

    it "path_separator is \\" do
      expect(path_helper.path_separator).to eq("\\")
    end

    context "platform-specific #join behavior" do
      it "joins components on Windows when some end with unix separators" do
        expected = "C:\\foo\\bar\\baz"
        expect(path_helper.join('C:\\foo/', "bar", "baz")).to eq(expected)
      end

      it "joins components when some end with separators" do
        expected = "C:\\foo\\bar\\baz"
        expect(path_helper.join('C:\\foo\\', "bar", "baz")).to eq(expected)
      end

      it "joins components when some end and start with separators" do
        expected = "C:\\foo\\bar\\baz"
        expect(path_helper.join('C:\\foo\\', "bar/", "/baz")).to eq(expected)
      end

      it "joins components that don't end in separators" do
        expected = "C:\\foo\\bar\\baz"
        expect(path_helper.join('C:\\foo', "bar", "baz")).to eq(expected)
      end
    end

    it "cleanpath changes slashes into backslashes and leaves backslashes alone" do
      expect(path_helper.cleanpath('/a/b\\c/d/')).to eq('\\a\\b\\c\\d')
    end

    it "cleanpath does not remove leading double backslash" do
      expect(path_helper.cleanpath('\\\\a/b\\c/d/')).to eq('\\\\a\\b\\c\\d')
    end
  end

  context "on unix", :unix_only do
    before(:each) do
      allow(ChefUtils).to receive(:windows?).and_return(false)
    end

    it "path_separator is /" do
      expect(path_helper.path_separator).to eq("/")
    end

    it "cleanpath removes extra slashes alone" do
      expect(path_helper.cleanpath("/a///b/c/d/")).to eq("/a/b/c/d")
    end

    context "platform-specific #join behavior" do
      it "joins components when some end with separators" do
        expected = path_helper.cleanpath("/foo/bar/baz")
        expect(path_helper.join("/foo/", "bar", "baz")).to eq(expected)
      end

      it "joins components when some end and start with separators" do
        expected = path_helper.cleanpath("/foo/bar/baz")
        expect(path_helper.join("/foo/", "bar/", "/baz")).to eq(expected)
      end

      it "joins components that don't end in separators" do
        expected = path_helper.cleanpath("/foo/bar/baz")
        expect(path_helper.join("/foo", "bar", "baz")).to eq(expected)
      end
    end

    it "cleanpath changes backslashes into slashes and leaves slashes alone" do
      expect(path_helper.cleanpath('/a/b\\c/d/', windows: false)).to eq("/a/b/c/d")
    end

    # NOTE: this seems a bit weird to me, but this is just the way Pathname#cleanpath works
    it "cleanpath does not remove leading double backslash" do
      expect(path_helper.cleanpath('\\\\a/b\\c/d/')).to eq("//a/b/c/d")
    end
  end

  context "validate_path" do
    context "on windows" do
      before(:each) do
        # pass by default
        allow(ChefUtils).to receive(:windows?).and_return(true)
        allow(path_helper).to receive(:printable?).and_return(true)
        allow(path_helper).to receive(:windows_max_length_exceeded?).and_return(false)
      end

      it "returns the path if the path passes the tests" do
        expect(path_helper.validate_path("C:\\ThisIsRigged")).to eql("C:\\ThisIsRigged")
      end

      it "does not raise an error if everything looks great" do
        expect { path_helper.validate_path("C:\\cool path\\dude.exe") }.not_to raise_error
      end

      it "raises an error if the path has invalid characters" do
        allow(path_helper).to receive(:printable?).and_return(false)
        expect { path_helper.validate_path("Newline!\n") }.to raise_error(ChefConfig::InvalidPath)
      end

      it "Adds the \\\\?\\ prefix if the path exceeds MAX_LENGTH and does not have it" do
        long_path = "C:\\" + "a" * 250 + "\\" + "b" * 250
        prefixed_long_path = "\\\\?\\" + long_path
        allow(path_helper).to receive(:windows_max_length_exceeded?).and_return(true)
        expect(path_helper.validate_path(long_path)).to eql(prefixed_long_path)
      end
    end
  end

  context "windows_max_length_exceeded?" do
    it "returns true if the path is too long (259 + NUL) for the API" do
      expect(path_helper.windows_max_length_exceeded?("C:\\" + "a" * 250 + "\\" + "b" * 6)).to be_truthy
    end

    it "returns false if the path is not too long (259 + NUL) for the standard API" do
      expect(path_helper.windows_max_length_exceeded?("C:\\" + "a" * 250 + "\\" + "b" * 5)).to be_falsey
    end

    it "returns false if the path is over 259 characters but uses the \\\\?\\ prefix" do
      expect(path_helper.windows_max_length_exceeded?("\\\\?\\C:\\" + "a" * 250 + "\\" + "b" * 250)).to be_falsey
    end
  end

  context "printable?" do
    it "returns true if the string contains no non-printable characters" do
      expect(path_helper.printable?("C:\\Program Files (x86)\\Microsoft Office\\Files.lst")).to be_truthy
    end

    it "returns true when given 'abc' in unicode" do
      expect(path_helper.printable?("\u0061\u0062\u0063")).to be_truthy
    end

    it "returns true when given japanese unicode" do
      expect(path_helper.printable?("\uff86\uff87\uff88")).to be_truthy
    end

    it "returns false if the string contains a non-printable character" do
      expect(path_helper.printable?("\my files\work\notes.txt")).to be_falsey
    end

    # This isn't necessarily a requirement, but here to be explicit about functionality.
    it "returns false if the string contains a newline or tab" do
      expect(path_helper.printable?("\tThere's no way,\n\t *no* way,\n\t that you came from my loins.\n")).to be_falsey
    end
  end

  context "canonical_path" do
    context "on windows", :windows_only do
      it "returns an absolute path with backslashes instead of slashes" do
        expect(path_helper.canonical_path("\\\\?\\C:/windows/win.ini")).to eq("\\\\?\\c:\\windows\\win.ini")
      end

      it "adds the \\\\?\\ prefix if it is missing" do
        expect(path_helper.canonical_path("C:/windows/win.ini")).to eq("\\\\?\\c:\\windows\\win.ini")
      end

      it "returns a lowercase path" do
        expect(path_helper.canonical_path("\\\\?\\C:\\CASE\\INSENSITIVE")).to eq("\\\\?\\c:\\case\\insensitive")
      end
    end

    context "not on windows", :unix_only do
      it "returns a canonical path" do
        expect(path_helper.canonical_path("/etc//apache.d/sites-enabled/../sites-available/default")).to eq("/etc/apache.d/sites-available/default")
      end
    end
  end

  context "paths_eql?" do
    it "returns true if the paths are the same" do
      allow(path_helper).to receive(:canonical_path).with("bandit", windows: ChefUtils.windows?).and_return("c:/bandit/bandit")
      allow(path_helper).to receive(:canonical_path).with("../bandit/bandit", windows: ChefUtils.windows?).and_return("c:/bandit/bandit")
      expect(path_helper.paths_eql?("bandit", "../bandit/bandit")).to be_truthy
    end

    it "returns false if the paths are different" do
      allow(path_helper).to receive(:canonical_path).with("bandit", windows: ChefUtils.windows?).and_return("c:/Bo/Bandit")
      allow(path_helper).to receive(:canonical_path).with("../bandit/bandit", windows: ChefUtils.windows?).and_return("c:/bandit/bandit")
      expect(path_helper.paths_eql?("bandit", "../bandit/bandit")).to be_falsey
    end
  end

  context "escape_glob" do
    it "escapes characters reserved by glob" do
      path = "C:\\this\\*path\\[needs]\\escaping?"
      escaped_path = "C:\\\\this\\\\\\*path\\\\\\[needs\\]\\\\escaping\\?"
      expect(path_helper.escape_glob(path, windows: true)).to eq(escaped_path)
    end

    context "when given more than one argument" do
      it "joins, cleanpaths, and escapes characters reserved by glob" do
        args = ["this/*path", "[needs]", "escaping?"]
        escaped_path = if ChefUtils.windows?
                         "this\\\\\\*path\\\\\\[needs\\]\\\\escaping\\?"
                       else
                         "this/\\*path/\\[needs\\]/escaping\\?"
                       end
        expect(path_helper.escape_glob(*args)).to eq(escaped_path)
      end
    end
  end

  context "escape_glob_dir" do
    it "escapes characters reserved by glob without using backslashes for path separators" do
      path = "C:/this/*path/[needs]/escaping?"
      escaped_path = "C:/this/\\*path/\\[needs\\]/escaping\\?"
      expect(path_helper.escape_glob_dir(path)).to eq(escaped_path)
    end

    context "when given more than one argument" do
      it "joins, cleanpaths, and escapes characters reserved by glob" do
        args = ["this/*path", "[needs]", "escaping?"]
        escaped_path = "this/\\*path/\\[needs\\]/escaping\\?"
        expect(path_helper).to receive(:join).with(*args).and_call_original
        expect(path_helper.escape_glob_dir(*args)).to eq(escaped_path)
      end
    end
  end

  context "all_homes" do
    before do
      stub_const("ENV", env)
      allow(ChefUtils).to receive(:windows?).and_return(is_windows)
    end

    context "on windows" do
      let(:is_windows) { true }
    end

    context "on unix" do
      let(:is_windows) { false }

      context "when HOME is not set" do
        let(:env) { {} }
        it "returns an empty array" do
          expect(path_helper.all_homes).to eq([])
        end
      end
    end
  end
end
