
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

  context "convert_value: false option in the constructor" do
    it "retains the same object and does not mutate it" do
      hash = { :foo.freeze => 'bar'.freeze }.freeze
      vivid2 = Chef::Node::VividMash.new(wrapped_object: hash, convert_value: false)
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

  context "path tracking" do
    it "is accessible through #__path" do
      expect(vivid['foo']['bar'].__path).to eql(['foo', 'bar'])
    end

    it "does not mutate the state of the top level" do
      expect(vivid['foo']['bar'].__path).to eql(['foo', 'bar'])
      expect(vivid['foo'].__path).to eql(['foo'])
    end

    it "converts symbols" do
      expect(vivid[:foo][:bar].__path).to eql(['foo', 'bar'])
    end

    it "works with arrays" do
      vivid[:foo] = [ { bar: 'baz' } ]
      expect(vivid[:foo][0].__path).to eql(['foo', 0])
    end

    it "works through arrays" do
      vivid[:foo] = [ { bar: { baz: 'qux' } } ]
      expect(vivid[:foo][0]['baz'].__path).to eql(['foo', 0, 'baz'])
    end
  end

  context "puts" do
    it "works on a Hash" do
      vivid['foo'] = 'bar'
      puts vivid
    end
  end

  context "#to_ary" do
    it "should not be implemented on a Hash" do
      vivid['foo'] = 'bar'
      expect { vivid.to_ary }.to raise_error(NoMethodError)
    end

    it "should not respond_to? :to_ary for a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.respond_to?(:to_ary)).to be false
    end

    it "should be implemented on an Array" do
      vivid['foo'] = [0,1]
      expect(vivid['foo'].to_ary).to eql([0,1])
    end

    it "should respond_to? :to_ary for an Array " do
      vivid['foo'] = [0,1]
      expect(vivid['foo'].respond_to?(:to_ary)).to be true
    end
  end

  context "#to_a" do
    it "should be implemented on a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.to_a).to eql([["foo", "bar"]])
    end

    it "should respond_to? :to_a for a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.respond_to?(:to_a)).to be true
    end

    it "should be implemented on a Array" do
      vivid['foo'] = [0,1]
      expect(vivid['foo'].to_a).to eql([0,1])
    end

    it "should respond_to? :to_a for a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.respond_to?(:to_a)).to be true
    end
  end

  context "#to_hash" do
    it "should be implemented on a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.to_hash).to eql({'foo' => 'bar'})
    end

    it "should respond_to? :to_hash for a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.respond_to?(:to_hash)).to be true
    end

    it "should not be implemented on an Array" do
      vivid['foo'] = [[0,1]]
      expect { vivid['foo'].to_hash }.to raise_error(NoMethodError)
    end

    it "should not respond_to? :to_hash for an Array " do
      vivid['foo'] = [[0,1]]
      expect(vivid['foo'].respond_to?(:to_hash)).to be false
    end
  end

  context "#to_h" do
    it "should be implemented on a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.to_h).to eql({'foo' => 'bar'})
    end

    it "should respond_to? :to_h for a Hash" do
      vivid['foo'] = 'bar'
      expect(vivid.respond_to?(:to_h)).to be true
    end

    it "should be implemented on an Array" do
      vivid['foo'] = [[0,1]]
      expect(vivid['foo'].to_h).to eql({0=>1})
    end

    it "should respond_to? :to_h for an Array" do
      vivid['foo'] = [[0,1]]
      expect(vivid.respond_to?(:to_h)).to be true
    end
  end

  context "#delete" do
    it "should delete hash keys" do
      vivid['foo'] = 'bar'
      expect(vivid.delete('foo')).to eql('bar')
      expect(vivid).to eql({})
    end

    it "should delete with symbols converted to strings" do
      vivid['foo'] = 'bar'
      expect(vivid.delete(:foo)).to eql('bar')
      expect(vivid).to eql({})
    end

    it "should delete hash keys set to nil" do
      vivid['foo'] = nil
      expect(vivid.delete('foo')).to eql(nil)
      expect(vivid).to eql({})
    end

    it "should delete hash keys set to nil with symbols converted to strings" do
      vivid['foo'] = nil
      expect(vivid.delete(:foo)).to eql(nil)
      expect(vivid).to eql({})
    end
  end
end
