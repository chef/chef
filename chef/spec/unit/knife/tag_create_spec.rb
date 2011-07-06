require File.expand_path( "../../../spec_helper", __FILE__ )

describe Chef::Knife::TagCreate do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::TagCreate.new
    @knife.name_args = [ Chef::Config[:node_name], "happytag" ]

    @node = Chef::Node.new
    @node.stub! :save
    Chef::Node.stub!(:load).and_return @node
  end

  describe "run" do
    it "can create tags on a node" do
      @knife.run
      @node.tags.should == ["happytag"]
    end
  end
end
