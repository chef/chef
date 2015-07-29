
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
    it "retrieves values set as strings using strings" do
      vivid['foo'] = 'bar'
      expect( vivid['foo'] ).to eql('bar')
      key_exists_as_string('foo')
    end

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

    it "retrieves values set as symbols using symbols" do
      vivid[:foo] = 'bar'
      expect( vivid[:foo] ).to eql('bar')
      key_exists_as_string('foo')
    end
  end

  context "autovivification" do
    it "should autovivify on access with symbols" do
      vivid[:foo][:bar][:baz]
      key_exists_as_string('foo')
      expect(vivid['foo']).to eql({'bar' => { 'baz' => {} } })
    end

    it "should autovivify on access with strings" do
      vivid['foo']['bar']['baz']
      key_exists_as_string('foo')
      expect(vivid['foo']).to eql({'bar' => { 'baz' => {} } })
    end

    it "should autovivify on access with methods" do
      vivid.foo.bar.baz
      key_exists_as_string('foo')
      expect(vivid['foo']).to eql({'bar' => { 'baz' => {} } })
    end

    it "should autovivify on setting with symbols" do
      vivid[:foo][:bar][:baz] = "qux"
      key_exists_as_string('foo')
      expect(vivid['foo']).to eql({'bar' => { 'baz' => 'qux' } })
    end

    it "should autovivify on setting with strings" do
      vivid['foo']['bar']['baz'] = "qux"
      key_exists_as_string('foo')
      expect(vivid['foo']).to eql({'bar' => { 'baz' => 'qux' } })
    end

    it "should autovivify on setting with methods" do
      vivid.foo.bar.baz = "qux"
      key_exists_as_string('foo')
      expect(vivid['foo']).to eql({'bar' => { 'baz' => 'qux' } })
    end
  end

  context "#regular_reader" do
    it "works in simple case" do
      vivid['foo'] = 'bar'
      expect( vivid.regular_reader("foo") ).to eql("bar")
    end

    it "works for deep access" do
      vivid['foo']['bar']['baz'] = 'qux'
      expect( vivid.regular_reader('foo', 'bar', 'baz') ).to eql('qux')
    end

    it "does stringize" do
      vivid['foo'] = 'bar'
      expect( vivid.regular_reader(:foo) ).to eql('bar')
    end

    it "does not autovivify" do
      vivid.regular_reader("foo")
      expect(vivid.key?("foo")).to be false
    end

    it "does not autovivify on deep access" do
      expect { vivid.regular_reader("foo", "bar", "baz") }.to raise_error(NoMethodError)
      expect(vivid.key?("foo")).to be false
    end
  end

  context "#regular_writer" do
    it "works in simple case" do
      vivid.regular_writer('foo', 'bar')
      key_exists_as_string('foo')
      expect( vivid['foo'] ).to eql('bar')
    end

    it "works for setting deep values" do
      vivid['foo']['bar']['baz'] = 'wrong'
      vivid.regular_writer('foo', 'bar', 'baz', 'qux')
      expect( vivid['foo']['bar']['baz'] ).to eql('qux')
    end

    it "does stringize" do
      vivid.regular_writer(:foo, 'bar')
      key_exists_as_string('foo')
      expect( vivid['foo'] ).to eql('bar')
    end

    it "does not autovivify on deep access" do
      expect { vivid.regular_writer('foo', 'bar', 'baz', 'qux') }.to raise_error(NoMethodError)
      expect(vivid.key?("foo")).to be false
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

  context "new_decorator" do
    it "as a class method, retains the same object and does not mutate it" do
      hash = { :foo.freeze => 'bar'.freeze }.freeze
      vivid2 = Chef::Node::VividMash.new_decorator(wrapped_object: hash)
      expect(vivid2.wrapped_object).to equal(hash)
    end

    it "as an instance method, retains the same object and does not mutate it" do
      hash = { :foo.freeze => 'bar'.freeze }.freeze
      vivid2 = vivid.new_decorator(wrapped_object: hash)
      expect(vivid2.wrapped_object).to equal(hash)
    end
  end

  context "#each on Hash" do
    it "works" do
      vivid['foo'] = 'bar'
      vivid['baz'] = 'qux'
      seen = {}
      vivid.each { |key, value| seen[key] = value }
      expect(seen).to eql({ 'foo' => 'bar', 'baz' => 'qux' })
    end

    it "returns vividmashes, not hashes" do
      vivid['foo']['bar'] = 'baz'
      vivid.each { |key, value| expect(value).to be_a_kind_of(Chef::Node::VividMash) }
    end
  end

  context "#merge!" do
    it "works in the simple case" do
      vivid['foo'] = 'bar'
      vivid.merge!({ 'baz' => 'qux' })
      expect(vivid['foo']).to eql('bar')
      expect(vivid['baz']).to eql('qux')
    end

    it "stringifies symbols" do
      vivid[:foo] = 'bar'
      vivid.merge!({ baz: 'qux' })
      expect(vivid['foo']).to eql('bar')
      expect(vivid['baz']).to eql('qux')
    end
  end
end
