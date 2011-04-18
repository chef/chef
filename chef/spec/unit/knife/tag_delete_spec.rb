require File.expand_path( "../../../spec_helper", __FILE__ )

describe Chef::Knife::TagDelete do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::TagDelete.new
    @knife.name_args = [ Chef::Config[:node_name], "sadtag" ]

    @node = Chef::Node.new
    @node.stub! :save
    @node.tags << "sadtag" << "happytag"
    Chef::Node.stub!(:load).and_return @node
  end

  describe "run" do
    it "can delete tags on a node" do
      @node.tags.should == ["sadtag", "happytag"]
      @knife.run
      @node.tags.should == ["happytag"]
    end
  end
end
