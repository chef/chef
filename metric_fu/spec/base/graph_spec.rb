require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricFu do

  describe "responding to #graph" do
    it "should return an instance of Graph" do
      MetricFu.graph.should be_a(Graph)
    end
  end
end

describe MetricFu::Graph do

  before(:each) do
    @graph = MetricFu::Graph.new
  end

  describe "responding to #add with gchart enabled" do
    it 'should instantiate a grapher and push it to clazz' do
      @graph.clazz.should_receive(:push).with(an_instance_of(RcovGchartGrapher))
      @graph.add("rcov", 'gchart')
    end
  end

  describe "responding to #add with gchart enabled" do
    it 'should instantiate a grapher and push it to clazz' do
      @graph.clazz.should_receive(:push).with(an_instance_of(RcovGchartGrapher))
      @graph.add("rcov", 'gchart')
    end
  end 

  describe "setting the date on the graph" do
    before(:each) do
      @graph.stub!(:puts)
    end

    it "should set the date once for one data point" do
      Dir.should_receive(:[]).and_return(["metric_fu/tmp/_data/20101105.yml"])
      File.should_receive(:join)
      File.should_receive(:open).and_return("Metrics")
      mock_grapher = stub
      mock_grapher.should_receive(:get_metrics).with("Metrics", "11/5")
      mock_grapher.should_receive(:graph!)
     
      @graph.clazz = [mock_grapher]
      @graph.generate
    end

    it "should set the date when the data directory isn't in the default place" do
      Dir.should_receive(:[]).and_return(["/some/kind/of/weird/directory/somebody/configured/_data/20101105.yml"])
      File.should_receive(:join)
      File.should_receive(:open).and_return("Metrics")
      mock_grapher = stub
      mock_grapher.should_receive(:get_metrics).with("Metrics", "11/5")
      mock_grapher.should_receive(:graph!)

      @graph.clazz = [mock_grapher]
      @graph.generate
    end
  end 
end
