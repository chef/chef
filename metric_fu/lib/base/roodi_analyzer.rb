class RoodiAnalyzer
  include ScoringStrategies

  COLUMNS = %w{problems}

  def columns
    COLUMNS
  end

  def name
    :roodi
  end

  def map(row)
    ScoringStrategies.present(row)
  end

  def reduce(scores)
    ScoringStrategies.sum(scores)
  end

  def score(metric_ranking, item)
    ScoringStrategies.percentile(metric_ranking, item)
  end

  def generate_records(data, table)
    return if data==nil
    Array(data[:problems]).each do |problem|
      table << {
        "metric" => name,
        "problems" => problem[:problem],
        "file_path" => problem[:file]
      }
    end
  end

end
