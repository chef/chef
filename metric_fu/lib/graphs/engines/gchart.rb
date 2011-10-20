module MetricFu
  module GchartGrapher
    COLORS = %w{009999 FF7400 A60000 008500 E6399B 344AD7 00B860 D5CCB9}
    GCHART_GRAPH_SIZE = "945x317" # maximum permitted image size is 300000 pixels

    NUMBER_OF_TICKS = 6
    def determine_y_axis_scale(values)
      values.collect! {|val| val || 0.0 }
      if values.empty?
        @max_value = 10
        @yaxis = [0, 2, 4, 6, 8, 10]
      else
        @max_value = values.max + Integer(0.1 * values.max)
        portion_size = (@max_value / (NUMBER_OF_TICKS - 1).to_f).ceil
        @yaxis = []
        NUMBER_OF_TICKS.times {|n| @yaxis << Integer(portion_size * n) }
        @max_value = @yaxis.last
      end
    end
  end

  class Grapher
    include MetricFu::GchartGrapher

    def self.require_graphing_gem
      require 'gchart' if MetricFu.graph_engine == :gchart
    rescue LoadError
      puts "#"*99 + "\n" +
           "If you want to use google charts for graphing, you'll need to install the googlecharts rubygem." +
           "\n" + "#"*99
    end
  end

  class FlayGchartGrapher < FlayGrapher
    def graph!
      determine_y_axis_scale(@flay_score)
      url = Gchart.line(
        :size => GCHART_GRAPH_SIZE,
        :title => URI.escape("Flay: duplication"),
        :data => @flay_score,
        :max_value => @max_value,
        :axis_with_labels => 'x,y',
        :axis_labels => [@labels.values, @yaxis],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'flay.png'))
    end
  end

  class FlogGchartGrapher < FlogGrapher
    def graph!
      determine_y_axis_scale(@top_five_percent_average + @flog_average)
      url = Gchart.line(
        :size => GCHART_GRAPH_SIZE,
        :title => URI.escape("Flog: code complexity"),
        :data => [@flog_average, @top_five_percent_average],
        :stacked => false,
        :bar_colors => COLORS[0..1],
        :legend => ['average', 'top 5% average'],
        :custom => "chdlp=t",
        :max_value => @max_value,
        :axis_with_labels => 'x,y',
        :axis_labels => [@labels.values, @yaxis],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'flog.png'))
    end
  end

  class RcovGchartGrapher < RcovGrapher
    def graph!
      url = Gchart.line(
        :size => GCHART_GRAPH_SIZE,
        :title => URI.escape("Rcov: code coverage"),
        :data => self.rcov_percent,
        :max_value => 101,
        :axis_with_labels => 'x,y',
        :axis_labels => [self.labels.values, [0,20,40,60,80,100]],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'rcov.png')
      )
    end
  end

  class ReekGchartGrapher < ReekGrapher
    def graph!
      determine_y_axis_scale(@reek_count.values.flatten.uniq)
      values = []
      legend = @reek_count.keys.sort
      legend.collect {|k| values << @reek_count[k]}

      url = Gchart.line(
        :size => GCHART_GRAPH_SIZE,
        :title => URI.escape("Reek: code smells"),
        :data => values,
        :stacked => false,
        :bar_colors => COLORS,
        :legend => legend,
        :custom => "chdlp=t",
        :max_value => @max_value,
        :axis_with_labels => 'x,y',
        :axis_labels => [@labels.values, @yaxis],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'reek.png'))
    end
  end

  class RoodiGchartGrapher < RoodiGrapher
    def graph!
      determine_y_axis_scale(@roodi_count)
      url = Gchart.line(
        :size => GCHART_GRAPH_SIZE,
        :title => URI.escape("Roodi: potential design problems"),
        :data => @roodi_count,
        :max_value => @max_value,
        :axis_with_labels => 'x,y',
        :axis_labels => [@labels.values, @yaxis],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'roodi.png'))
    end
  end

  class StatsGchartGrapher < StatsGrapher
    def graph!
      determine_y_axis_scale(@loc_counts + @lot_counts)
      url = Gchart.line(
        :size => GCHART_GRAPH_SIZE,
        :title => URI.escape("Stats: LOC & LOT"),
        :data => [@loc_counts, @lot_counts],
        :bar_colors => COLORS[0..1],
        :legend => ['Lines of code', 'Lines of test'],
        :custom => "chdlp=t",
        :max_value => @max_value,
        :axis_with_labels => 'x,y',
        :axis_labels => [@labels.values, @yaxis],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'stats.png'))
    end
  end

  class RailsBestPracticesGchartGrapher < RailsBestPracticesGrapher
    def graph!
      determine_y_axis_scale(@rails_best_practices_count)
      url = Gchart.line(
        :size => GCHART_GRAPH_SIZE,
        :title => URI.escape("Rails Best Practices: design problems"),
        :data => self.rails_best_practices_count,
        :bar_colors => COLORS[0..1],
        :legend => ['Problems'],
        :custom => "chdlp=t",
        :max_value => @max_value,
        :axis_with_labels => 'x,y',
        :axis_labels => [@labels.values, @yaxis],
        :format => 'file',
        :filename => File.join(MetricFu.output_directory, 'rails_best_practices.png')
      )
    end
  end
end
