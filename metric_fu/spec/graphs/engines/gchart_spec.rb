require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
describe MetricFu::Grapher do
  describe "require_graphing_gem" do
    it "should give a warning if trying to use gchart but gem is not installed" do
      MetricFu::Configuration.run {|config| config.graph_engine = :gchart}
      MetricFu::Grapher.should_receive(:require).with('gchart').and_raise(LoadError)
      MetricFu::Grapher.should_receive(:puts).with(/If you want to use google charts/)
      MetricFu::Grapher.require_graphing_gem
    end
  end
end

describe MetricFu::GchartGrapher do
  describe "determine_y_axis_scale" do
    it "should set defaults when empty array" do
      grapher = Object.new.extend(MetricFu::GchartGrapher)
      grapher.determine_y_axis_scale([])
      grapher.instance_variable_get(:@max_value).should == 10
      grapher.instance_variable_get(:@yaxis).should == [0, 2, 4, 6, 8, 10]
    end

    it "should set max value of the graph above largest value" do
      grapher = Object.new.extend(MetricFu::GchartGrapher)
      grapher.determine_y_axis_scale([19])
      grapher.instance_variable_get(:@max_value).should == 20

      grapher.determine_y_axis_scale([20])
      grapher.instance_variable_get(:@max_value).should == 25
    end
  end
end

describe "Gchart graphers" do
  before :each do
    MetricFu::Configuration.run {|config| config.graph_engine = :gchart}
  end

  describe "FlayGchartGrapher graph! method" do
    it "should set static values for graph" do
      grapher = FlayGchartGrapher.new
      expected = {
        :size => MetricFu::GchartGrapher::GCHART_GRAPH_SIZE,
        :title => URI.escape("Flay: duplication"),
        :axis_with_labels => 'x,y',
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'flay.png'),
      }
      Gchart.should_receive(:line).with(hash_including(expected))
      grapher.graph!
    end
  end

  describe "FlogGchartGrapher graph! method" do
    it "should set static values for graph" do
      grapher = FlogGchartGrapher.new
      expected = {
        :size => MetricFu::GchartGrapher::GCHART_GRAPH_SIZE,
        :title => URI.escape("Flog: code complexity"),
        :stacked => false,
        :bar_colors => MetricFu::GchartGrapher::COLORS[0..1],
        :legend => ['average', 'top 5% average'],
        :custom => "chdlp=t",
        :axis_with_labels => 'x,y',
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'flog.png'),
      }
      Gchart.should_receive(:line).with(hash_including(expected))
      grapher.graph!
    end
  end

  describe "RcovGchartGrapher graph! method" do
    it "should set static values for graph" do
      grapher = RcovGchartGrapher.new
      expected = {
        :size => MetricFu::GchartGrapher::GCHART_GRAPH_SIZE,
        :title => URI.escape("Rcov: code coverage"),
        :max_value => 101,
        :axis_with_labels => 'x,y',
        :axis_labels => [grapher.labels.values, [0,20,40,60,80,100]],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'rcov.png'),
      }
      Gchart.should_receive(:line).with(hash_including(expected))
      grapher.graph!
    end
  end

  describe "ReekGchartGrapher graph! method" do
    it "should set static values for graph" do
      grapher = ReekGchartGrapher.new
      expected = {
        :size => MetricFu::GchartGrapher::GCHART_GRAPH_SIZE,
        :title => URI.escape("Reek: code smells"),
        :stacked => false,
        :bar_colors => MetricFu::GchartGrapher::COLORS,
        :axis_with_labels => 'x,y',
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'reek.png'),
      }
      Gchart.should_receive(:line).with(hash_including(expected))
      grapher.graph!
    end
  end

  describe "RoodiGchartGrapher graph! method" do
    it "should set static values for graph" do
      grapher = RoodiGchartGrapher.new
      expected = {
        :size => MetricFu::GchartGrapher::GCHART_GRAPH_SIZE,
        :title => URI.escape("Roodi: potential design problems"),
        :axis_with_labels => 'x,y',
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'roodi.png'),
      }
      Gchart.should_receive(:line).with(hash_including(expected))
      grapher.graph!
    end
  end

  describe "StatsGchartGrapher graph! method" do
    it "should set static values for graph" do
      grapher = StatsGchartGrapher.new
      expected = {
        :size => MetricFu::GchartGrapher::GCHART_GRAPH_SIZE,
        :title => URI.escape("Stats: LOC & LOT"),
        :bar_colors => MetricFu::GchartGrapher::COLORS[0..1],
        :legend => ['Lines of code', 'Lines of test'],
        :custom => "chdlp=t",
        :axis_with_labels => 'x,y',
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'stats.png'),
      }
      Gchart.should_receive(:line).with(hash_including(expected))
      grapher.graph!
    end
  end

  describe "RailsBestPracticesGchartGrapher graph! method" do
    it "should set static values for graph" do
      grapher = RailsBestPracticesGchartGrapher.new
      expected = {
        :size => MetricFu::GchartGrapher::GCHART_GRAPH_SIZE,
        :title => URI.escape("Rails Best Practices: design problems"),
        :bar_colors => MetricFu::GchartGrapher::COLORS[0..1],
        :legend => ['Problems'],
        :custom => "chdlp=t",
        :axis_with_labels => 'x,y',
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'rails_best_practices.png'),
      }
      Gchart.should_receive(:line).with(hash_including(expected))
      grapher.graph!
    end
  end
end
