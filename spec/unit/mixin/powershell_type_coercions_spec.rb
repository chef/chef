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
require 'base64'

class Chef::PSTypeTester
  include Chef::Mixin::PowershellTypeCoercions
end

describe Chef::Mixin::PowershellTypeCoercions do
  let (:test_class) { Chef::PSTypeTester.new }

  describe '#translate_type' do
    it 'should single quote a string' do
      expect(test_class.translate_type('foo')).to eq("'foo'")
    end

    ["'", '"', '#', '`'].each do |c|
      it "should base64 encode a string that contains #{c}" do
        expect(test_class.translate_type("#{c}")).to match(Base64.strict_encode64(c))
      end
    end

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

    it 'should translat all members of an array and them by a ,' do
      expect(test_class.translate_type([true, false])).to eq('@($true,$false)')
    end

    it 'should fall back :to_psobject if we have not defined at explicit rule' do
      ps_obj = double("PSObject")
      expect(ps_obj).to receive(:to_psobject).and_return('$true')
      expect(test_class.translate_type(ps_obj)).to eq('($true)')
    end
  end
end
