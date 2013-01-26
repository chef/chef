#
# Author:: Adam Edwards (<adamed@opscode.com>)
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
require 'chef/mixin/windows_architecture_helper'



describe Chef::Mixin::WindowsArchitectureHelper do
  include Chef::Mixin::WindowsArchitectureHelper

  before do
    @valid_architectures = [ :i386, :x86_64 ]
    @invalid_architectures = [ "i386", "x86_64", :x64, :x86, :arm ]

    @node_i386 = Chef::Node.new
    @node_x86_64 = Chef::Node.new
  end
  
  it "returns true when valid architectures are passed to valid_windows_architecture?" do
    @valid_architectures.each do | architecture |
      valid_windows_architecture?(architecture).should == true
    end
  end

  it "returns false when invalid architectures are passed to valid_windows_architecture?" do
    @invalid_architectures.each do | architecture |
      valid_windows_architecture?(architecture).should == false
    end
  end

  it "does not raise an exception when a valid architecture is passed to assert_valid_windows_architecture!" do
    @valid_architectures.each do | architecture |
      assert_valid_windows_architecture!(architecture)
    end
  end

  it "raises an error if an invalid architecture is passed to assert_valid_windows_architecture!" do
    @invalid_architectures.each do | architecture |
      begin
        assert_valid_windows_architecture!(architecture).should raise_error Chef::Exceptions::Win32ArchitectureIncorrect
      rescue Chef::Exceptions::Win32ArchitectureIncorrect
      end
    end
  end

  it "returns true for each supported desired architecture for all nodes with each valid architecture passed to node_supports_windows_architecture" do
    enumerate_architecture_node_combinations(true)
  end

  it "returns false for each unsupported desired architecture for all nodes with each valid architecture passed to node_supports_windows_architecture?" do
    enumerate_architecture_node_combinations(true)
  end
  
  def enumerate_architecture_node_combinations(only_valid_combinations)
    @valid_architectures.each do | node_architecture |
      new_node = Chef::Node.new
      new_node.default["kernel"] = Hash.new
      new_node.default["kernel"][:machine] = node_architecture.to_s

      @valid_architectures.each do | supported_architecture |
        node_supports_windows_architecture?(new_node, supported_architecture).should == true if only_valid_combinations && (supported_architecture != :x86_64 && node_architecture != :i386 )
        node_supports_windows_architecture?(new_node, supported_architecture).should == false if ! only_valid_combinations && (supported_architecture == :x86_64 && node_architecture == :i386 )        
      end
    end
  end
end
