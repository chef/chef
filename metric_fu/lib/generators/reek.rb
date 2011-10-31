module MetricFu

  class Reek < Generator
    REEK_REGEX = /^(\S+) (.*) \((.*)\)$/

    def emit
      files_to_reek = MetricFu.reek[:dirs_to_reek].map{|dir| Dir[File.join(dir, "**/*.rb")] }
      files = remove_excluded_files(files_to_reek.flatten)
      config_file_param = MetricFu.reek[:config_file_pattern] ? "--config #{MetricFu.reek[:config_file_pattern]}" : ''
      @output = `reek #{config_file_param} #{files.join(" ")}`
      @output = massage_for_reek_12 if reek_12?
    end

    def reek_12?
      return false if @output.length == 0
      (@output =~ /^"/) != 0
    end

    def massage_for_reek_12
      section_break = ''
      @output.split("\n").map do |line|
        case line
        when /^  /
          "#{line.gsub(/^  /, '')}\n"
        else
          parts = line.split(" -- ")
          if parts[1].nil?
            "#{line}\n"
          else
            warnings = parts[1].gsub(/ \(.*\):/, ':')
            result = "#{section_break}\"#{parts[0]}\" -- #{warnings}\n"
            section_break = "\n"
            result
          end
        end
      end.join
    end

    def analyze
      @matches = @output.chomp.split("\n\n").map{|m| m.split("\n") }
      @matches = @matches.map do |match|
        file_path = match.shift.split('--').first
        file_path = file_path.gsub('"', ' ').strip
        code_smells = match.map do |smell|
          match_object = smell.match(REEK_REGEX)
          next unless match_object
          {:method => match_object[1].strip,
           :message => match_object[2].strip,
           :type => match_object[3].strip}
        end.compact
        {:file_path => file_path, :code_smells => code_smells}
      end
    end

    def to_h
      {:reek => {:matches => @matches}}
    end

    def per_file_info(out)
      @matches.each do |file_data|
        next if File.extname(file_data[:file_path]) == '.erb'
        begin
          line_numbers = MetricFu::LineNumbers.new(File.open(file_data[:file_path], 'r').read)
        rescue StandardError => e
          raise e unless e.message =~ /you shouldn't be able to get here/
          puts "ruby_parser blew up while trying to parse #{file_path}. You won't have method level reek information for this file."
          next
        end

        out[file_data[:file_path]] ||= {}
        file_data[:code_smells].each do |smell_data|
          line = line_numbers.start_line_for_method(smell_data[:method])
          out[file_data[:file_path]][line.to_s] ||= []
          out[file_data[:file_path]][line.to_s] << {:type => :reek,
                                                    :description => "#{smell_data[:type]} - #{smell_data[:message]}"}
        end
      end
    end

  end
end
