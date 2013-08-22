#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'chef/deprecation/warnings'

describe Chef::Deprecation do

  # Support code for Chef::Deprecation

  def self.class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end

  module DeprecatedMethods
    def deprecated_method(value)
      @value = value
    end

    def get_value
      @value
    end
  end

  class TestClass
    extend Chef::Deprecation::Warnings
    include DeprecatedMethods
    add_deprecation_warnings_for(DeprecatedMethods.instance_methods)
  end

  method_snapshot_file = File.join(CHEF_SPEC_DATA, "file-providers-method-snapshot-chef-11-4.json")
  method_snapshot = JSON.parse(File.open(method_snapshot_file).read())

  method_snapshot.each do |class_name, old_methods|
    class_object = class_from_string(class_name)
    current_methods = class_object.public_instance_methods.map(&:to_sym)

    it "defines all methods on #{class_object} that were available in 11.0" do
      old_methods.each do |old_method|
        current_methods.should include(old_method.to_sym)
      end
    end
  end

  context 'deprecation warning messages' do
    before(:each) do
      @warning_output = [ ]
      Chef::Log.stub!(:warn) { |msg| @warning_output << msg }
    end

    it 'should be enabled for deprecated methods' do
      TestClass.new.deprecated_method(10)
      @warning_output.should_not be_empty
    end

    it 'should contain stack trace' do
      TestClass.new.deprecated_method(10)
      @warning_output.join("").include?(".rb").should be_true
    end
  end

  it 'deprecated methods should still be called' do
    test_instance = TestClass.new
    test_instance.deprecated_method(10)
    test_instance.get_value.should == 10
  end

end

