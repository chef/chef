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
  let(:path_helper) { Chef::Util::PathHelper }

  describe "validate_path" do
    context "on windows" do
      before(:each) do
        # pass by default
        Chef::Platform.stub(:windows?).and_return(true)
        path_helper.stub(:printable?).and_return(true)
        path_helper.stub(:windows_max_length_exceeded?).and_return(false)
      end

      it "returns the path if the path passes the tests" do
        expect(path_helper.validate_path("C:\\ThisIsRigged")).to eql("C:\\ThisIsRigged")
      end

      it "does not raise an error if everything looks great" do
        expect { path_helper.validate_path("C:\\cool path\\dude.exe") }.not_to raise_error
      end

      it "raises an error if the path has invalid characters" do
        path_helper.stub(:printable?).and_return(false)
        expect { path_helper.validate_path("Newline!\n") }.to raise_error(Chef::Exceptions::ValidationFailed)
      end

      it "Adds the \\\\?\\ prefix if the path exceeds MAX_LENGTH and does not have it" do
        long_path = "C:\\" + "a" * 250 + "\\" + "b" * 250
        prefixed_long_path = "\\\\?\\" + long_path
        path_helper.stub(:windows_max_length_exceeded?).and_return(true)
        expect(path_helper.validate_path(long_path)).to eql(prefixed_long_path)
      end
    end
  end

  describe "windows_max_length_exceeded?" do
    it "returns true if the path is too long (259 + NUL) for the API" do
      expect(path_helper.windows_max_length_exceeded?("C:\\" + "a" * 250 + "\\" + "b" * 6)).to be_true
    end

    it "returns false if the path is not too long (259 + NUL) for the standard API" do
      expect(path_helper.windows_max_length_exceeded?("C:\\" + "a" * 250 + "\\" + "b" * 5)).to be_false
    end

    it "returns false if the path is over 259 characters but uses the \\\\?\\ prefix" do
      expect(path_helper.windows_max_length_exceeded?("\\\\?\\C:\\" + "a" * 250 + "\\" + "b" * 250)).to be_false
    end
  end

  describe "printable?" do
    it "returns true if the string contains no non-printable characters" do
      expect(path_helper.printable?("C:\\Program Files (x86)\\Microsoft Office\\Files.lst")).to be_true
    end

    it "returns true when given 'abc' in unicode" do
      expect(path_helper.printable?("\u0061\u0062\u0063")).to be_true
    end

    it "returns true when given japanese unicode" do
      expect(path_helper.printable?("\uff86\uff87\uff88")).to be_true
    end

    it "returns false if the string contains a non-printable character" do
      expect(path_helper.printable?("\my files\work\notes.txt")).to be_false
    end

    # This isn't necessarily a requirement, but here to be explicit about functionality.
    it "returns false if the string contains a newline or tab" do
      expect(path_helper.printable?("\tThere's no way,\n\t *no* way,\n\t that you came from my loins.\n")).to be_false
    end
  end

  describe "canonical_path" do
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

    context "not on windows", :unix_only  do
      context "ruby is at least 1.9", :ruby_gte_19_only do
        it "returns a canonical path" do
          expect(path_helper.canonical_path("/etc//apache.d/sites-enabled/../sites-available/default")).to eq("/etc/apache.d/sites-available/default")
        end
      end

      context "ruby is less than 1.9", :ruby_18_only do
        it "returns a canonical path" do
          expect { path_helper.canonical_path("/etc//apache.d/sites-enabled/../sites-available/default") }.to raise_error(NotImplementedError)
        end
      end
    end
  end

  describe "paths_eql?" do
    it "returns true if the paths are the same" do
      path_helper.stub(:canonical_path).with("bandit").and_return("c:/bandit/bandit")
      path_helper.stub(:canonical_path).with("../bandit/bandit").and_return("c:/bandit/bandit")
      expect(path_helper.paths_eql?("bandit", "../bandit/bandit")).to be_true
    end

    it "returns false if the paths are different" do
      path_helper.stub(:canonical_path).with("bandit").and_return("c:/Bo/Bandit")
      path_helper.stub(:canonical_path).with("../bandit/bandit").and_return("c:/bandit/bandit")
      expect(path_helper.paths_eql?("bandit", "../bandit/bandit")).to be_false
     end
  end
end
