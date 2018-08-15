#
# Copyright:: Copyright 2011-2017, Chef Software Inc.
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
  include Chef::Mixin::Which
end

describe Chef::Mixin::Which do

  let(:test) { TestClass.new }

  describe "#which" do
    def self.test_which(description, *args, finds: nil, others: [], directory: false, &block)
      it description do
        # stub the ENV['PATH']
        expect(test).to receive(:env_path).and_return(["/dir1", "/dir2" ].join(File::PATH_SEPARATOR))

        # most files should not be found
        allow(File).to receive(:executable?).and_return(false)
        allow(File).to receive(:directory?).and_return(false)

        # stub the expectation
        expect(File).to receive(:executable?).with(finds).and_return(true) if finds

        # if the file we find is a directory
        expect(File).to receive(:directory?).with(finds).and_return(true) if finds && directory

        # allow for stubbing other paths to exist that we should not find
        others.each do |other|
          allow(File).to receive(:executable?).with(other).and_return(true)
        end

        # setup the actual expectation on the return value
        if finds && !directory
          expect(test.which(*args, &block)).to eql(finds)
        else
          expect(test.which(*args, &block)).to eql(false)
        end
      end
    end

    context "simple usage" do
      test_which("returns false when it does not find anything", "foo1")

      ["/dir1", "/dir2", "/bin", "/usr/bin", "/sbin", "/usr/sbin" ].each do |dir|
        test_which("finds `foo1` in #{dir} when it is stubbed", "foo1", finds: "#{dir}/foo1")
      end

      test_which("does not find an executable directory", "foo1", finds: "/dir1/foo1", directory: true)
    end

    context "with an array of args" do
      test_which("finds the first arg", "foo1", "foo2", finds: "/dir2/foo1")

      test_which("finds the second arg", "foo1", "foo2", finds: "/dir2/foo2")

      test_which("finds the first arg when there's both", "foo1", "foo2", finds: "/dir2/foo1", others: [ "/dir1/foo2" ])

      test_which("and the directory order can be reversed", "foo1", "foo2", finds: "/dir1/foo1", others: [ "/dir2/foo2" ])

      test_which("or be the same", "foo1", "foo2", finds: "/dir1/foo1", others: [ "/dir1/foo2" ])
    end

    context "with a block" do
      test_which("doesnt find it if its false", "foo1", others: [ "/dir1/foo1" ]) do |f|
        false
      end

      test_which("finds it if its true", "foo1", finds: "/dir1/foo1") do |f|
        true
      end

      test_which("passes in the filename as the arg", "foo1", finds: "/dir1/foo1") do |f|
        raise "bad arg to block" unless f == "/dir1/foo1"
        true
      end

      test_which("arrays with blocks", "foo1", "foo2", finds: "/dir2/foo1", others: [ "/dir1/foo2" ]) do |f|
        raise "bad arg to block" unless f == "/dir2/foo1" || f == "/dir1/foo2"
        true
      end
    end
  end

  describe "#where" do
    def self.test_where(description, *args, finds: [], others: [], &block)
      it description do
        # stub the ENV['PATH']
        expect(test).to receive(:env_path).and_return(["/dir1", "/dir2" ].join(File::PATH_SEPARATOR))

        # most files should not be found
        allow(File).to receive(:executable?).and_return(false)
        allow(File).to receive(:directory?).and_return(false)

        # allow for stubbing other paths to exist that we should not return
        others.each do |other|
          allow(File).to receive(:executable?).with(other).and_return(true)
        end

        # stub the expectation
        finds.each do |path|
          expect(File).to receive(:executable?).with(path).and_return(true)
        end

        # setup the actual expectation on the return value
        expect(test.where(*args, &block)).to eql(finds)
      end
    end

    context "simple usage" do
      test_where("returns empty array when it doesn't find anything", "foo1")

      ["/dir1", "/dir2", "/bin", "/usr/bin", "/sbin", "/usr/sbin" ].each do |dir|
        test_where("finds `foo1` in #{dir} when it is stubbed", "foo1", finds: [ "#{dir}/foo1" ])
      end

      test_where("finds `foo1` in all directories", "foo1", finds: [ "/dir1/foo1", "/dir2/foo1" ])
    end

    context "with an array of args" do
      test_where("finds the first arg", "foo1", "foo2", finds: [ "/dir2/foo1" ])

      test_where("finds the second arg", "foo1", "foo2", finds: [ "/dir2/foo2" ])

      test_where("finds foo1 before foo2", "foo1", "foo2", finds: [ "/dir2/foo1", "/dir1/foo2" ])

      test_where("finds foo1 before foo2 if the dirs are reversed", "foo1", "foo2", finds: [ "/dir1/foo1", "/dir2/foo2" ])

      test_where("finds them both in the same directory", "foo1", "foo2", finds: [ "/dir1/foo1", "/dir1/foo2" ])

      test_where("finds foo2 first if they're reversed", "foo2", "foo1", finds: [ "/dir1/foo2", "/dir1/foo1" ])
    end

    context "with a block do" do
      test_where("finds foo1 and foo2 if they exist and the block is true", "foo1", "foo2", finds: [ "/dir1/foo2", "/dir2/foo2" ]) do
        true
      end

      test_where("does not finds foo1 and foo2 if they exist and the block is false", "foo1", "foo2", others: [ "/dir1/foo2", "/dir2/foo2" ]) do
        false
      end
    end
  end
end
