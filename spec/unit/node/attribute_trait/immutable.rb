
require 'spec_helper'
require 'bigdecimal'

describe Chef::Node::AttributeTrait::Immutable do
  class Test
    include Chef::Node::AttributeTrait::Decorator
    include Chef::Node::AttributeTrait::Immutable
  end

  let(:test) { t = Test.new }

  context "#dup" do
    it "deep dup's correctly to a mutable Array from an Array" do
      test.wrapped_object = [1,[2,3]]
      dup = test.dup
      expect(dup).to eql([1,[2,3]])
      expect(dup).to be_instance_of(Array)
      expect(dup[1]).to be_instance_of(Array)
      dup[1][2] = 4
      expect(dup).to eql([1,[2,3,4]])
      expect(test).to eql([1,[2,3]])
    end

    it "deep dup's correctly to a mutable Hash from a Hash" do
      test.wrapped_object = { a: { b: 'b' } }
      dup = test.dup
      expect(dup).to eql({ a: { b: 'b' } })
      expect(dup).to be_instance_of(Hash)
      expect(dup[:a]).to be_instance_of(Hash)
      dup[:a][:c] = 'c'
      expect(dup).to eql({ a: { b: 'b', c: 'c' } })
      expect(test).to eql({ a: { b: 'b' } })
    end

    it "handles undupable values without an Exception" do
      test.wrapped_object = {
        nil: nil,
        false: 'false',
        true: 'true',
        fixnum: '1',
        float: '1.1',
        symbol: :foo,
        method: method(:puts),
        big_decimal: BigDecimal.new("1.2"),
      }
      test.dup
    end
  end

  context "#to_hash" do
    context "when the wrapped_object is an Array" do
      before { test.wrapped_object =  [ 1, 2 ] }

      it "throws NoMethodError" do
        expect { test.to_hash }.to raise_error(NoMethodError)
      end

      it "does not respond_to #to_hash" do
        expect(test.respond_to?(:to_hash)).to be false
      end

      it "INCORRECTLY responds to #method" do
        # this isn't fixable since we don't use method_missing
        expect(test.method(:to_hash)).to be_kind_of(Method)
      end
    end

    context "when the wrapped_object is a Hash" do
      before { test.wrapped_object = { a: 'a' } }

      it "will respond_to #to_hash" do
        expect(test.respond_to?(:to_hash)).to be true
      end

      it "responds to #method" do
        expect(test.method(:to_hash)).to be_kind_of(Method)
      end

      it "converts to a bare object" do
        expect(test.to_hash).to be_instance_of(Hash)
      end
    end
  end

  context "#to_ary" do
    context "when the wrapped_object is a Hash" do
      before { test.wrapped_object = { a: 'a' } }

      it "throws NoMethodError" do
        expect { test.to_ary }.to raise_error(NoMethodError)
      end

      it "does not respond_to #to_ary" do
        expect(test.respond_to?(:to_ary)).to be false
      end

      it "INCORRECTLY responds to #method" do
        # this isn't fixable since we don't use method_missing
        expect(test.method(:to_ary)).to be_kind_of(Method)
      end
    end

    context "when the wrapped_object is an Array" do
      before { test.wrapped_object =  [ 1, 2 ] }

      it "will respond_to #to_ary" do
        expect(test.respond_to?(:to_ary)).to be true
      end

      it "responds to #method" do
        expect(test.method(:to_ary)).to be_kind_of(Method)
      end

      it "converts to a bare object" do
        expect(test.to_ary).to be_instance_of(Array)
      end
    end
  end

  context "mutator methods raise immutable errors" do
    context "as a Hash" do
      before { test.wrapped_object = {} }

      Test::MUTATOR_METHODS.each do |method|
        it "raises ImmutableAttributeModification on #{method}" do
          expect { test.public_send(method) }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
        end
        it "respond_to?(:#{method}) is true" do
          expect(test.respond_to?(method)).to be true
        end
        it "returns a method(:#{method})" do
          expect(test.method(method)).to be_instance_of(Method)
        end
      end
    end

    context "as an Array" do
      before { test.wrapped_object = [] }

      Test::MUTATOR_METHODS.each do |method|
        it "raises ImmutableAttributeModification on #{method}" do
          expect { test.public_send(method) }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
        end
        it "respond_to?(:#{method}) is true" do
          expect(test.respond_to?(method)).to be true
        end
        it "returns a method(:#{method})" do
          expect(test.method(method)).to be_instance_of(Method)
        end
      end
    end
  end
end
