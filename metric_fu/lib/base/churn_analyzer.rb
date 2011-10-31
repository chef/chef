class ChurnAnalyzer
  include ScoringStrategies

  COLUMNS = %w{times_changed}

  def columns
    COLUMNS
  end

  def name
    :churn
  end

  def map(row)
    ScoringStrategies.present(row)
  end

  def reduce(scores)
    ScoringStrategies.sum(scores)
  end

  def score(metric_ranking, item)
    flat_churn_score = 0.50
    metric_ranking.scored?(item) ? flat_churn_score : 0
  end

  def generate_records(data, table)
   return if data==nil
    Array(data[:changes]).each do |change|
      table << {
        "metric" => :churn,
        "times_changed" => change[:times_changed],
        "file_path" => change[:file_path]
      }
    end
  end

end
