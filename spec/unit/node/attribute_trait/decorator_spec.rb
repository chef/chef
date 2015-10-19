
require 'spec_helper'

describe Chef::Node::AttributeTrait::Decorator do
  class Test
    include Chef::Node::AttributeTrait::Decorator
  end

  context "as a Hash" do
    let(:test) { Test[] }

    context "Hash#any" do
      it "yields decorated objects when nested" do
        test['foo'] = { 'bar' => 'baz' }
        test['bar'] = [ 1, 2 ]
        test.any? { |k, v| expect(v).to be_instance_of(Test) }
      end

      it "yields undecorated objects when not nested" do
        test['foo'] = 1
        test['bar'] = "string"
        test.any? { |k, v| expect(v).not_to be_instance_of(Test) }
      end
    end

    context "Hash#assoc" do
      it "returns decorated objects when nested" do
        test['foo'] = { 'bar' => 'baz' }
        test['bar'] = [ 1, 2 ]
        expect(test.assoc('foo')).to be_instance_of(Test)
        expect(test.assoc('bar')).to be_instance_of(Test)
      end

      it "yields undecorated objects when not nested" do
        test['foo'] = 1
        test['bar'] = "string"
        expect(test.assoc('foo')).not_to be_instance_of(Test)
        expect(test.assoc('bar')).not_to be_instance_of(Test)
      end
    end

    context "Hash#delete_if" do
      it "returns decorated objects when nested" do
        test['foo'] = { 'bar' => 'baz' }
        test['bar'] = [ 1, 2 ]
        expect(test.delete('foo')).to be_instance_of(Test)
        expect(test.delete('bar')).to be_instance_of(Test)
      end

      it "yields undecorated objects when not nested" do
        test['foo'] = 1
        test['bar'] = "string"
        expect(test.delete('foo')).not_to be_instance_of(Test)
        expect(test.delete('bar')).not_to be_instance_of(Test)
      end
    end

    context "Hash#to_hash" do
      it "return a real hash" do
        test['foo'] = 'bar'
        expect(test.to_hash).to be_instance_of(Hash)
      end
    end

    context "Hash#each" do
      it "yields decorated objects when nested" do
        test['foo'] = { 'bar' => 'baz' }
        test['bar'] = [ 1, 2 ]
        test.each { |k, v| expect(v).to be_instance_of(Test) }
      end

      it "yields undecorated objects when not nested" do
        test['foo'] = 1
        test['bar'] = "string"
        test.each { |k, v| expect(v).not_to be_instance_of(Test) }
      end
    end
  end

  context "as an Array" do
    let(:test) { t = Test.new; t.wrapped_object = []; t }

    context "Array#any" do
      it "yields decorated objects when nested" do
        test.wrapped_object =  [ { a: 'a' }, { b: 'b' } ]
        test.any? { |e| expect(e).to be_instance_of(Test) }
      end

      it "yields undecorated objects when not nested" do
        test.wrapped_object =  [ 1, true, "string" ]
        test.any? { |e| expect(e).not_to be_instance_of(Test) }
      end
    end

    context "Array#map" do
      it "yields decorated objects when nested" do
        test.wrapped_object =  [ { a: 'a' }, { b: 'b' } ]
        map = test.map { |e| expect(e).to be_instance_of(Test); e }
        expect(map[0]).to be_instance_of(Test)
        expect(map[0]).to eql({ a: 'a' })
      end

      it "yields undecorated objects when not nested" do
        test.wrapped_object =  [ 1, true, "string" ]
        map = test.map { |e| expect(e).not_to be_instance_of(Test); e }
        expect(map[0]).not_to be_instance_of(Test)
        expect(map[0]).to eql(1)
      end
    end
  end
end
