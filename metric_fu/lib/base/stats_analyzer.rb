class StatsAnalyzer

  COLUMNS = %w{stat_name stat_value}

  def columns
    COLUMNS
  end

  def name
    :stats
  end

  def map(row)
    0
  end

  def reduce(scores)
    0
  end

  def score(metric_ranking, item)
    0
  end

  def generate_records(data, table)
    return if data == nil
    data.each do |key, value|
      next if value.kind_of?(Array)
      table << {
        "metric" => name,
        "stat_name" => key,
        "stat_value" => value
      }
    end
  end

end
