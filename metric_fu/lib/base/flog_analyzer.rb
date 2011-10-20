class FlogAnalyzer
  include ScoringStrategies

  COLUMNS = %w{score}

  def columns
    COLUMNS
  end

  def name
    :flog
  end

  def map(row)
    row.score
  end

  def reduce(scores)
    ScoringStrategies.average(scores)
  end

  def score(metric_ranking, item)
    ScoringStrategies.identity(metric_ranking, item)
  end

  def generate_records(data, table)
    return if data==nil
    Array(data[:method_containers]).each do |method_container|
      Array(method_container[:methods]).each do |entry|
        file_path = entry[1][:path].sub(%r{^/},'') if entry[1][:path]
        location = MetricFu::Location.for(entry.first)
        table << {
          "metric" => name,
          "score" => entry[1][:score],
          "file_path" => file_path,
          "class_name" => location.class_name,
          "method_name" => location.method_name
        }
      end
    end
  end

end
