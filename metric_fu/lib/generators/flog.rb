require 'pathname'
require 'optparse'
require 'flog'

module MetricFu

  class Flog < Generator

    def emit
      files = []
      MetricFu.flog[:dirs_to_flog].each do |directory|
        directory = "." if directory=='./'
        dir_files = Dir.glob("#{directory}/**/*.rb")
        dir_files = remove_excluded_files(dir_files)
        files += dir_files
      end
      options = ::Flog.parse_options ["--all", "--details"]

      @flogger = ::Flog.new options
      @flogger.flog files

    rescue LoadError
      if RUBY_PLATFORM =~ /java/
        puts 'running in jruby - flog tasks not available'
      end
    end

    def analyze
      @method_containers = {}
      @flogger.calls.each do |full_method_name, operators|
        container_name = full_method_name.split('#').first
        path = @flogger.method_locations[full_method_name]
        if @method_containers[container_name]
          @method_containers[container_name].add_method(full_method_name, operators, @flogger.totals[full_method_name], path)
          @method_containers[container_name].add_path(path)
        else
          mc = MethodContainer.new(container_name, path)
          mc.add_method(full_method_name, operators, @flogger.totals[full_method_name], path)
          @method_containers[container_name] = mc
        end
      end
    end

    def to_h
      sorted_containers = @method_containers.values.sort_by {|c| c.highest_score}.reverse
      {:flog => { :total => @flogger.total,
                  :average => @flogger.average,
                  :method_containers => sorted_containers.map {|method_container| method_container.to_h}}}
    end

    def per_file_info(out)
      @method_containers.each_pair do |klass, container|
        container.methods.each_pair do |method_name, data|
          next if data[:path].nil?

          file, line = data[:path].split(':')

          out[file] ||= {}
          out[file][line] ||= []
          out[file][line] << {:type => :flog, :description => "Score of %.2f" % data[:score]}
        end
      end
    end
  end

  class MethodContainer
    attr_reader :methods

    def initialize(name, path)
      @name = name
      add_path path
      @methods = {}
    end

    def add_path path
      return unless path
      @path ||= path.split(':').first
    end

    def add_method(full_method_name, operators, score, path)
      @methods[full_method_name] = {:operators => operators, :score => score, :path => path}
    end

    def to_h
      { :name => @name,
        :path => @path || '',
        :total_score => total_score,
        :highest_score => highest_score,
        :average_score => average_score,
        :methods => @methods}
    end

    def highest_score
      method_scores.max
    end

    private

    def method_scores
      @method_scores ||= @methods.values.map {|v| v[:score] }
    end

    def total_score
      @total_score ||= method_scores.inject(0) {|sum, score| sum += score}
    end

    def average_score
      total_score / method_scores.size.to_f
    end
  end
end
