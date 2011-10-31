require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe FlayGrapher do
  before :each do
    @flay_grapher = MetricFu::FlayGrapher.new
    MetricFu.configuration
  end

  it "should respond to flay_score and labels" do
    @flay_grapher.should respond_to(:flay_score)
    @flay_grapher.should respond_to(:labels)
  end

  describe "responding to #initialize" do
    it "should initialise flay_score and labels" do
      @flay_grapher.flay_score.should == []
      @flay_grapher.labels.should == {}
    end
  end

  describe "responding to #get_metrics" do
    context "when metrics were not generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "metric_missing.yml")))
        @date = "1/2"
      end

      it "should not push to flay_score" do
        @flay_grapher.flay_score.should_not_receive(:push)
        @flay_grapher.get_metrics(@metrics, @date)
      end

      it "should not update labels with the date" do
        @flay_grapher.labels.should_not_receive(:update)
        @flay_grapher.get_metrics(@metrics, @date)
      end
    end

    context "when metrics have been generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "20090630.yml")))
        @date = "1/2"
      end

      it "should push to flay_score" do
        @flay_grapher.flay_score.should_receive(:push).with(476)
        @flay_grapher.get_metrics(@metrics, @date)
      end

      it "should update labels with the date" do
        @flay_grapher.labels.should_receive(:update).with({ 0 => "1/2" })
        @flay_grapher.get_metrics(@metrics, @date)
      end
    end
  end
end
