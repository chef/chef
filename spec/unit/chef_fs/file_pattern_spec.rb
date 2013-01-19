#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
require 'chef/chef_fs/file_pattern'

describe Chef::ChefFS::FilePattern do
  def p(str)
    Chef::ChefFS::FilePattern.new(str)
  end

  # Different kinds of patterns
  context 'with empty pattern ""' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('') }
    it 'match?' do
      pattern.match?('').should be_true
      pattern.match?('/').should be_false
      pattern.match?('a').should be_false
      pattern.match?('a/b').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should == ''
    end
    it 'could_match_children?' do
      pattern.could_match_children?('').should be_false
      pattern.could_match_children?('a/b').should be_false
    end
  end

  context 'with root pattern "/"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/') }
    it 'match?' do
      pattern.match?('/').should be_true
      pattern.match?('').should be_false
      pattern.match?('a').should be_false
      pattern.match?('/a').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should == '/'
    end
    it 'could_match_children?' do
      pattern.could_match_children?('').should be_false
      pattern.could_match_children?('/').should be_false
      pattern.could_match_children?('a').should be_false
      pattern.could_match_children?('a/b').should be_false
      pattern.could_match_children?('/a').should be_false
    end
  end

  context 'with simple pattern "abc"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('abc') }
    it 'match?' do
      pattern.match?('abc').should be_true
      pattern.match?('a').should be_false
      pattern.match?('abcd').should be_false
      pattern.match?('/abc').should be_false
      pattern.match?('').should be_false
      pattern.match?('/').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should == 'abc'
    end
    it 'could_match_children?' do
      pattern.could_match_children?('').should be_false
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/abc').should be_false
    end
  end

  context 'with simple pattern "/abc"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc') }
    it 'match?' do
      pattern.match?('/abc').should be_true
      pattern.match?('abc').should be_false
      pattern.match?('a').should be_false
      pattern.match?('abcd').should be_false
      pattern.match?('').should be_false
      pattern.match?('/').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should == '/abc'
    end
    it 'could_match_children?' do
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/abc').should be_false
      pattern.could_match_children?('/').should be_true
      pattern.could_match_children?('').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
    end
  end

  context 'with simple pattern "abc/def/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('abc/def/ghi') }
    it 'match?' do
      pattern.match?('abc/def/ghi').should be_true
      pattern.match?('/abc/def/ghi').should be_false
      pattern.match?('abc').should be_false
      pattern.match?('abc/def').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should == 'abc/def/ghi'
    end
    it 'could_match_children?' do
      pattern.could_match_children?('abc').should be_true
      pattern.could_match_children?('xyz').should be_false
      pattern.could_match_children?('/abc').should be_false
      pattern.could_match_children?('abc/def').should be_true
      pattern.could_match_children?('abc/xyz').should be_false
      pattern.could_match_children?('abc/def/ghi').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('abc').should == 'def'
      pattern.exact_child_name_under('abc/def').should == 'ghi'
    end
  end

  context 'with simple pattern "/abc/def/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc/def/ghi') }
    it 'match?' do
      pattern.match?('/abc/def/ghi').should be_true
      pattern.match?('abc/def/ghi').should be_false
      pattern.match?('/abc').should be_false
      pattern.match?('/abc/def').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should == '/abc/def/ghi'
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/xyz').should be_false
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/abc/def').should be_true
      pattern.could_match_children?('/abc/xyz').should be_false
      pattern.could_match_children?('/abc/def/ghi').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
      pattern.exact_child_name_under('/abc').should == 'def'
      pattern.exact_child_name_under('/abc/def').should == 'ghi'
    end
  end

  context 'with simple pattern "a\*\b"', :pending => (Chef::Platform.windows?) do
    let(:pattern) { Chef::ChefFS::FilePattern.new('a\*\b') }
    it 'match?' do
      pattern.match?('a*b').should be_true
      pattern.match?('ab').should be_false
      pattern.match?('acb').should be_false
      pattern.match?('ab').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should == 'a*b'
    end
    it 'could_match_children?' do
      pattern.could_match_children?('a/*b').should be_false
    end
  end

  context 'with star pattern "/abc/*/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc/*/ghi') }
    it 'match?' do
      pattern.match?('/abc/def/ghi').should be_true
      pattern.match?('/abc/ghi').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/xyz').should be_false
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/abc/def').should be_true
      pattern.could_match_children?('/abc/xyz').should be_true
      pattern.could_match_children?('/abc/def/ghi').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
      pattern.exact_child_name_under('/abc').should == nil
      pattern.exact_child_name_under('/abc/def').should == 'ghi'
    end
  end

  context 'with star pattern "/abc/d*f/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc/d*f/ghi') }
    it 'match?' do
      pattern.match?('/abc/def/ghi').should be_true
      pattern.match?('/abc/dxf/ghi').should be_true
      pattern.match?('/abc/df/ghi').should be_true
      pattern.match?('/abc/dxyzf/ghi').should be_true
      pattern.match?('/abc/d/ghi').should be_false
      pattern.match?('/abc/f/ghi').should be_false
      pattern.match?('/abc/ghi').should be_false
      pattern.match?('/abc/xyz/ghi').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/xyz').should be_false
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/abc/def').should be_true
      pattern.could_match_children?('/abc/xyz').should be_false
      pattern.could_match_children?('/abc/dxyzf').should be_true
      pattern.could_match_children?('/abc/df').should be_true
      pattern.could_match_children?('/abc/d').should be_false
      pattern.could_match_children?('/abc/f').should be_false
      pattern.could_match_children?('/abc/def/ghi').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
      pattern.exact_child_name_under('/abc').should == nil
      pattern.exact_child_name_under('/abc/def').should == 'ghi'
    end
  end

  context 'with star pattern "/abc/d??f/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc/d??f/ghi') }
    it 'match?' do
      pattern.match?('/abc/deef/ghi').should be_true
      pattern.match?('/abc/deeef/ghi').should be_false
      pattern.match?('/abc/def/ghi').should be_false
      pattern.match?('/abc/df/ghi').should be_false
      pattern.match?('/abc/d/ghi').should be_false
      pattern.match?('/abc/f/ghi').should be_false
      pattern.match?('/abc/ghi').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/xyz').should be_false
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/abc/deef').should be_true
      pattern.could_match_children?('/abc/deeef').should be_false
      pattern.could_match_children?('/abc/def').should be_false
      pattern.could_match_children?('/abc/df').should be_false
      pattern.could_match_children?('/abc/d').should be_false
      pattern.could_match_children?('/abc/f').should be_false
      pattern.could_match_children?('/abc/deef/ghi').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
      pattern.exact_child_name_under('/abc').should == nil
      pattern.exact_child_name_under('/abc/deef').should == 'ghi'
    end
  end

  context 'with star pattern "/abc/d[a-z][0-9]f/ghi"', :pending => (Chef::Platform.windows?) do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc/d[a-z][0-9]f/ghi') }
    it 'match?' do
      pattern.match?('/abc/de1f/ghi').should be_true
      pattern.match?('/abc/deef/ghi').should be_false
      pattern.match?('/abc/d11f/ghi').should be_false
      pattern.match?('/abc/de11f/ghi').should be_false
      pattern.match?('/abc/dee1f/ghi').should be_false
      pattern.match?('/abc/df/ghi').should be_false
      pattern.match?('/abc/d/ghi').should be_false
      pattern.match?('/abc/f/ghi').should be_false
      pattern.match?('/abc/ghi').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/xyz').should be_false
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/abc/de1f').should be_true
      pattern.could_match_children?('/abc/deef').should be_false
      pattern.could_match_children?('/abc/d11f').should be_false
      pattern.could_match_children?('/abc/de11f').should be_false
      pattern.could_match_children?('/abc/dee1f').should be_false
      pattern.could_match_children?('/abc/def').should be_false
      pattern.could_match_children?('/abc/df').should be_false
      pattern.could_match_children?('/abc/d').should be_false
      pattern.could_match_children?('/abc/f').should be_false
      pattern.could_match_children?('/abc/de1f/ghi').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
      pattern.exact_child_name_under('/abc').should == nil
      pattern.exact_child_name_under('/abc/de1f').should == 'ghi'
    end
  end

  context 'with star pattern "/abc/**/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc/**/ghi') }
    it 'match?' do
      pattern.match?('/abc/def/ghi').should be_true
      pattern.match?('/abc/d/e/f/ghi').should be_true
      pattern.match?('/abc/ghi').should be_false
      pattern.match?('/abcdef/d/ghi').should be_false
      pattern.match?('/abc/d/defghi').should be_false
      pattern.match?('/xyz').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/abc/d').should be_true
      pattern.could_match_children?('/abc/d/e').should be_true
      pattern.could_match_children?('/abc/d/e/f').should be_true
      pattern.could_match_children?('/abc/def/ghi').should be_true
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/xyz').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
      pattern.exact_child_name_under('/abc').should == nil
      pattern.exact_child_name_under('/abc/def').should == nil
    end
  end

  context 'with star pattern "/abc**/ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc**/ghi') }
    it 'match?' do
      pattern.match?('/abc/def/ghi').should be_true
      pattern.match?('/abc/d/e/f/ghi').should be_true
      pattern.match?('/abc/ghi').should be_true
      pattern.match?('/abcdef/ghi').should be_true
      pattern.match?('/abc/defghi').should be_false
      pattern.match?('/xyz').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/abcdef').should be_true
      pattern.could_match_children?('/abc/d/e').should be_true
      pattern.could_match_children?('/abc/d/e/f').should be_true
      pattern.could_match_children?('/abc/def/ghi').should be_true
      pattern.could_match_children?('abc').should be_false
    end
    it 'could_match_children? /abc** returns false for /xyz' do
      pending 'Make could_match_children? more rigorous' do
        # At the moment, we return false for this, but in the end it would be nice to return true:
        pattern.could_match_children?('/xyz').should be_false
      end
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == nil
      pattern.exact_child_name_under('/abc').should == nil
      pattern.exact_child_name_under('/abc/def').should == nil
    end
  end

  context 'with star pattern "/abc/**ghi"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('/abc/**ghi') }
    it 'match?' do
      pattern.match?('/abc/def/ghi').should be_true
      pattern.match?('/abc/def/ghi/ghi').should be_true
      pattern.match?('/abc/def/ghi/jkl').should be_false
      pattern.match?('/abc/d/e/f/ghi').should be_true
      pattern.match?('/abc/ghi').should be_true
      pattern.match?('/abcdef/ghi').should be_false
      pattern.match?('/abc/defghi').should be_true
      pattern.match?('/xyz').should be_false
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
    it 'could_match_children?' do
      pattern.could_match_children?('/abc').should be_true
      pattern.could_match_children?('/abcdef').should be_false
      pattern.could_match_children?('/abc/d/e').should be_true
      pattern.could_match_children?('/abc/d/e/f').should be_true
      pattern.could_match_children?('/abc/def/ghi').should be_true
      pattern.could_match_children?('abc').should be_false
      pattern.could_match_children?('/xyz').should be_false
    end
    it 'exact_child_name_under' do
      pattern.exact_child_name_under('/').should == 'abc'
      pattern.exact_child_name_under('/abc').should == nil
      pattern.exact_child_name_under('/abc/def').should == nil
    end
  end

  context 'with star pattern "a**b**c"' do
    let(:pattern) { Chef::ChefFS::FilePattern.new('a**b**c') }
    it 'match?' do
      pattern.match?('axybzwc').should be_true
      pattern.match?('abc').should be_true
      pattern.match?('axyzwc').should be_false
      pattern.match?('ac').should be_false
      pattern.match?('a/x/y/b/z/w/c').should be_true
    end
    it 'exact_path' do
      pattern.exact_path.should be_nil
    end
  end

  context 'normalization tests' do
    it 'handles trailing slashes' do
      p('abc/').normalized_pattern.should == 'abc'
      p('abc/').exact_path.should == 'abc'
      p('abc/').match?('abc').should be_true
      p('//').normalized_pattern.should == '/'
      p('//').exact_path.should == '/'
      p('//').match?('/').should be_true
      p('/./').normalized_pattern.should == '/'
      p('/./').exact_path.should == '/'
      p('/./').match?('/').should be_true
    end
    it 'handles multiple slashes' do
      p('abc//def').normalized_pattern.should == 'abc/def'
      p('abc//def').exact_path.should == 'abc/def'
      p('abc//def').match?('abc/def').should be_true
      p('abc//').normalized_pattern.should == 'abc'
      p('abc//').exact_path.should == 'abc'
      p('abc//').match?('abc').should be_true
    end
    it 'handles dot' do
      p('abc/./def').normalized_pattern.should == 'abc/def'
      p('abc/./def').exact_path.should == 'abc/def'
      p('abc/./def').match?('abc/def').should be_true
      p('./abc/def').normalized_pattern.should == 'abc/def'
      p('./abc/def').exact_path.should == 'abc/def'
      p('./abc/def').match?('abc/def').should be_true
      p('/.').normalized_pattern.should == '/'
      p('/.').exact_path.should == '/'
      p('/.').match?('/').should be_true
    end
    it 'handles dot by itself', :pending => "decide what to do with dot by itself" do
      p('.').normalized_pattern.should == '.'
      p('.').exact_path.should == '.'
      p('.').match?('.').should be_true
      p('./').normalized_pattern.should == '.'
      p('./').exact_path.should == '.'
      p('./').match?('.').should be_true
    end
    it 'handles dotdot' do
      p('abc/../def').normalized_pattern.should == 'def'
      p('abc/../def').exact_path.should == 'def'
      p('abc/../def').match?('def').should be_true
      p('abc/def/../..').normalized_pattern.should == ''
      p('abc/def/../..').exact_path.should == ''
      p('abc/def/../..').match?('').should be_true
      p('/*/../def').normalized_pattern.should == '/def'
      p('/*/../def').exact_path.should == '/def'
      p('/*/../def').match?('/def').should be_true
      p('/*/*/../def').normalized_pattern.should == '/*/def'
      p('/*/*/../def').exact_path.should be_nil
      p('/*/*/../def').match?('/abc/def').should be_true
      p('/abc/def/../..').normalized_pattern.should == '/'
      p('/abc/def/../..').exact_path.should == '/'
      p('/abc/def/../..').match?('/').should be_true
      p('abc/../../def').normalized_pattern.should == '../def'
      p('abc/../../def').exact_path.should == '../def'
      p('abc/../../def').match?('../def').should be_true
    end
    it 'handles dotdot with double star' do
      p('abc**/def/../ghi').exact_path.should be_nil
      p('abc**/def/../ghi').match?('abc/ghi').should be_true
      p('abc**/def/../ghi').match?('abc/x/y/z/ghi').should be_true
      p('abc**/def/../ghi').match?('ghi').should be_false
    end
    it 'raises error on dotdot with overlapping double star' do
      lambda { Chef::ChefFS::FilePattern.new('abc/**/../def').exact_path }.should raise_error(ArgumentError)
      lambda { Chef::ChefFS::FilePattern.new('abc/**/abc/../../def').exact_path }.should raise_error(ArgumentError)
    end
    it 'handles leading dotdot' do
      p('../abc/def').exact_path.should == '../abc/def'
      p('../abc/def').match?('../abc/def').should be_true
      p('/../abc/def').exact_path.should == '/abc/def'
      p('/../abc/def').match?('/abc/def').should be_true
      p('..').exact_path.should == '..'
      p('..').match?('..').should be_true
      p('/..').exact_path.should == '/'
      p('/..').match?('/').should be_true
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
