require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Stats do
  describe "emit method" do
    it "should gather the raw data" do
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      stats = MetricFu::Stats.new
      stats.should_receive(:`).with("rake stats > tmp/metric_fu/scratch/stats/stats.txt")
      stats.emit
    end
  end

  describe "analyze method" do
    before :each do
      @lines =  <<-HERE.gsub(/^\s*/, "")
      +----------------------+-------+-------+---------+---------+-----+-------+
      | Name                 | Lines |   LOC | Classes | Methods | M/C | LOC/M |
      +----------------------+-------+-------+---------+---------+-----+-------+
      | Controllers          |   470 |   382 |       7 |      53 |   7 |     5 |
      | Helpers              |   128 |    65 |       0 |       6 |   0 |     8 |
      | Models               |   351 |   285 |       9 |      31 |   3 |     7 |
      | Libraries            |   305 |   183 |       2 |      30 |  15 |     4 |
      | Model specs          |   860 |   719 |       0 |       2 |   0 |   357 |
      | View specs           |     0 |     0 |       0 |       0 |   0 |     0 |
      | Controller specs     |  1570 |  1308 |       1 |      10 |  10 |   128 |
      | Helper specs         |   191 |   172 |       0 |       0 |   0 |     0 |
      | Library specs        |    31 |    27 |       0 |       0 |   0 |     0 |
      +----------------------+-------+-------+---------+---------+-----+-------+
      | Total                |  3906 |  3141 |      19 |     132 |   6 |    21 |
      +----------------------+-------+-------+---------+---------+-----+-------+
        Code LOC: 915     Test LOC: 2226     Code to Test Ratio: 1:2.4

      HERE
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      stats = MetricFu::Stats.new
      File.should_receive(:open).and_return(mock("file", :read => @lines))
      @results = stats.analyze
    end

    it "should get code Lines Of Code" do
      @results[:codeLOC].should == 915
    end

    it "should get test Lines Of Code" do
      @results[:testLOC].should == 2226
    end

    it "should get code to test ratio" do
      @results[:code_to_test_ratio].should == 2.4
    end

    it "should get data on models" do
      model_data = @results[:lines].find {|line| line[:name] == "Models"}
      model_data[:classes].should == 9
      model_data[:methods].should == 31
      model_data[:loc].should == 285
      model_data[:lines].should == 351
      model_data[:methods_per_class].should == 3
      model_data[:loc_per_method].should == 7
    end
  end

  describe "to_h method" do
    it "should put things into a hash" do
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      stats = MetricFu::Stats.new
      stats.instance_variable_set(:@stats, "the_stats")
      stats.to_h[:stats].should == "the_stats"
    end
  end
end