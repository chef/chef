
require 'spec_helper'

describe Chef::Node::VividMash do
  let(:vivid) { Chef::Node::VividMash.new }

  def key_exists_as_string(key)
    expect(vivid.wrapped_object.key?(key.to_s)).to be true
    expect(vivid.wrapped_object.key?(key.to_sym)).to be false
    expect(vivid.key?(key.to_s)).to be true
    expect(vivid.key?(key.to_sym)).to be true
  end

  context "stringification" do
    it "retrieves values set as symbols using strings" do
      vivid[:foo] = 'bar'
      expect( vivid['foo'] ).to eql('bar')
      key_exists_as_string('foo')
    end

    it "retrieves values set as strings using symbols" do
      vivid['foo'] = 'bar'
      expect( vivid[:foo] ).to eql('bar')
      key_exists_as_string('foo')
    end
  end

  context "autovivification" do
    it "should autovivify symbols" do
      vivid[:foo]
      key_exists_as_string('foo')
    end

    it "should autovivify strings" do
      vivid['foo']
      key_exists_as_string('foo')
    end
  end
end
