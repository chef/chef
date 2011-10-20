class RcovAnalyzer
  include ScoringStrategies

  COLUMNS = %w{percentage_uncovered}

  def columns
    COLUMNS
  end

  def name
    :rcov
  end

  def map(row)
    row.percentage_uncovered
  end

  def reduce(scores)
    ScoringStrategies.average(scores)
  end

  def score(metric_ranking, item)
    ScoringStrategies.identity(metric_ranking, item)
  end

  def generate_records(data, table)
   return if data==nil
   data.each do |file_name, info|
     next if (file_name == :global_percent_run) || (info[:methods].nil?)
     info[:methods].each do |method_name, percentage_uncovered|
       location = MetricFu::Location.for(method_name)
       table << {
         "metric" => :rcov,
         'file_path' => file_name,
         'class_name' => location.class_name,
         "method_name" => location.method_name,
         "percentage_uncovered" => percentage_uncovered
       }
     end
   end
 end

end