
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
end
