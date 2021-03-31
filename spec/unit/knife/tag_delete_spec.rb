require "knife_spec_helper"

describe Chef::Knife::TagDelete do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::TagDelete.new
    @knife.name_args = [ Chef::Config[:node_name], "sadtag" ]

    @node = Chef::Node.new
    allow(@node).to receive :save
    @node.tags << "sadtag" << "happytag"
    allow(Chef::Node).to receive(:load).and_return @node
    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
  end

  describe "run" do
    it "can delete tags on a node" do
      expect(@node.tags).to eq(%w{sadtag happytag})
      @knife.run
      expect(@node.tags).to eq(["happytag"])
      expect(@stderr.string).to match(/deleted.+sadtag/i)
    end
  end
end
