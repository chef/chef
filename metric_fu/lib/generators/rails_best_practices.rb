module MetricFu
  class RailsBestPractices < Generator

    def emit
      @output = `rails_best_practices --without-color .`
    end

    def analyze
      @matches = @output.chomp.split("\n").map{|m| m.split(" - ") }
      total = @matches.pop
      cleanup_color_switches(total.first)

      2.times { @matches.pop } # ignore wiki link
      @matches.reject! {|array| array.empty? }
      @matches.map! do |match|
        file, line = match[0].split(':')
        problem = match[1]

        cleanup_color_switches(file)
        cleanup_color_switches(problem)

        file.gsub!(/^\.\//, '')

        {:file => file, :line => line, :problem => problem}
      end
      @rails_best_practices_results = {:total => total, :problems => @matches}
    end

    def cleanup_color_switches(str)
      return if str.nil?
      str.gsub!(%r{^\e\[3[1|2]m}, '')
      str.gsub!(%r{\e\[0m$}, '')
    end

    def to_h
      {:rails_best_practices => @rails_best_practices_results}
    end

    def per_file_info(out)
      @rails_best_practices_results[:problems].each do |problem|
        next if problem[:file] == '' || problem[:problem].nil?

        out[problem[:file]] ||= {}

        lines = problem[:line].split(/\s*,\s*/)
        lines.each do |line|
          out[problem[:file]][line] ||= []
          out[problem[:file]][line] << {:type => :rails_best_practices, :description => problem[:problem]}
        end
      end
    end
  end
end
