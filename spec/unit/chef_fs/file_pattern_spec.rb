#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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
require "chef/chef_fs/file_pattern"

describe Chef::ChefFS::FilePattern do
  def p(str)
    Chef::ChefFS::FilePattern.new(str)
  end

  # Different kinds of patterns
  context 'with empty pattern ""' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("") }
    it "match?" do
      expect(pattern.match?("")).to be_truthy
      expect(pattern.match?("/")).to be_falsey
      expect(pattern.match?("a")).to be_falsey
      expect(pattern.match?("a/b")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to eq("")
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("")).to be_falsey
      expect(pattern.could_match_children?("a/b")).to be_falsey
    end
  end

  context 'with root pattern "/"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/") }
    it "match?" do
      expect(pattern.match?("/")).to be_truthy
      expect(pattern.match?("")).to be_falsey
      expect(pattern.match?("a")).to be_falsey
      expect(pattern.match?("/a")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to eq("/")
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("")).to be_falsey
      expect(pattern.could_match_children?("/")).to be_falsey
      expect(pattern.could_match_children?("a")).to be_falsey
      expect(pattern.could_match_children?("a/b")).to be_falsey
      expect(pattern.could_match_children?("/a")).to be_falsey
    end
  end

  context 'with simple pattern "abc"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("abc") }
    it "match?" do
      expect(pattern.match?("abc")).to be_truthy
      expect(pattern.match?("a")).to be_falsey
      expect(pattern.match?("abcd")).to be_falsey
      expect(pattern.match?("/abc")).to be_falsey
      expect(pattern.match?("")).to be_falsey
      expect(pattern.match?("/")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to eq("abc")
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("")).to be_falsey
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/abc")).to be_falsey
    end
  end

  context 'with simple pattern "/abc"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc") }
    it "match?" do
      expect(pattern.match?("/abc")).to be_truthy
      expect(pattern.match?("abc")).to be_falsey
      expect(pattern.match?("a")).to be_falsey
      expect(pattern.match?("abcd")).to be_falsey
      expect(pattern.match?("")).to be_falsey
      expect(pattern.match?("/")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to eq("/abc")
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/abc")).to be_falsey
      expect(pattern.could_match_children?("/")).to be_truthy
      expect(pattern.could_match_children?("")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
    end
  end

  context 'with simple pattern "abc/def/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("abc/def/ghi") }
    it "match?" do
      expect(pattern.match?("abc/def/ghi")).to be_truthy
      expect(pattern.match?("/abc/def/ghi")).to be_falsey
      expect(pattern.match?("abc")).to be_falsey
      expect(pattern.match?("abc/def")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to eq("abc/def/ghi")
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("abc")).to be_truthy
      expect(pattern.could_match_children?("xyz")).to be_falsey
      expect(pattern.could_match_children?("/abc")).to be_falsey
      expect(pattern.could_match_children?("abc/def")).to be_truthy
      expect(pattern.could_match_children?("abc/xyz")).to be_falsey
      expect(pattern.could_match_children?("abc/def/ghi")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("abc")).to eq("def")
      expect(pattern.exact_child_name_under("abc/def")).to eq("ghi")
    end
  end

  context 'with simple pattern "/abc/def/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc/def/ghi") }
    it "match?" do
      expect(pattern.match?("/abc/def/ghi")).to be_truthy
      expect(pattern.match?("abc/def/ghi")).to be_falsey
      expect(pattern.match?("/abc")).to be_falsey
      expect(pattern.match?("/abc/def")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to eq("/abc/def/ghi")
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/xyz")).to be_falsey
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/abc/def")).to be_truthy
      expect(pattern.could_match_children?("/abc/xyz")).to be_falsey
      expect(pattern.could_match_children?("/abc/def/ghi")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
      expect(pattern.exact_child_name_under("/abc")).to eq("def")
      expect(pattern.exact_child_name_under("/abc/def")).to eq("ghi")
    end
  end

  context 'with simple pattern "a\*\b"', :skip => (Chef::Platform.windows?) do
    let(:pattern) { Chef::ChefFS::FilePattern.new('a\*\b') }
    it "match?" do
      expect(pattern.match?("a*b")).to be_truthy
      expect(pattern.match?("ab")).to be_falsey
      expect(pattern.match?("acb")).to be_falsey
      expect(pattern.match?("ab")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to eq("a*b")
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("a/*b")).to be_falsey
    end
  end

  context 'with star pattern "/abc/*/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc/*/ghi") }
    it "match?" do
      expect(pattern.match?("/abc/def/ghi")).to be_truthy
      expect(pattern.match?("/abc/ghi")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/xyz")).to be_falsey
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/abc/def")).to be_truthy
      expect(pattern.could_match_children?("/abc/xyz")).to be_truthy
      expect(pattern.could_match_children?("/abc/def/ghi")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
      expect(pattern.exact_child_name_under("/abc")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc/def")).to eq("ghi")
    end
  end

  context 'with star pattern "/abc/d*f/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc/d*f/ghi") }
    it "match?" do
      expect(pattern.match?("/abc/def/ghi")).to be_truthy
      expect(pattern.match?("/abc/dxf/ghi")).to be_truthy
      expect(pattern.match?("/abc/df/ghi")).to be_truthy
      expect(pattern.match?("/abc/dxyzf/ghi")).to be_truthy
      expect(pattern.match?("/abc/d/ghi")).to be_falsey
      expect(pattern.match?("/abc/f/ghi")).to be_falsey
      expect(pattern.match?("/abc/ghi")).to be_falsey
      expect(pattern.match?("/abc/xyz/ghi")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/xyz")).to be_falsey
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/abc/def")).to be_truthy
      expect(pattern.could_match_children?("/abc/xyz")).to be_falsey
      expect(pattern.could_match_children?("/abc/dxyzf")).to be_truthy
      expect(pattern.could_match_children?("/abc/df")).to be_truthy
      expect(pattern.could_match_children?("/abc/d")).to be_falsey
      expect(pattern.could_match_children?("/abc/f")).to be_falsey
      expect(pattern.could_match_children?("/abc/def/ghi")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
      expect(pattern.exact_child_name_under("/abc")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc/def")).to eq("ghi")
    end
  end

  context 'with star pattern "/abc/d??f/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc/d??f/ghi") }
    it "match?" do
      expect(pattern.match?("/abc/deef/ghi")).to be_truthy
      expect(pattern.match?("/abc/deeef/ghi")).to be_falsey
      expect(pattern.match?("/abc/def/ghi")).to be_falsey
      expect(pattern.match?("/abc/df/ghi")).to be_falsey
      expect(pattern.match?("/abc/d/ghi")).to be_falsey
      expect(pattern.match?("/abc/f/ghi")).to be_falsey
      expect(pattern.match?("/abc/ghi")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/xyz")).to be_falsey
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/abc/deef")).to be_truthy
      expect(pattern.could_match_children?("/abc/deeef")).to be_falsey
      expect(pattern.could_match_children?("/abc/def")).to be_falsey
      expect(pattern.could_match_children?("/abc/df")).to be_falsey
      expect(pattern.could_match_children?("/abc/d")).to be_falsey
      expect(pattern.could_match_children?("/abc/f")).to be_falsey
      expect(pattern.could_match_children?("/abc/deef/ghi")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
      expect(pattern.exact_child_name_under("/abc")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc/deef")).to eq("ghi")
    end
  end

  context 'with star pattern "/abc/d[a-z][0-9]f/ghi"', :skip => (Chef::Platform.windows?) do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc/d[a-z][0-9]f/ghi") }
    it "match?" do
      expect(pattern.match?("/abc/de1f/ghi")).to be_truthy
      expect(pattern.match?("/abc/deef/ghi")).to be_falsey
      expect(pattern.match?("/abc/d11f/ghi")).to be_falsey
      expect(pattern.match?("/abc/de11f/ghi")).to be_falsey
      expect(pattern.match?("/abc/dee1f/ghi")).to be_falsey
      expect(pattern.match?("/abc/df/ghi")).to be_falsey
      expect(pattern.match?("/abc/d/ghi")).to be_falsey
      expect(pattern.match?("/abc/f/ghi")).to be_falsey
      expect(pattern.match?("/abc/ghi")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/xyz")).to be_falsey
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/abc/de1f")).to be_truthy
      expect(pattern.could_match_children?("/abc/deef")).to be_falsey
      expect(pattern.could_match_children?("/abc/d11f")).to be_falsey
      expect(pattern.could_match_children?("/abc/de11f")).to be_falsey
      expect(pattern.could_match_children?("/abc/dee1f")).to be_falsey
      expect(pattern.could_match_children?("/abc/def")).to be_falsey
      expect(pattern.could_match_children?("/abc/df")).to be_falsey
      expect(pattern.could_match_children?("/abc/d")).to be_falsey
      expect(pattern.could_match_children?("/abc/f")).to be_falsey
      expect(pattern.could_match_children?("/abc/de1f/ghi")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
      expect(pattern.exact_child_name_under("/abc")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc/de1f")).to eq("ghi")
    end
  end

  context 'with star pattern "/abc/**/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc/**/ghi") }
    it "match?" do
      expect(pattern.match?("/abc/def/ghi")).to be_truthy
      expect(pattern.match?("/abc/d/e/f/ghi")).to be_truthy
      expect(pattern.match?("/abc/ghi")).to be_falsey
      expect(pattern.match?("/abcdef/d/ghi")).to be_falsey
      expect(pattern.match?("/abc/d/defghi")).to be_falsey
      expect(pattern.match?("/xyz")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/abc/d")).to be_truthy
      expect(pattern.could_match_children?("/abc/d/e")).to be_truthy
      expect(pattern.could_match_children?("/abc/d/e/f")).to be_truthy
      expect(pattern.could_match_children?("/abc/def/ghi")).to be_truthy
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/xyz")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
      expect(pattern.exact_child_name_under("/abc")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc/def")).to eq(nil)
    end
  end

  context 'with star pattern "/abc**/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc**/ghi") }
    it "match?" do
      expect(pattern.match?("/abc/def/ghi")).to be_truthy
      expect(pattern.match?("/abc/d/e/f/ghi")).to be_truthy
      expect(pattern.match?("/abc/ghi")).to be_truthy
      expect(pattern.match?("/abcdef/ghi")).to be_truthy
      expect(pattern.match?("/abc/defghi")).to be_falsey
      expect(pattern.match?("/xyz")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/abcdef")).to be_truthy
      expect(pattern.could_match_children?("/abc/d/e")).to be_truthy
      expect(pattern.could_match_children?("/abc/d/e/f")).to be_truthy
      expect(pattern.could_match_children?("/abc/def/ghi")).to be_truthy
      expect(pattern.could_match_children?("abc")).to be_falsey
    end

    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc/def")).to eq(nil)
    end
  end

  context 'with star pattern "/abc/**ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("/abc/**ghi") }
    it "match?" do
      expect(pattern.match?("/abc/def/ghi")).to be_truthy
      expect(pattern.match?("/abc/def/ghi/ghi")).to be_truthy
      expect(pattern.match?("/abc/def/ghi/jkl")).to be_falsey
      expect(pattern.match?("/abc/d/e/f/ghi")).to be_truthy
      expect(pattern.match?("/abc/ghi")).to be_truthy
      expect(pattern.match?("/abcdef/ghi")).to be_falsey
      expect(pattern.match?("/abc/defghi")).to be_truthy
      expect(pattern.match?("/xyz")).to be_falsey
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
    it "could_match_children?" do
      expect(pattern.could_match_children?("/abc")).to be_truthy
      expect(pattern.could_match_children?("/abcdef")).to be_falsey
      expect(pattern.could_match_children?("/abc/d/e")).to be_truthy
      expect(pattern.could_match_children?("/abc/d/e/f")).to be_truthy
      expect(pattern.could_match_children?("/abc/def/ghi")).to be_truthy
      expect(pattern.could_match_children?("abc")).to be_falsey
      expect(pattern.could_match_children?("/xyz")).to be_falsey
    end
    it "exact_child_name_under" do
      expect(pattern.exact_child_name_under("/")).to eq("abc")
      expect(pattern.exact_child_name_under("/abc")).to eq(nil)
      expect(pattern.exact_child_name_under("/abc/def")).to eq(nil)
    end
  end

  context 'with star pattern "a**b**c"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new("a**b**c") }
    it "match?" do
      expect(pattern.match?("axybzwc")).to be_truthy
      expect(pattern.match?("abc")).to be_truthy
      expect(pattern.match?("axyzwc")).to be_falsey
      expect(pattern.match?("ac")).to be_falsey
      expect(pattern.match?("a/x/y/b/z/w/c")).to be_truthy
    end
    it "exact_path" do
      expect(pattern.exact_path).to be_nil
    end
  end

  context "normalization tests" do
    it "handles trailing slashes" do
      expect(p("abc/").normalized_pattern).to eq("abc")
      expect(p("abc/").exact_path).to eq("abc")
      expect(p("abc/").match?("abc")).to be_truthy
      expect(p("//").normalized_pattern).to eq("/")
      expect(p("//").exact_path).to eq("/")
      expect(p("//").match?("/")).to be_truthy
      expect(p("/./").normalized_pattern).to eq("/")
      expect(p("/./").exact_path).to eq("/")
      expect(p("/./").match?("/")).to be_truthy
    end
    it "handles multiple slashes" do
      expect(p("abc//def").normalized_pattern).to eq("abc/def")
      expect(p("abc//def").exact_path).to eq("abc/def")
      expect(p("abc//def").match?("abc/def")).to be_truthy
      expect(p("abc//").normalized_pattern).to eq("abc")
      expect(p("abc//").exact_path).to eq("abc")
      expect(p("abc//").match?("abc")).to be_truthy
    end
    it "handles dot" do
      expect(p("abc/./def").normalized_pattern).to eq("abc/def")
      expect(p("abc/./def").exact_path).to eq("abc/def")
      expect(p("abc/./def").match?("abc/def")).to be_truthy
      expect(p("./abc/def").normalized_pattern).to eq("abc/def")
      expect(p("./abc/def").exact_path).to eq("abc/def")
      expect(p("./abc/def").match?("abc/def")).to be_truthy
      expect(p("/.").normalized_pattern).to eq("/")
      expect(p("/.").exact_path).to eq("/")
      expect(p("/.").match?("/")).to be_truthy
    end
    it "handles dotdot" do
      expect(p("abc/../def").normalized_pattern).to eq("def")
      expect(p("abc/../def").exact_path).to eq("def")
      expect(p("abc/../def").match?("def")).to be_truthy
      expect(p("abc/def/../..").normalized_pattern).to eq("")
      expect(p("abc/def/../..").exact_path).to eq("")
      expect(p("abc/def/../..").match?("")).to be_truthy
      expect(p("/*/../def").normalized_pattern).to eq("/def")
      expect(p("/*/../def").exact_path).to eq("/def")
      expect(p("/*/../def").match?("/def")).to be_truthy
      expect(p("/*/*/../def").normalized_pattern).to eq("/*/def")
      expect(p("/*/*/../def").exact_path).to be_nil
      expect(p("/*/*/../def").match?("/abc/def")).to be_truthy
      expect(p("/abc/def/../..").normalized_pattern).to eq("/")
      expect(p("/abc/def/../..").exact_path).to eq("/")
      expect(p("/abc/def/../..").match?("/")).to be_truthy
      expect(p("abc/../../def").normalized_pattern).to eq("../def")
      expect(p("abc/../../def").exact_path).to eq("../def")
      expect(p("abc/../../def").match?("../def")).to be_truthy
    end
    it "handles dotdot with double star" do
      expect(p("abc**/def/../ghi").exact_path).to be_nil
      expect(p("abc**/def/../ghi").match?("abc/ghi")).to be_truthy
      expect(p("abc**/def/../ghi").match?("abc/x/y/z/ghi")).to be_truthy
      expect(p("abc**/def/../ghi").match?("ghi")).to be_falsey
    end
    it "raises error on dotdot with overlapping double star" do
      expect { Chef::ChefFS::FilePattern.new("abc/**/../def").exact_path }.to raise_error(ArgumentError)
      expect { Chef::ChefFS::FilePattern.new("abc/**/abc/../../def").exact_path }.to raise_error(ArgumentError)
    end
    it "handles leading dotdot" do
      expect(p("../abc/def").exact_path).to eq("../abc/def")
      expect(p("../abc/def").match?("../abc/def")).to be_truthy
      expect(p("/../abc/def").exact_path).to eq("/abc/def")
      expect(p("/../abc/def").match?("/abc/def")).to be_truthy
      expect(p("..").exact_path).to eq("..")
      expect(p("..").match?("..")).to be_truthy
      expect(p("/..").exact_path).to eq("/")
      expect(p("/..").match?("/")).to be_truthy
    end
  end

  # match?
  #  - single element matches (empty, fixed, ?, *, characters, escapes)
  #  - nested matches
  #  - absolute matches
  #  - trailing slashes
  #  - **

  # exact_path
  #  - empty
  #  - single element and nested matches, with escapes
  #  - absolute and relative
  #  - ?, *, characters, **

  # could_match_children?
  #
  #
  #
  #
  context 'with pattern "abc"' do
  end

  context 'with pattern "/abc"' do
  end

  context 'with pattern "abc/def/ghi"' do
  end

  context 'with pattern "/abc/def/ghi"' do
  end

  # Exercise the different methods to their maximum
end
