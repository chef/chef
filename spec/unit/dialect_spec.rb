#
# Copyright:: Copyright (c) 2013 Noah Kantrowitz
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
require 'chef/dialect'

class TestDialect1 < Chef::Dialect
  register_dialect :recipe, 'test1', 'test/one'
  register_dialect :attributes, 'test1', 'test/one'
end

class TestDialect2 < Chef::Dialect
  register_dialect :recipe, 'test2', 'test/two'
end

# High quality to override TestDialect2
class TestDialect2Plus < Chef::Dialect
  register_dialect :recipe, 'test2', 'test/two', 10
end

describe Chef::Dialect do
  describe 'find_by_extension' do
    it 'should find a registered extension' do
      Chef::Dialect.find_by_extension(:recipe, 'test1').should == TestDialect1
    end

    it 'should raise an exception on unregistered extension' do
      lambda { Chef::Dialect.find_by_extension(:recipe, 'notfound') }.should raise_error(Chef::Exceptions::DialectNotFound)
    end

    it 'should allow higher quality to take priority' do
      Chef::Dialect.find_by_extension(:recipe, 'test2').should == TestDialect2Plus
    end
  end

  describe 'find_by_mime_type' do
    it 'should find a registered MIME type' do
      Chef::Dialect.find_by_mime_type(:recipe, 'test/one').should == TestDialect1
    end

    it 'should raise an exception on unregistered MIME type' do
      lambda { Chef::Dialect.find_by_mime_type(:recipe, '404/notfound') }.should raise_error(Chef::Exceptions::DialectNotFound)
    end

    it 'should allow higher quality to take priority' do
      Chef::Dialect.find_by_mime_type(:recipe, 'test/two').should == TestDialect2Plus
    end
  end
end
