#
# Copyright:: Copyright 2018-2018, Chef Software Inc.
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

  context "#empty!" do
    it "empties a file" do
      File.open(path, "a+") { |f| f.puts "stuff\nthings\notherstuff\n" }
      r.edit do
        empty!
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to be_empty
    end

    it "empties a file before an append" do
      File.open(path, "a+") { |f| f.puts "stuff\nthings\notherstuff\n" }
      r.edit do
        empty!
        append_lines "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{appended\n})
    end
  end

  context "#append_lines" do
    it "creates a file and appends to the empty file" do
      r.edit do
        append_lines "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(["appended\n"])
    end

    it "appends to a file that already exists" do
      FileUtils.touch(path)
      r.edit do
        append_lines "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(["appended\n"])
    end

    it "appends to a file that already exists with stuff in it" do
      File.open(path, "a+") { |f| f.puts "stuff" }
      r.edit do
        append_lines "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end

    it "appends to a file that already exists with stuff in it, where stuff does not have a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        append_lines "appended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end

    it "appends to content in the resource" do
      r.edit do
        append_lines "appended"
      end
      r.content "stuff\n"
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end

    it "appends to content in the resource on a new line" do
      r.edit do
        append_lines "appended"
      end
      r.content "stuff"
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end

    it "does not append multiple times" do
      r.edit do
        append_lines "appended"
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{appended\n})
    end

    it "when not appending, preserves files that do not end in a newline" do
      File.open(path, "a+") { |f| f.write "matching\nstuff" }
      r.edit do
        append_lines "matching"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{matching\n stuff})
    end

    it "when not appending, preserves files that do not end in a newline, when the matching pattern is the line without the newline" do
      File.open(path, "a+") { |f| f.write "matching\nstuff" }
      r.edit do
        append_lines "stuff"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{matching\n stuff})
    end

    it "does not append multiple times, where file does not already have a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        append_lines "appended"
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n appended\n})
    end

    it "appends with a multi line string" do
      r.edit do
        append_lines <<~EOF
          append1
          append2
        EOF
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{append1\n append2\n})
    end

    it "is idempotent with a multi line string" do
      r.edit do
        append_lines <<~EOF
          append1
          append2
        EOF
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{append1\n append2\n})
    end

    it "is idempotent with a multi line string, on a file that contains a line without a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        append_lines <<~EOF
          append1
          append2
        EOF
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n append1\n append2\n})
    end

    it "appends with a array of strings" do
      r.edit do
        append_lines %W{append1\n append2\n}
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{append1\n append2\n})
    end

    it "is idempotent with an array of strings" do
      r.edit do
        append_lines %W{append1\n append2\n}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{append1\n append2\n})
    end

    it "is idempotent with an array of strings, on a file that contains a line without a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        append_lines %W{append1\n append2\n}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n append1\n append2\n})
    end

    it "appends with a array of strings without newlines" do
      r.edit do
        append_lines %w{append1 append2}
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{append1\n append2\n})
    end

    it "is idempotent with an array of strings wihtout newlines" do
      r.edit do
        append_lines %w{append1 append2}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{append1\n append2\n})
    end

    it "is idempotent with an array of strings without newlines, on a file that contains a line without a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        append_lines %w{append1 append2}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{stuff\n append1\n append2\n})
    end

    it "hashes append lines that don't match, and doesn't update lines that do match" do
      File.open(path, "a+") { |f| f.write "FOO=noreplace1\nBAR=noreplace2" }
      r.edit do
        append_lines({
          "FOO=" => "FOO=shouldntreplace1",
          "BAR=appended1" => "BAR=appended1",
        })
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{FOO=noreplace1\n BAR=noreplace2\n BAR=appended1\n})
    end

    it "hashes append lines that don't match, and doesn't update lines that do match when using regexp keys" do
      File.open(path, "a+") { |f| f.write "FOO=noreplace1\nBAR=noreplace2" }
      r.edit do
        append_lines({
          /^.*FOO=/ => "FOO=shouldntreplace1",
          /^.*BAR=appended1/ => "BAR=appended1",
        })
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{FOO=noreplace1\n BAR=noreplace2\n BAR=appended1\n})
    end

    it "hashes append lines that don't match, and does update lines that do match, when replace is true" do
      File.open(path, "a+") { |f| f.write "FOO=replace\nBAR=noreplace2" }
      r.edit do
        append_lines({
          "FOO=" => "FOO=replaced",
          "BAR=appended1" => "BAR=appended1",
        }, replace: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{FOO=replaced\n BAR=noreplace2\n BAR=appended1\n})
    end

    it "hashes append lines that don't match, and does update lines that do match when using regexp keys, when replace is true" do
      File.open(path, "a+") { |f| f.write "FOO=replace\nBAR=noreplace2" }
      r.edit do
        append_lines({
          /^.*FOO=/ => "FOO=replaced",
          /^.*BAR=appended1/ => "BAR=appended1",
        }, replace: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{FOO=replaced\n BAR=noreplace2\n BAR=appended1\n})
    end

    it "hashes replace all the matching lines when replace is true" do
      # note that substrings match, and a regexp has to be used to anchor
      File.open(path, "a+") { |f| f.write "FOO=replace1\nBAR=noreplace2\nFIZZFOO=replace2" }
      r.edit do
        append_lines({
          "FOO=" => "FOO=replaced",
          "BAR=appended1" => "BAR=appended1",
        }, replace: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{FOO=replaced\n BAR=noreplace2\n FOO=replaced\n BAR=appended1\n})
    end

    it "hashes delete all matches except the last line which is replaced when replace is true and unique is true" do
      # note that substrings match, and a regexp has to be used to anchor
      File.open(path, "a+") { |f| f.write "FOO=replace1\nBAR=noreplace2\nFIZZFOO=replace2" }
      r.edit do
        append_lines({
          "FOO=" => "FOO=replaced",
          "BAR=appended1" => "BAR=appended1",
        }, replace: true, unique: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{BAR=noreplace2\n FOO=replaced\n BAR=appended1\n})
    end
  end

  context "#prepend_lines" do
    it "creates a file and prepends to the empty file" do
      r.edit do
        prepend_lines "prepended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(["prepended\n"])
    end

    it "prepends to a file that already exists" do
      FileUtils.touch(path)
      r.edit do
        prepend_lines "prepended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(["prepended\n"])
    end

    it "prepends to a file that already exists with stuff in it" do
      File.open(path, "a+") { |f| f.puts "stuff" }
      r.edit do
        prepend_lines "prepended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepended\n stuff\n})
    end

    it "prepends to a file that already exists with stuff in it, where stuff does not have a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        prepend_lines "prepended"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepended\n stuff})
    end

    it "prepends to content in the resource" do
      r.edit do
        prepend_lines "prepended"
      end
      r.content "stuff\n"
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepended\n stuff\n})
    end

    it "prepends to content in the resource on a new line" do
      r.edit do
        prepend_lines "prepended"
      end
      r.content "stuff"
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepended\n stuff})
    end

    it "does not prepend multiple times" do
      r.edit do
        prepend_lines "prepended"
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepended\n})
    end

    it "does not prepend multiple times, where file does not already have a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        prepend_lines "prepended"
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepended\n stuff})
    end

    it "when not prepending, preserves files that do not end in a newline, when the matching pattern is the line without the newline" do
      File.open(path, "a+") { |f| f.write "matching\nstuff" }
      r.edit do
        prepend_lines "stuff"
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{matching\n stuff})
    end

    it "does not prepend multiple times, where file does not already have a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        prepend_lines "prepended"
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepended\n stuff})
    end

    it "prepends with a multi line string" do
      r.edit do
        prepend_lines <<~EOF
          prepend1
          prepend2
        EOF
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n})
    end

    it "is idempotent with a multi line string" do
      r.edit do
        prepend_lines <<~EOF
          prepend1
          prepend2
        EOF
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n})
    end

    it "is idempotent with a multi line string, on a file that contains a line without a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        prepend_lines <<~EOF
          prepend1
          prepend2
        EOF
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n stuff})
    end

    it "prepends with a array of strings" do
      r.edit do
        prepend_lines %W{prepend1\n prepend2\n}
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n})
    end

    it "is idempotent with an array of strings" do
      r.edit do
        prepend_lines %W{prepend1\n prepend2\n}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n})
    end

    it "is idempotent with an array of strings, on a file that contains a line without a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        prepend_lines %W{prepend1\n prepend2\n}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n stuff})
    end

    it "prepends with a array of strings without newlines" do
      r.edit do
        prepend_lines %w{prepend1 prepend2}
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n})
    end

    it "is idempotent with an array of strings wihtout newlines" do
      r.edit do
        prepend_lines %w{prepend1 prepend2}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n})
    end

    it "is idempotent with an array of strings without newlines, on a file that contains a line without a newline" do
      File.open(path, "a+") { |f| f.write "stuff" }
      r.edit do
        prepend_lines %w{prepend1 prepend2}
      end
      r.run_action(:create)
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{prepend1\n prepend2\n stuff})
    end

    it "hashes prepend lines that don't match, and doesn't update lines that do match" do
      File.open(path, "a+") { |f| f.write "FOO=noreplace1\nBAR=noreplace2" }
      r.edit do
        prepend_lines({
          "FOO=" => "FOO=shouldntreplace1",
          "BAR=prepended1" => "BAR=prepended1",
        })
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{BAR=prepended1\n FOO=noreplace1\n BAR=noreplace2})
    end

    it "hashes prepend lines that don't match, and doesn't update lines that do match when using regexp keys" do
      File.open(path, "a+") { |f| f.write "FOO=noreplace1\nBAR=noreplace2" }
      r.edit do
        prepend_lines({
          /^.*FOO=/ => "FOO=shouldntreplace1",
          /^.*BAR=prepended1/ => "BAR=prepended1",
        })
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{BAR=prepended1\n FOO=noreplace1\n BAR=noreplace2})
    end

    it "hashes prepend lines that don't match, and does update lines that do match, when replace is true" do
      File.open(path, "a+") { |f| f.write "FOO=replace\nBAR=noreplace2" }
      r.edit do
        prepend_lines({
          "FOO=" => "FOO=replaced",
          "BAR=prepended1" => "BAR=prepended1",
        }, replace: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{BAR=prepended1\n FOO=replaced\n BAR=noreplace2})
    end

    it "hashes prepend lines that don't match, and does update lines that do match when using regexp keys, when replace is true" do
      File.open(path, "a+") { |f| f.write "FOO=replace\nBAR=noreplace2" }
      r.edit do
        prepend_lines({
          /^.*FOO=/ => "FOO=replaced",
          /^.*BAR=prepended1/ => "BAR=prepended1",
        }, replace: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{BAR=prepended1\n FOO=replaced\n BAR=noreplace2})
    end

    it "hashes replace all the matching lines when replace is true" do
      # note that substrings match, and a regexp has to be used to anchor
      File.open(path, "a+") { |f| f.write "FOO=replace1\nBAR=noreplace2\nFIZZFOO=replace2" }
      r.edit do
        prepend_lines({
          "FOO=" => "FOO=replaced",
          "BAR=prepended1" => "BAR=prepended1",
        }, replace: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{BAR=prepended1\n FOO=replaced\n BAR=noreplace2\n FOO=replaced\n})
    end

    it "hashes delete all matches except the first line which is replaced when replace is true and unique is true" do
      # note that substrings match, and a regexp has to be used to anchor
      File.open(path, "a+") { |f| f.write "FOO=replace1\nBAR=noreplace2\nFIZZFOO=replace2" }
      r.edit do
        prepend_lines({
          "FOO=" => "FOO=replaced",
          "BAR=prepended1" => "BAR=prepended1",
        }, replace: true, unique: true)
      end
      r.run_action(:create)
      expect(IO.read(path).lines).to eql(%W{BAR=prepended1\n FOO=replaced\n BAR=noreplace2\n})
    end

  end
end
