class FlayAnalyzer
  include ScoringStrategies

  COLUMNS = %w{flay_reason flay_matching_reason}

  def columns
    COLUMNS
  end

  def name
    :flay
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
    Array(data[:matches]).each do |match|
      problems  = match[:reason]
      matching_reason = problems.gsub(/^[0-9]+\) /,'').gsub(/\:[0-9]+/,'')
      files     = []
      locations = []
      match[:matches].each do |file_match|
        file_path = file_match[:name].sub(%r{^/},'')
        locations << "#{file_path}:#{file_match[:line]}"
        files     << file_path
      end
      files = files.uniq
      files.each do |file|
        table << {
          "metric" => self.name,
          "file_path" => file,
          "flay_reason" => problems+" files: #{locations.join(', ')}",
          "flay_matching_reason" => matching_reason
        }
      end
    end
  end

end
