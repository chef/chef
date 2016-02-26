
require "spec_helper"
require "chef/node/cow_mash"

describe Chef::Node::COWMash do
  context "#keep_if" do
    it "behaves correctly" do
      hash = { "foo" => true, "bar" => false }
      cow = Chef::Node::COWMash.new(wrapped_object: hash)
      expect(hash).not_to receive(:keep_if)
      expect(cow.keep_if { |k, v| v }).to eql({ "foo" => true })
      expect(hash).to eql({ "foo" => true, "bar" => false })
      expect(cow).to eql({ "foo" => true })
    end

    it "returns the object it mutates" do
      pending "not yet fixed"
      hash = { "foo" => true, "bar" => false }
      cow = Chef::Node::COWMash.new(wrapped_object: hash)
      expect(cow.keep_if { |k, v| v }).to equal(cow)
    end
  end

  context "#[]=" do
    it "behaves correctly" do
      hash = { "foo" => true, "bar" => false }
      cow = Chef::Node::COWMash.new(wrapped_object: hash)
      expect(cow["baz"] = "qux").to eql("qux")
      expect(cow).to eql({ "foo" => true, "bar" => false, "baz" => "qux" })
      expect(hash).to eql({ "foo" => true, "bar" => false })
    end
  end

  context "Array#push" do
    it "behaves correctly when wrapping an array" do
      array = []
      cow = Chef::Node::COWMash.new(wrapped_object: array)
      expect(array).to_not receive(:push)
      cow.push("1.2.3")
      expect(array).to eql([])
      expect(cow).to eql([ "1.2.3" ])
    end
    it "behaves correctly when deeply accessing an array" do
      hash = { "array" => [] }
      cow = Chef::Node::COWMash.new(wrapped_object: hash)
      expect(hash["array"]).to_not receive(:push)
      cow["array"].push("1.2.3")
      expect(hash).to eql({ "array" => [] })
      expect(cow).to eql({ "array" => [ "1.2.3" ] })
    end
  end
end
