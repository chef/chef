
require "spec_helper"
require "chef/node/cow_mash"

describe Chef::Node::COWMash do
  context "#keep_if" do
    it "works" do
      hash = { "foo" => true, "bar" => false }
      cow = Chef::Node::COWMash.new(wrapped_object: hash)
      expect(cow.keep_if { |k, v| v }).to eql({ "foo" => true })
      expect(hash).to eql({ "foo" => true, "bar" => false })
    end
  end
end
