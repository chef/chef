require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe StatsGrapher do
  before :each do
    @stats_grapher = MetricFu::StatsGrapher.new
    MetricFu.configuration
  end

  it "should respond to loc_counts and lot_counts and labels" do
    @stats_grapher.should respond_to(:loc_counts)
    @stats_grapher.should respond_to(:lot_counts)
    @stats_grapher.should respond_to(:labels)
  end

  describe "responding to #initialize" do
    it "should initialise loc_counts and lot_counts and labels" do
      @stats_grapher.loc_counts.should == []
      @stats_grapher.lot_counts.should == []
      @stats_grapher.labels.should == {}
    end
  end

  describe "responding to #get_metrics" do
    context "when metrics were not generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "metric_missing.yml")))
        @date = "01022003"
      end

      it "should not push to loc_counts" do
        @stats_grapher.loc_counts.should_not_receive(:push)
        @stats_grapher.get_metrics(@metrics, @date)
      end

      it "should not push to lot_counts" do
        @stats_grapher.lot_counts.should_not_receive(:push)
        @stats_grapher.get_metrics(@metrics, @date)
      end

      it "should not update labels with the date" do
        @stats_grapher.labels.should_not_receive(:update)
        @stats_grapher.get_metrics(@metrics, @date)
      end
    end

    context "when metrics have been generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "20090630.yml")))
        @date = "01022003"
      end

      it "should push to loc_counts" do
        @stats_grapher.loc_counts.should_receive(:push).with(15935)
        @stats_grapher.get_metrics(@metrics, @date)
      end

      it "should push to lot_counts" do
        @stats_grapher.lot_counts.should_receive(:push).with(7438)
        @stats_grapher.get_metrics(@metrics, @date)
      end

      it "should update labels with the date" do
        @stats_grapher.labels.should_receive(:update).with({ 0 => "01022003" })
        @stats_grapher.get_metrics(@metrics, @date)
      end
    end
  end
end
