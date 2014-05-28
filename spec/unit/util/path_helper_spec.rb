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

  describe "invalid_path?" do
    context "on windows" do
      before(:each) do
        Chef::Platform.stub(:windows?).and_return(true)
        path_helper.stub(:printable?).and_return(true)
      end

      it "returns true if the path has invalid characters" do
        path_helper.stub(:printable?).and_return(false)
        expect(path_helper.invalid_path?("Newline!\n")).to be_true
      end

      it "returns true if the path is too long (260) for the API" do
        expect(path_helper.invalid_path?("C:\\" + "a" * 250 + "\\" + "b" * 10)).to be_true
      end

      it "returns false if the path is not too long (260) for the standard API" do
        expect(path_helper.invalid_path?("C:\\" + "a" * 250 + "\\" + "b" * 9)).to be_false
      end

      it "returns false if the path is over 260 characters but uses the \\\\?\\ prefix" do
        expect(path_helper.invalid_path?("\\\\?\\C:\\" + "a" * 250 + "\\" + "b" * 250)).to be_false
      end

    end

    it "returns nil on an unknown platform" do
      Chef::Platform.stub(:windows?).and_return(false)
      expect(path_helper.invalid_path?('fail')).to be_nil
    end
  end

  describe "native_path" do
    context "on windows" do
      it "returns an absolute path with backslashes" do
        platform_mock :windows do
          path_helper.stub(:canonical_path).with("/windows/win.ini").and_return("c:/windows/win.ini")
          expect(path_helper.native_path("/windows/win.ini")).to eq('c:\windows\win.ini')
        end
      end
    end

    context "not on windows" do
      it "returns a canonical path" do
        platform_mock :unix do
          path_helper.stub(:canonical_path).with("/etc//apache.d/sites-enabled/../sites-available/default").and_return("/etc/apache.d/sites-available/default")
          expect(path_helper.native_path("/etc//apache.d/sites-enabled/../sites-available/default")).to eq("/etc/apache.d/sites-available/default")
        end
      end
    end
  end

  describe "printable?" do
    it "returns true if the string contains no non-printable characters" do
      expect(path_helper.printable?("C:\\Program Files (x86)\\Microsoft Office\\Files.lst")).to be_true
    end

    it "returns false if the string contains a non-printable character" do
      expect(path_helper.printable?("\my files\work\notes.txt")).to be_false
    end

    # This isn't necessarily a requirement, but here to be explicit about functionality.
    it "returns false if the string contains a newline or tab" do
      expect(path_helper.printable?("\tThere's no way,\n\t *no* way,\n\t that you came from my loins.\n")).to be_false
    end
  end

  describe "paths_eql?" do
    it "returns true if the paths are the same" do
      path_helper.stub(:canonical_path).with("bandit").and_return("C:/bandit/bandit")
      path_helper.stub(:canonical_path).with("../bandit/bandit").and_return("C:/bandit/bandit")
      expect(path_helper.paths_eql?("bandit", "../bandit/bandit")).to be_true
    end

    it "returns false if the paths are different" do
      path_helper.stub(:canonical_path).with("bandit").and_return("C:/Bo/Bandit")
      path_helper.stub(:canonical_path).with("../bandit/bandit").and_return("C:/bandit/bandit")
      expect(path_helper.paths_eql?("bandit", "../bandit/bandit")).to be_false
     end
  end
end
