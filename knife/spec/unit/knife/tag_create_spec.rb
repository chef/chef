require "knife_spec_helper"

describe Chef::Knife::TagCreate do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::TagCreate.new
    @knife.name_args = [ Chef::Config[:node_name], "happytag" ]

    @node = Chef::Node.new
    allow(@node).to receive :save
    allow(Chef::Node).to receive(:load).and_return @node
    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
  end

  describe "run" do
    it "can create tags on a node" do
      @knife.run
      expect(@node.tags).to eq(["happytag"])
      expect(@stderr.string).to match(/created tags happytag.+node webmonkey.example.com/i)
    end
  end
end
