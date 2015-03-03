#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
require 'chef/mixin/powershell_type_coercions'

class Chef::PSTypeTester
  include Chef::Mixin::PowershellTypeCoercions
end

describe Chef::Mixin::PowershellTypeCoercions do
  let (:test_class) { Chef::PSTypeTester.new }

  describe '#translate_type' do
    it 'should not quote an integer' do
      expect(test_class.translate_type(123)).to eq('123')
    end

    it 'should not quote a floating point number' do
      expect(test_class.translate_type(123.4)).to eq('123.4')
    end

    it 'should return $false when an instance of FalseClass is provided' do
      expect(test_class.translate_type(false)).to eq('$false')
    end

    it 'should return $true when an instance of TrueClass is provided' do
      expect(test_class.translate_type(true)).to eq('$true')
    end

    it 'should translate all members of a hash and wrap them in @{} separated by ;' do
      expect(test_class.translate_type({"a" => 1, "b" => 1.2, "c" => false, "d" => true
      })).to eq("@{a=1;b=1.2;c=$false;d=$true}")
    end
  end
end
