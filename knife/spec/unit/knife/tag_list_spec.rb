require "knife_spec_helper"

describe Chef::Knife::TagList do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::TagList.new
    @knife.name_args = [ Chef::Config[:node_name], "sadtag" ]

    @node = Chef::Node.new
    allow(@node).to receive :save
    @node.tags << "sadtag" << "happytag"
    allow(Chef::Node).to receive(:load).and_return @node
  end

  describe "run" do
    it "can list tags on a node" do
      expected = %w{sadtag happytag}
      expect(@node.tags).to eq(expected)
      expect(@knife).to receive(:output).with(expected)
      @knife.run
    end
  end
end
