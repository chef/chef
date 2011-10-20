class Table

  def initialize(opts = {})
    @rows = []
    @columns = opts.fetch(:column_names)

    @make_index = opts.fetch(:make_index) {true}
    @metric_index = {}
  end

  def <<(row)
    record = nil
    if row.is_a?(Record) || row.is_a?(CodeIssue)
      record = row
    else
      record = Record.new(row, @columns)
    end
    @rows << record
    updated_key_index(record) if @make_index
  end

  def each
    @rows.each do |row|
      yield row
    end
  end

  def size
    length
  end

  def length
    @rows.length
  end

  def [](index)
    @rows[index]
  end

  def column(column_name)
    arr = []
    @rows.each do |row|
      arr << row[column_name]
    end
    arr
  end

  def group_by_metric
    @metric_index.to_a
  end

  def rows_with(conditions)
    if optimized_conditions?(conditions)
      optimized_select(conditions)
    else
      slow_select(conditions)
    end
  end

  def delete_at(index)
    @rows.delete_at(index)
  end

  def to_a
    @rows
  end

  def map
    new_table = Table.new(:column_names => @columns)
    @rows.map do |row|
      new_table << (yield row)
    end
    new_table
  end

  private

  def optimized_conditions?(conditions)
    conditions.keys.length == 1 && conditions.keys.first.to_sym == :metric
  end

  def optimized_select(conditions)
    metric = (conditions['metric'] || conditions[:metric]).to_s
    @metric_index[metric].to_a.clone
  end

  def slow_select(conditions)
    @rows.select do |row|
      conditions.all? do |key, value|
        row.has_key?(key.to_s) && row[key.to_s] == value
      end
    end
  end

  def updated_key_index(record)
    if record.has_key?('metric')
      @metric_index[record.metric] ||= Table.new(:column_names => @columns, :make_index => false)
      @metric_index[record.metric] << record
    end
  end

end
