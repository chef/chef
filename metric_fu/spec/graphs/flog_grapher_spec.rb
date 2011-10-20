require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricFu::FlogGrapher do
  before :each do
    MetricFu.configuration
    @flog_grapher = MetricFu::FlogGrapher.new

  end

  it "should respond to flog_total, flog_average and labels" do
    @flog_grapher.should respond_to(:flog_average)
    @flog_grapher.should respond_to(:labels)
    @flog_grapher.should respond_to(:top_five_percent_average)
  end

  describe "responding to #initialize" do
    it "should initialize top_five_percent_average, flog_average and labels" do
      @flog_grapher.flog_average.should == []
      @flog_grapher.labels.should == {}
      @flog_grapher.top_five_percent_average.should == []
    end
  end

  describe "responding to #get_metrics" do
    before(:each) do
      methods = {}
      100.times do |i|
        methods["method_name_#{i}"] = {:score => i.to_f}
      end

      @metrics = {:flog => {:total => 111.1,
                            :average => 7.7,
                            :method_containers => [ {:methods => methods } ] } }
      @date = "1/2"
    end

    it "should push to top_five_percent_average" do
      average = (99.0 + 98.0 + 97.0 + 96.0 + 95.0) / 5.0
      @flog_grapher.top_five_percent_average.should_receive(:push).with(average)
      @flog_grapher.get_metrics(@metrics, @date)
    end

    it "should push 9.9 to flog_average" do
      @flog_grapher.flog_average.should_receive(:push).with(7.7)
      @flog_grapher.get_metrics(@metrics, @date)
    end

    context "when metrics were not generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "metric_missing.yml")))
        @date = "1/2"
      end

      it "should not push to top_five_percent_average" do
        @flog_grapher.top_five_percent_average.should_not_receive(:push)
        @flog_grapher.get_metrics(@metrics, @date)
      end

      it "should not push to flog_average" do
        @flog_grapher.flog_average.should_not_receive(:push)
        @flog_grapher.get_metrics(@metrics, @date)
      end

      it "should not update labels with the date" do
        @flog_grapher.labels.should_not_receive(:update)
        @flog_grapher.get_metrics(@metrics, @date)
      end
    end

    context "when metrics have been generated" do
      before(:each) do
        @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "20090630.yml")))
        @date = "1/2"
      end

      it "should push to top_five_percent_average" do
        average = (73.6 + 68.5 + 66.1 + 46.6 + 44.8 + 44.1 + 41.2 + 36.0) / 8.0
        @flog_grapher.top_five_percent_average.should_receive(:push).with(average)
        @flog_grapher.get_metrics(@metrics, @date)
      end

      it "should push to flog_average" do
        @flog_grapher.flog_average.should_receive(:push).with(9.9)
        @flog_grapher.get_metrics(@metrics, @date)
      end

      it "should update labels with the date" do
        @flog_grapher.labels.should_receive(:update).with({ 0 => "1/2" })
        @flog_grapher.get_metrics(@metrics, @date)
      end
    end
  end

  describe "responding to #get_metrics with legacy data" do
    before(:each) do
      @metrics = YAML::load(File.open(File.join(File.dirname(__FILE__), "..", "resources", "yml", "20090630.yml")))

      @date = "1/2"
    end

    it "should push to top_five_percent_average" do
      average = (73.6 + 68.5 + 66.1 + 46.6 + 44.8 + 44.1 + 41.2 + 36.0) / 8.0
      @flog_grapher.top_five_percent_average.should_receive(:push).with(average)
      @flog_grapher.get_metrics(@metrics, @date)
    end
  end

end
