#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
require "chef/deprecation/warnings"

describe Chef::Deprecation do

  # Support code for Chef::Deprecation

  def self.class_from_string(str)
    str.split("::").inject(Object) do |mod, class_name|
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

  context "when Chef::Config[:treat_deprecation_warnings_as_errors] is off" do
    before do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
    end

    context "deprecation warning messages" do
      it "should be enabled for deprecated methods" do
        expect(Chef).to receive(:deprecated).with(:internal_api, /Method.*of 'TestClass'/)
        TestClass.new.deprecated_method(10)
      end
    end

    it "deprecated methods should still be called" do
      test_instance = TestClass.new
      test_instance.deprecated_method(10)
      expect(test_instance.get_value).to eq(10)
    end
  end

  it "should raise when deprecation warnings are treated as errors" do
    # rspec should set this
    expect(Chef::Config[:treat_deprecation_warnings_as_errors]).to be true
    test_instance = TestClass.new
    expect { test_instance.deprecated_method(10) }.to raise_error(Chef::Exceptions::DeprecatedFeatureError)
  end

  context "When a class has deprecated_attr, _reader and _writer" do
    before(:context) do
      class DeprecatedAttrTest
        extend Chef::Mixin::Deprecation
        def initialize
          @a = @r = @w = 1
        end
        deprecated_attr :a, "a"
        deprecated_attr_reader :r, "r"
        deprecated_attr_writer :w, "w"
      end
    end

    it "The deprecated_attr emits warnings" do
      test = DeprecatedAttrTest.new
      expect { test.a = 10 }.to raise_error(Chef::Exceptions::DeprecatedFeatureError)
      expect { test.a }.to raise_error(Chef::Exceptions::DeprecatedFeatureError)
    end

    it "The deprecated_attr_writer emits warnings, and does not create a reader" do
      test = DeprecatedAttrTest.new
      expect { test.w = 10 }.to raise_error(Chef::Exceptions::DeprecatedFeatureError)
      expect { test.w }.to raise_error(NoMethodError)
    end

    it "The deprecated_attr_reader emits warnings, and does not create a writer" do
      test = DeprecatedAttrTest.new
      expect { test.r = 10 }.to raise_error(NoMethodError)
      expect { test.r }.to raise_error(Chef::Exceptions::DeprecatedFeatureError)
    end

    context "With deprecation warnings not throwing exceptions" do
      before do
        Chef::Config[:treat_deprecation_warnings_as_errors] = false
      end

      it "The deprecated_attr can be written to and read from" do
        test = DeprecatedAttrTest.new
        test.a = 10
        expect(test.a).to eq 10
      end

      it "The deprecated_attr_reader can be read from" do
        test = DeprecatedAttrTest.new
        expect(test.r).to eq 1
      end

      it "The deprecated_attr_writer can be written to" do
        test = DeprecatedAttrTest.new
        test.w = 10
        expect(test.instance_eval { @w }).to eq 10
      end
    end
  end

end
