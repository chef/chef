require 'spec_helper'

describe Chef::Knife::TagList do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::TagList.new
    @knife.name_args = [ Chef::Config[:node_name], "sadtag" ]

    @node = Chef::Node.new
    @node.stub! :save
    @node.tags << "sadtag" << "happytag"
    Chef::Node.stub!(:load).and_return @node
  end

  describe "run" do
    it "can list tags on a node" do
      expected = %w(sadtag happytag)
      @node.tags.should == expected
      @knife.should_receive(:output).with(expected)
      @knife.run
    end
  end
end
