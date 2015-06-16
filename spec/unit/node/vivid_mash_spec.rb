
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

    it "should deeply autovivify correctly" do
      vivid['foo'][:bar]['baz'] = true
      expect(vivid['foo']).to eql({'bar' => { 'baz' => true } })
    end
  end

  context "deep conversion of symbols to strings" do
    context "in the constructor" do
      let(:vivid) { Chef::Node::VividMash.new(wrapped_object: { foo: { bar: { baz: "qux" } } } ) }

      it "should convert deeply nested symbols" do
        expect(vivid.wrapped_object[:foo]).to be nil
        expect(vivid.wrapped_object['foo'][:bar]).to be nil
        expect(vivid.wrapped_object['foo']['bar'][:baz]).to be nil
        expect(vivid.wrapped_object['foo']['bar']['baz']).to eql('qux')
        expect(vivid.wrapped_object).to eql({ 'foo' => { 'bar' => { 'baz' => 'qux' } } } )
      end
    end
  end
end
