module MetricFu

  def self.graph
    @graph ||= Graph.new
  end

  class Graph

    attr_accessor :clazz

    def initialize
      self.clazz = []
    end

    def add(graph_type, graph_engine)
      grapher_name = graph_type.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase } + graph_engine.to_s.capitalize + "Grapher"
      self.clazz.push MetricFu.const_get(grapher_name).new
    end


    def generate
      return if self.clazz.empty?
      puts "Generating graphs"
      Dir[File.join(MetricFu.data_directory, '*.yml')].sort.each do |metric_file|
        puts "Generating graphs for #{metric_file}"
        date_parts = year_month_day_from_filename(metric_file)
        metrics = YAML::load(File.open(metric_file))

        self.clazz.each do |grapher|
          grapher.get_metrics(metrics, "#{date_parts[:m]}/#{date_parts[:d]}")
        end
      end
      self.clazz.each do |grapher|
        grapher.graph!
      end
    end

    private
    def year_month_day_from_filename(path_to_file_with_date)
      date = path_to_file_with_date.match(/\/(\d+).yml$/)[1]
      {:y => date[0..3].to_i, :m => date[4..5].to_i, :d => date[6..7].to_i}
    end
  end
end
