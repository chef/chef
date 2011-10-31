require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe RailsBestPracticesGrapher do
  before :each do
    @stats_grapher = MetricFu::RailsBestPracticesGrapher.new
    MetricFu.configuration
  end

  it "should respond to rails_best_practices_count and labels" do
    @stats_grapher.should respond_to(:rails_best_practices_count)
    @stats_grapher.should respond_to(:labels)
  end

  describe "responding to #initialize" do
    it "should initialise rails_best_practices_count and labels" do
      @stats_grapher.rails_best_practices_count.should == []
      @stats_grapher.labels.should == {}
    end
  end

  describe "responding to #get_metrics" do
    context "when metrics were not generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "metric_missing.yml")))
        @date = "01022003"
      end

      it "should not push to rails_best_practices_count" do
        @stats_grapher.rails_best_practices_count.should_not_receive(:push)
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

      it "should push to rails_best_practices_count" do
        @stats_grapher.rails_best_practices_count.should_receive(:push).with(2)
        @stats_grapher.get_metrics(@metrics, @date)
      end

      it "should push 0 to rails_best_practices_count when no problems were found" do
        @stats_grapher.rails_best_practices_count.should_receive(:push).with(0)
        @stats_grapher.get_metrics({ :rails_best_practices => {} }, @date)
      end

      it "should update labels with the date" do
        @stats_grapher.labels.should_receive(:update).with({ 0 => "01022003" })
        @stats_grapher.get_metrics(@metrics, @date)
      end
    end
  end
end
