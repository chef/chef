#
# Copyright:: Copyright 2018, Chef Software, Inc.
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
require "tmpdir"

describe "edit property of the file resource" do
  let(:file_base) { "file_spec" }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:node) { Chef::Node.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:content) { nil }

  let(:path) { File.join(Dir.mktmpdir, "chef_file_edit_spec") }

  let(:r) { Chef::Resource::File.new(path, run_context) }

  context "#append_if_no_such_line" do
    it "creates a file and appends to the empty file" do
      r.edit do
        append_if_no_such_line "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(["appended\n"])
    end

    it "appends to a file that already exists" do
      FileUtils.touch(path)
      r.edit do
        append_if_no_such_line "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(["appended\n"])
    end

    it "appends to a file that already exists with stuff in it" do
      File.open(path, "a+") { |f| f.puts "stuff" }
      r.edit do
        append_if_no_such_line "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end

    it "appends to content in the resource" do
      r.edit do
        append_if_no_such_line "appended"
      end
      r.content "stuff\n"
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end

    it "appends to content in the resource on a new line" do
      r.edit do
        append_if_no_such_line "appended"
      end
      r.content "stuff"
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end
  end
end
