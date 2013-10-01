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
  register_dialect :recipe, '.test1', 'test/one'
  register_dialect :attributes, '.test1', 'test/one'
end

class TestDialect2 < Chef::Dialect
  register_dialect :recipe, '.test2', 'test/two'
end

# High quality to override TestDialect2
class TestDialect2Plus < Chef::Dialect
  register_dialect :recipe, '.test2', 'test/two', 10
end

class TestDialect3 < Chef::Dialect
  register_dialect :recipe, 'test3', 'test/three'
end

describe Chef::Dialect do
  describe 'find_by_extension' do
    it 'should find a registered extension' do
      Chef::Dialect.find_by_extension(nil, :recipe, '.test1').should be_an_instance_of(TestDialect1)
    end

    it 'should raise an exception on unregistered extension' do
      lambda { Chef::Dialect.find_by_extension(nil, :recipe, '.notfound') }.should raise_error(Chef::Exceptions::DialectNotFound)
    end

    it 'should allow higher quality to take priority' do
      Chef::Dialect.find_by_extension(nil, :recipe, '.test2').should be_an_instance_of(TestDialect2Plus)
    end

    it 'should allow passing in an absolute path' do
      Chef::Dialect.find_by_extension(nil, :recipe, '/etc/foo.test1').should be_an_instance_of(TestDialect1)
    end

    it 'should allow passing in a relative path' do
      Chef::Dialect.find_by_extension(nil, :recipe, 'etc/foo.test1').should be_an_instance_of(TestDialect1)
    end

    it 'should allow passing in a simple filename' do
      Chef::Dialect.find_by_extension(nil, :recipe, 'foo.test1').should be_an_instance_of(TestDialect1)
    end

    it 'should allow passing in a filename with no extension' do
      Chef::Dialect.find_by_extension(nil, :recipe, 'test3').should be_an_instance_of(TestDialect3)
    end

    it 'should allow passing in a path with no extension' do
      Chef::Dialect.find_by_extension(nil, :recipe, 'foo/test3').should be_an_instance_of(TestDialect3)
    end

    it 'should return the same dialect instance for all uses of the same dialect' do
      d1 = Chef::Dialect.find_by_extension(nil, :recipe, '.test1')
      d2 = Chef::Dialect.find_by_extension(nil, :attributes, '.test1')
      d1.should be(d2)
    end
  end

  describe 'find_by_mime_type' do
    it 'should find a registered MIME type' do
      Chef::Dialect.find_by_mime_type(nil, :recipe, 'test/one').should be_an_instance_of(TestDialect1)
    end

    it 'should raise an exception on unregistered MIME type' do
      lambda { Chef::Dialect.find_by_mime_type(nil, :recipe, '404/notfound') }.should raise_error(Chef::Exceptions::DialectNotFound)
    end

    it 'should allow higher quality to take priority' do
      Chef::Dialect.find_by_mime_type(nil, :recipe, 'test/two').should be_an_instance_of(TestDialect2Plus)
    end
  end

  describe 'cleanup' do
    it 'should call cleanup on all active dialect instances' do
      TestDialect1.any_instance.should_receive(:cleanup).once
      Chef::Dialect.find_by_extension(nil, :recipe, '.test1')
      Chef::Dialect.cleanup
    end

    it 'should remove all dialect instances' do
      d1 = Chef::Dialect.find_by_extension(nil, :recipe, '.test1')
      Chef::Dialect.cleanup
      d2 = Chef::Dialect.find_by_extension(nil, :recipe, '.test1')
      d1.should_not be(d2)
    end
  end

end
