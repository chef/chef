
require 'spec_helper'

describe Chef::Node::AttributeTrait::Decorator do
  class Test
    include Chef::Node::AttributeTrait::Decorator
  end

  let(:test) { Test[] }

  context "#to_hash" do
    it "return a real hash" do
      test['foo'] = 'bar'
      expect(test.to_hash).to be_instance_of(Hash)
    end
  end

  context "#each" do
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

  context "Array#map" do
    it "yields decorated objects when nested" do
      test['array'] =  [ { a: 'a' }, { b: 'b' } ]
      map = test['array'].map { |e| expect(e).to be_instance_of(Test) }
      expect(map[0]).to be_instance_of(Test)
    end

    it "yields undecorated objects when not nested" do
      test['array'] =  [ 1, true, "string" ]
      map = test['array'].map { |e| expect(e).not_to be_instance_of(Test) }
      expect(map[0]).not_to be_instance_of(Test)
    end
  end
end
