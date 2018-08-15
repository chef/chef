#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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

def impersonates_a(klass)
  it "#is_a?(#{klass}) is true" do
    expect(decorator.is_a?(klass)).to be true
  end

  it "#is_a?(Chef::Decorator) is true" do
    expect(decorator.is_a?(Chef::Decorator)).to be true
  end

  it "#kind_of?(#{klass}) is true" do
    expect(decorator.kind_of?(klass)).to be true
  end

  it "#kind_of?(Chef::Decorator) is true" do
    expect(decorator.kind_of?(Chef::Decorator)).to be true
  end

  it "#instance_of?(#{klass}) is false" do
    expect(decorator.instance_of?(klass)).to be false
  end

  it "#instance_of?(Chef::Decorator) is true" do
    expect(decorator.instance_of?(Chef::Decorator)).to be true
  end

  it "#class is Chef::Decorator" do
    expect(decorator.class).to eql(Chef::Decorator)
  end
end

describe Chef::Decorator do
  let(:obj) {}
  let(:decorator) { Chef::Decorator.new(obj) }

  context "when the obj is a string" do
    let(:obj) { "STRING" }

    impersonates_a(String)

    it "#nil? is false" do
      expect(decorator.nil?).to be false
    end

    it "!! is true" do
      expect(!!decorator).to be true
    end

    it "dup returns a decorator" do
      expect(decorator.dup.class).to be Chef::Decorator
    end

    it "dup dup's the underlying thing" do
      expect(decorator.dup.__getobj__).not_to equal(decorator.__getobj__)
    end
  end

  context "when the obj is a nil" do
    let(:obj) { nil }

    it "#nil? is true" do
      expect(decorator.nil?).to be true
    end

    it "!! is false" do
      expect(!!decorator).to be false
    end

    impersonates_a(NilClass)
  end

  context "when the obj is an empty Hash" do
    let(:obj) { {} }

    impersonates_a(Hash)

    it "formats it correctly through ffi-yajl and not the JSON gem" do
      # this relies on a quirk of pretty formatting whitespace between yajl and ruby's JSON
      expect(FFI_Yajl::Encoder.encode(decorator, pretty: true)).to eql("{\n\n}\n")
    end
  end

  context "whent he obj is a Hash with elements" do
    let(:obj) { { foo: "bar", baz: "qux" } }

    impersonates_a(Hash)

    it "dup is shallow on the Hash" do
      expect(decorator.dup[:baz]).to equal(decorator[:baz])
    end

    it "deep mutating the dup'd hash mutates the origin" do
      decorator.dup[:baz] << "qux"
      expect(decorator[:baz]).to eql("quxqux")
    end
  end

  context "memoizing methods" do
    let(:obj) { {} }

    it "calls method_missing only once" do
      expect(decorator).to receive(:method_missing).once.and_call_original
      expect(decorator.keys).to eql([])
      expect(decorator.keys).to eql([])
    end

    it "switching a Hash to an Array responds to keys then does not" do
      expect(decorator.respond_to?(:keys)).to be true
      expect(decorator.keys).to eql([])
      decorator.__setobj__([])
      expect(decorator.respond_to?(:keys)).to be false
      expect { decorator.keys }.to raise_error(NoMethodError)
    end

    it "memoization of methods happens on the instances, not the classes" do
      decorator2 = Chef::Decorator.new([])
      expect(decorator.respond_to?(:keys)).to be true
      expect(decorator.keys).to eql([])
      expect(decorator2.respond_to?(:keys)).to be false
      expect { decorator2.keys }.to raise_error(NoMethodError)
    end
  end
end
