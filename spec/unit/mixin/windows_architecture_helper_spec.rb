#
# Author:: Adam Edwards (<adamed@chef.io>)
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
require "chef/mixin/windows_architecture_helper"

describe Chef::Mixin::WindowsArchitectureHelper do
  include Chef::Mixin::WindowsArchitectureHelper

  before do
    @valid_architectures = [ :i386, :x86_64 ]
    @invalid_architectures = [ "i386", "x86_64", :x64, :x86, :arm ]

    @node_i386 = Chef::Node.new
    @node_x86_64 = Chef::Node.new
  end

  it "returns true when valid architectures are passed to valid_windows_architecture?" do
    @valid_architectures.each do |architecture|
      expect(valid_windows_architecture?(architecture)).to eq(true)
    end
  end

  it "returns false when invalid architectures are passed to valid_windows_architecture?" do
    @invalid_architectures.each do |architecture|
      expect(valid_windows_architecture?(architecture)).to eq(false)
    end
  end

  it "does not raise an exception when a valid architecture is passed to assert_valid_windows_architecture!" do
    @valid_architectures.each do |architecture|
      assert_valid_windows_architecture!(architecture)
    end
  end

  it "raises an error if an invalid architecture is passed to assert_valid_windows_architecture!" do
    @invalid_architectures.each do |architecture|
      begin
        expect(assert_valid_windows_architecture!(architecture)).to raise_error Chef::Exceptions::Win32ArchitectureIncorrect
      rescue Chef::Exceptions::Win32ArchitectureIncorrect
      end
    end
  end

  it "returns true only for supported desired architecture passed to node_supports_windows_architecture" do
    with_node_architecture_combinations do |node, desired_arch|
      expect(node_supports_windows_architecture?(node, desired_arch)).to be true if node_windows_architecture(node) == :x86_64 || desired_arch == :i386
      expect(node_supports_windows_architecture?(node, desired_arch)).to be false if node_windows_architecture(node) == :i386 && desired_arch == :x86_64
    end
  end

  it "returns true only when forced_32bit_override_required? has 64-bit node architecture and 32-bit desired architecture" do
    with_node_architecture_combinations do |node, desired_arch|
      expect(forced_32bit_override_required?(node, desired_arch)).to be true if (node_windows_architecture(node) == :x86_64) && (desired_arch == :i386) && !is_i386_process_on_x86_64_windows?
      expect(forced_32bit_override_required?(node, desired_arch)).to be false if ! ((node_windows_architecture(node) == :x86_64) && (desired_arch == :i386))
    end
  end

  def with_node_architecture_combinations
    @valid_architectures.each do |node_architecture|
      new_node = Chef::Node.new
      new_node.default["kernel"] = Hash.new
      new_node.default["kernel"][:machine] = node_architecture.to_s

      @valid_architectures.each do |architecture|
        yield new_node, architecture if block_given?
      end
    end
  end
end
