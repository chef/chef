#
# Copyright:: Copyright (c) Chef Software Inc.
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

class TestClass
  include Chef::Mixin::CreatePath
end

describe Chef::Mixin::CreatePath do

  let(:test) { TestClass.new }

  describe "#create_path" do
    it "creates directories if path entirely missing" do
      expect(File).to receive(:directory?).with("/foo").and_return(false)
      expect(test).to receive(:create_dir).with("/foo").and_return(true)
      expect(File).to receive(:directory?).with("/foo/bar").and_return(false)
      expect(test).to receive(:create_dir).with("/foo/bar").and_return(true)
      expect(File).to receive(:directory?).with("/foo/bar/baz").and_return(false)
      expect(test).to receive(:create_dir).with("/foo/bar/baz").and_return(true)

      path = "/foo/bar/baz"
      expect(test.create_path(path)).to eql(path)
    end
    it "creates directories if some are missing" do
      expect(File).to receive(:directory?).with("/foo").and_return(true)
      expect(File).to receive(:directory?).with("/foo/bar").and_return(false)
      expect(test).to receive(:create_dir).with("/foo/bar").and_return(true)
      expect(File).to receive(:directory?).with("/foo/bar/baz").and_return(false)
      expect(test).to receive(:create_dir).with("/foo/bar/baz").and_return(true)

      path = "/foo/bar/baz"
      expect(test.create_path(path)).to eql(path)
    end
    it "doesn't call create_dir if path already exists" do
      expect(File).to receive(:directory?).with("/foo/bar/baz").and_return(true)
      expect(test).to_not receive(:create_dir)

      path = "/foo/bar/baz"
      expect(test.create_path(path)).to eql(path)
    end
  end
end
