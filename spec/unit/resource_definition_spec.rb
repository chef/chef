#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::ResourceDefinition do
  let(:defn) { Chef::ResourceDefinition.new() }

  describe "initialize" do
    it "should be a Chef::ResourceDefinition" do
      expect(defn).to be_a_kind_of(Chef::ResourceDefinition)
    end

    it "should not initialize a new node if one is not provided" do
      expect(defn.node).to eql(nil)
    end

    it "should accept a node as an argument" do
      node = Chef::Node.new
      node.name("bobo")
      defn = Chef::ResourceDefinition.new(node)
      expect(defn.node.name).to eq("bobo")
    end
  end

  describe "node" do
    it "should set the node with node=" do
      node = Chef::Node.new
      node.name("bobo")
      defn.node = node
      expect(defn.node.name).to eq("bobo")
    end

    it "should return the node" do
      defn.node = Chef::Node.new
      expect(defn.node).to be_a_kind_of(Chef::Node)
    end
  end

  it "should accept a new definition with a symbol for a name" do
    expect do
      defn.define :smoke do
      end
    end.not_to raise_error
    expect do
      defn.define "george washington" do
      end
    end.to raise_error(ArgumentError)
    expect(defn.name).to eql(:smoke)
  end

  it "should accept a new definition with a hash" do
    expect do
      defn.define :smoke, :cigar => "cuban", :cigarette => "marlboro" do
      end
    end.not_to raise_error
  end

  it "should expose the prototype hash params in the params hash" do
    defn.define(:smoke, :cigar => "cuban", :cigarette => "marlboro") {}
    expect(defn.params[:cigar]).to eql("cuban")
    expect(defn.params[:cigarette]).to eql("marlboro")
  end

  it "should store the block passed to define as a proc under recipe" do
    defn.define :smoke do
      "I am what I am"
    end
    expect(defn.recipe).to be_a_kind_of(Proc)
    expect(defn.recipe.call).to eql("I am what I am")
  end

  it "should set parameters based on method_missing" do
    defn.mind "to fly"
    expect(defn.params[:mind]).to eql("to fly")
  end

  it "should raise an exception if prototype_params is not a hash" do
    expect do
      defn.define :monkey, Array.new do
      end
    end.to raise_error(ArgumentError)
  end

  it "should raise an exception if define is called without a block" do
    expect do
      defn.define :monkey
    end.to raise_error(ArgumentError)
  end

  it "should load a description from a file" do
    defn.from_file(File.join(CHEF_SPEC_DATA, "definitions", "test.rb"))
    expect(defn.name).to eql(:rico_suave)
    expect(defn.params[:rich]).to eql("smooth")
  end

  it "should turn itself into a string based on the name with to_s" do
    defn.name = :woot
    expect(defn.to_s).to eql("woot")
  end

end
