class AnalysisError < RuntimeError; end;

class MetricAnalyzer

  COMMON_COLUMNS = %w{metric}
  GRANULARITIES =  %w{file_path class_name method_name}

  attr_accessor :table

  def initialize(yaml)
    if(yaml.is_a?(String))
       @yaml = YAML.load(yaml)
     else
       @yaml = yaml
     end
    @file_ranking = MetricFu::Ranking.new
    @class_ranking = MetricFu::Ranking.new
    @method_ranking = MetricFu::Ranking.new
    rankings = [@file_ranking, @class_ranking, @method_ranking]

    tool_analyzers = [ReekAnalyzer.new, RoodiAnalyzer.new,
    FlogAnalyzer.new, ChurnAnalyzer.new, SaikuroAnalyzer.new,
    FlayAnalyzer.new, StatsAnalyzer.new, RcovAnalyzer.new]
    # TODO There is likely a clash that will happen between
    # column names eventually. We should probably auto-prefix
    # them (e.g. "roodi_problem")
    columns = COMMON_COLUMNS + GRANULARITIES + tool_analyzers.map{|analyzer| analyzer.columns}.flatten

    @table = make_table(columns)

    # These tables are an optimization. They contain subsets of the master table.
    # TODO - these should be pushed into the Table class now
    @tool_tables   = make_table_hash(columns)
    @file_tables   = make_table_hash(columns)
    @class_tables  = make_table_hash(columns)
    @method_tables = make_table_hash(columns)

    tool_analyzers.each do |analyzer|
      analyzer.generate_records(@yaml[analyzer.name], @table)
    end

    build_lookups!(table)
    process_rows!(table)

    tool_analyzers.each do |analyzer|
      GRANULARITIES.each do |granularity|
        metric_ranking = calculate_metric_scores(granularity, analyzer)
        add_to_master_ranking(ranking(granularity), metric_ranking, analyzer)
      end
    end

    rankings.each do |ranking|
      ranking.delete(nil)
    end
  end

  def location(item, value)
    sub_table = get_sub_table(item, value)
    if(sub_table.length==0)
      raise AnalysisError, "The #{item.to_s} '#{value.to_s}' does not have any rows in the analysis table"
    else
      first_row = sub_table[0]
      case item
      when :class
        MetricFu::Location.get(first_row.file_path, first_row.class_name, nil)
      when :method
        MetricFu::Location.get(first_row.file_path, first_row.class_name, first_row.method_name)
      when :file
        MetricFu::Location.get(first_row.file_path, nil, nil)
      else
        raise ArgumentError, "Item must be :class, :method, or :file"
      end
    end
  end

  #todo redo as item,value, options = {}
  # Note that the other option for 'details' is :detailed (this isn't
  # at all clear from this method itself
  def problems_with(item, value, details = :summary, exclude_details = [])
    sub_table = get_sub_table(item, value)
    #grouping = Ruport::Data::Grouping.new(sub_table, :by => 'metric')
    grouping = get_grouping(sub_table, :by => 'metric')
    problems = {}
    grouping.each do |metric, table|
      if details == :summary || exclude_details.include?(metric)
        problems[metric] = present_group(metric,table)
      else
        problems[metric] = present_group_details(metric,table)
      end
    end
    problems
  end

  def worst_methods(size = nil)
    @method_ranking.top(size)
  end

  def worst_classes(size = nil)
    @class_ranking.top(size)
  end

  def worst_files(size = nil)
    @file_ranking.top(size)
  end

  private

  def get_grouping(table, opts)
    #Ruport::Data::Grouping.new(table, opts)
    Grouping.new(table, opts)
    #@grouping_cache ||= {}
    #@grouping_cache.fetch(grouping_key(table,opts)) do
    #  @grouping_cache[grouping_key(table,opts)] = Ruport::Data::Grouping.new(table, opts)
    #end
  end

  def grouping_key(table, opts)
    "table #{table.object_id} opts #{opts.inspect}"
  end

  def build_lookups!(table)
    @class_and_method_to_file ||= {}
    # Build a mapping from [class,method] => filename
    # (and make sure the mapping is unique)
    table.each do |row|
      # We know that Saikuro provides the wrong data
      next if row['metric'] == :saikuro
      key = [row['class_name'], row['method_name']]
      file_path = row['file_path']
      @class_and_method_to_file[key] ||= file_path
    end
  end

  def process_rows!(table)
    # Correct incorrect rows in the table
    table.each do |row|
      row_metric = row['metric'] #perf optimization
      if row_metric == :saikuro
        fix_row_file_path!(row)
      end
      @tool_tables[row_metric] << row
      @file_tables[row["file_path"]] << row
      @class_tables[row["class_name"]] << row
      @method_tables[row["method_name"]] << row
    end
  end

  def fix_row_file_path!(row)
    # We know that Saikuro rows are broken
    # next unless row['metric'] == :saikuro
    key = [row['class_name'], row['method_name']]
    current_file_path = row['file_path'].to_s
    correct_file_path = @class_and_method_to_file[key]
    if(correct_file_path!=nil && correct_file_path.include?(current_file_path))
      row['file_path'] = correct_file_path
    else
      # There wasn't an exact match, so we can do a substring match
      matching_file_path = file_paths.detect {|file_path|
        file_path!=nil && file_path.include?(current_file_path)
      }
      if(matching_file_path)
        row['file_path'] = matching_file_path
      end
    end
  end

  def file_paths
    @file_paths ||= @table.column('file_path').uniq
  end

  def ranking(column_name)
    case column_name
    when "file_path"
      @file_ranking
    when "class_name"
      @class_ranking
    when "method_name"
      @method_ranking
    else
      raise ArgumentError, "Invalid column name #{column_name}"
    end
  end

  def calculate_metric_scores(granularity, analyzer)
    metric_ranking = MetricFu::Ranking.new
    metric_violations = @tool_tables[analyzer.name]
    metric_violations.each do |row|
      location = row[granularity]
      metric_ranking[location] ||= []
      metric_ranking[location] << analyzer.map(row)
    end

    metric_ranking.each do |item, scores|
      metric_ranking[item] = analyzer.reduce(scores)
    end

    metric_ranking
  end

  def add_to_master_ranking(master_ranking, metric_ranking, analyzer)
    metric_ranking.each do |item, _|
      master_ranking[item] ||= 0
      master_ranking[item] += analyzer.score(metric_ranking, item) # scaling? Do we just add in the raw score?
    end
  end

  def most_common_column(column_name, size)
    #grouping = Ruport::Data::Grouping.new(@table,
    #                                      :by => column_name,
    #                                      :order => lambda { |g| -g.size})
    get_grouping(@table, :by => column_name, :order => lambda {|g| -g.size})
    values = []
    grouping.each do |value, _|
      values << value if value!=nil
      if(values.size==size)
        break
      end
    end
    return nil if values.empty?
    if(values.size == 1)
      return values.first
    else
      return values
    end
  end

  # TODO: As we get fancier, the presenter should
  # be its own class, not just a method with a long
  # case statement
  def present_group(metric, group)
    occurences = group.size
    case(metric)
    when :reek
      "found #{occurences} code smells"
    when :roodi
      "found #{occurences} design problems"
    when :churn
      "detected high level of churn (changed #{group[0].times_changed} times)"
    when :flog
      complexity = get_mean(group.column("score"))
      "#{"average " if occurences > 1}complexity is %.1f" % complexity
    when :saikuro
      complexity = get_mean(group.column("complexity"))
      "#{"average " if occurences > 1}complexity is %.1f" % complexity
    when :flay
      "found #{occurences} code duplications"
    when :rcov
      average_code_uncoverage = get_mean(group.column("percentage_uncovered"))
      "#{"average " if occurences > 1}uncovered code is %.1f%" % average_code_uncoverage
    else
      raise AnalysisError, "Unknown metric #{metric}"
    end
  end

  def present_group_details(metric, group)
    occurences = group.size
    case(metric)
    when :reek
      message = "found #{occurences} code smells<br/>"
      group.each do |item|
        type    = item.data["reek__type_name"]
        reek_message = item.data["reek__message"]
        message << "* #{type}: #{reek_message}<br/>"
      end
      message
    when :roodi
      message = "found #{occurences} design problems<br/>"
      group.each do |item|
        problem    = item.data["problems"]
        message << "* #{problem}<br/>"
      end
      message
    when :churn
      "detected high level of churn (changed #{group[0].times_changed} times)"
    when :flog
      complexity = get_mean(group.column("score"))
      "#{"average " if occurences > 1}complexity is %.1f" % complexity
    when :saikuro
      complexity = get_mean(group.column("complexity"))
      "#{"average " if occurences > 1}complexity is %.1f" % complexity
    when :flay
      message = "found #{occurences} code duplications<br/>"
      group.each do |item|
        problem    = item.data["flay_reason"]
        problem    = problem.gsub(/^[0-9]*\)/,'')
        problem    = problem.gsub(/files\:/,' <br>&nbsp;&nbsp;&nbsp;files:')
        message << "* #{problem}<br/>"
      end
      message
    else
      raise AnalysisError, "Unknown metric #{metric}"
    end
  end

  def make_table_hash(columns)
    Hash.new { |hash, key|
      hash[key] = make_table(columns)
    }
  end

  def make_table(columns)
    Table.new(:column_names => columns)
  end

  def get_sub_table(item, value)
    tables = {
      :class  => @class_tables,
      :method => @method_tables,
      :file   => @file_tables,
      :tool   => @tool_tables
    }.fetch(item) do
      raise ArgumentError, "Item must be :class, :method, or :file"
    end
    tables[value]
  end

  def get_mean(collection)
    collection_length = collection.length
    sum = 0
    sum = collection.inject( nil ) { |sum,x| sum ? sum+x : x }
    (sum.to_f / collection_length.to_f)
  end

end

class Record

  attr_reader :data

  def initialize(data, columns)
    @data = data
    @columns = columns
  end

  def method_missing(name, *args, &block)
    key = name.to_s
    if @data.has_key?(key)
      @data[key]
    elsif @columns.member?(key)
      nil
    else
      super(name, *args, &block)
    end
  end

  def []=(key, value)
     @data[key]=value
  end

  def [](key)
    @data[key]
  end

  def keys
    @data.keys
  end

  def has_key?(key)
    @data.has_key?(key)
  end

  def attributes
    @columns
  end

end

class Grouping

  def initialize(table, opts)
    column_name = opts.fetch(:by)
    order = opts.fetch(:order) { nil }
    hash = {}
    if column_name.to_sym == :metric # special optimized case
      hash = table.group_by_metric
    else
      table.each do |row|
        hash[row[column_name]] ||= Table.new(:column_names => row.attributes)
        hash[row[column_name]] << row
      end
    end
    if order
      @arr = hash.sort_by &order
    else
      @arr = hash.to_a
    end
  end

  def [](key)
    @arr.each do |group_key, table|
      return table if group_key == key
    end
    return nil
  end

  def each
    @arr.each do |value, rows|
      yield value, rows
    end
  end

end


