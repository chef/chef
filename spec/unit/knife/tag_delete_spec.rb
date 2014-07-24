require 'spec_helper'

describe Chef::Knife::TagDelete do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::TagDelete.new
    @knife.name_args = [ Chef::Config[:node_name], "sadtag" ]

    @node = Chef::Node.new
    @node.stub :save
    @node.tags << "sadtag" << "happytag"
    Chef::Node.stub(:load).and_return @node
    @stderr = StringIO.new
    @knife.ui.stub(:stderr).and_return(@stderr)
  end

  describe "run" do
    it "can delete tags on a node" do
      @node.tags.should == ["sadtag", "happytag"]
      @knife.run
      @node.tags.should == ["happytag"]
      @stderr.string.should match /deleted.+sadtag/i
    end
  end
end
