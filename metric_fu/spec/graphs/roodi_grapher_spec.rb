require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe RoodiGrapher do
  before :each do
    @roodi_grapher = MetricFu::RoodiGrapher.new
    MetricFu.configuration
  end

  it "should respond to roodi_count and labels" do
    @roodi_grapher.should respond_to(:roodi_count)
    @roodi_grapher.should respond_to(:labels)
  end

  describe "responding to #initialize" do
    it "should initialise roodi_count and labels" do
      @roodi_grapher.roodi_count.should == []
      @roodi_grapher.labels.should == {}
    end
  end

  describe "responding to #get_metrics" do
    context "when metrics were not generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "metric_missing.yml")))
        @date = "1/2"
      end

      it "should not push to roodi_count" do
        @roodi_grapher.roodi_count.should_not_receive(:push)
        @roodi_grapher.get_metrics(@metrics, @date)
      end

      it "should not update labels with the date" do
        @roodi_grapher.labels.should_not_receive(:update)
        @roodi_grapher.get_metrics(@metrics, @date)
      end
    end

    context "when metrics have been generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "20090630.yml")))
        @date = "1/2"
      end

      it "should push to roodi_count" do
        @roodi_grapher.roodi_count.should_receive(:push).with(13)
        @roodi_grapher.get_metrics(@metrics, @date)
      end

      it "should update labels with the date" do
        @roodi_grapher.labels.should_receive(:update).with({ 0 => "1/2" })
        @roodi_grapher.get_metrics(@metrics, @date)
      end
    end
  end
end
