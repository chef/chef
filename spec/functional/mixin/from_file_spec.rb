#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Mixin::FromFile do
  REAL_DATA = File.join(CHEF_SPEC_DATA, "mixin", "real_data.rb")
  INVALID_DATA = File.join(CHEF_SPEC_DATA, "mixin", "invalid_data.rb")
  NO_DATA = File.join(CHEF_SPEC_DATA, "mixin", "non_existant_data.rb")
  DIRECTORY = File.expand_path("")

  class TestData
    include Chef::Mixin::FromFile

    def a(a = nil)
      @a = a if a
      @a
    end
  end

  class ClassTestData
    class << self
      include Chef::Mixin::FromFile

      def a(a = nil)
        @a = a if a
        @a
      end
    end
  end

  describe "from_file" do
    it "should load data" do
      datum = TestData.new
      datum.from_file(REAL_DATA)
      expect(datum.a).to eq(:foo)
    end

    it "should load class data" do
      datum = ClassTestData
      datum.class_from_file(REAL_DATA)
      expect(datum.a).to eq(:foo)
    end

    it "should set source_file" do
      datum = TestData.new
      datum.from_file(REAL_DATA)
      expect(datum.source_file).to eq(REAL_DATA)
    end

    it "should set class source_file" do
      datum = ClassTestData
      datum.class_from_file(REAL_DATA)
      expect(datum.source_file).to eq(REAL_DATA)
    end

    it "should fail on invalid data" do
      datum = TestData.new
      expect do
        datum.from_file(INVALID_DATA)
      end.to raise_error(NoMethodError)
    end

    it "should fail on nonexistant data" do
      datum = TestData.new
      expect { datum.from_file(NO_DATA) }.to raise_error(IOError)
    end

    it "should fail if it's a directory not a file" do
      datum = TestData.new
      expect { datum.from_file(DIRECTORY) }.to raise_error(IOError)
    end

    it "should fail class if it's a directory not a file" do
      datum = ClassTestData
      expect { datum.from_file(DIRECTORY) }.to raise_error(IOError)
    end
  end
end
