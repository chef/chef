module MetricFu

  class Saikuro < Generator

    def emit
      options_string = MetricFu.saikuro.inject("") do |options, option|
        option[0] == :input_directory ? options : options + "--#{option.join(' ')} "
      end

      MetricFu.saikuro[:input_directory].each do |input_dir|
        options_string += "--input_directory #{input_dir} "
      end
      sh %{saikuro #{options_string}} do |ok, response|
        unless ok
          puts "Saikuro failed with exit status: #{response.exitstatus}"
          exit 1
        end
      end
    end

    def format_directories
      dirs = MetricFu.saikuro[:input_directory].join(" | ")
      "\"#{dirs}\""
    end

    def analyze
      @files = sort_files(assemble_files)
      @classes = sort_classes(assemble_classes(@files))
      @meths = sort_methods(assemble_methods(@files))
    end

    def to_h
      files = @files.map do |file|
        my_file = file.to_h

        f = file.filepath
        f.gsub!(%r{^#{metric_directory}/}, '')
        f << "/#{file.filename}"

        my_file[:filename] = f
        my_file
      end
      @saikuro_data = {:files => files,
                       :classes => @classes.map {|c| c.to_h},
                       :methods => @meths.map {|m| m.to_h}
                      }
      {:saikuro => @saikuro_data}
    end

    def per_file_info(out)
      @saikuro_data[:files].each do |file_data|
        next if File.extname(file_data[:filename]) == '.erb' || !File.exists?(file_data[:filename])
        begin
          line_numbers = MetricFu::LineNumbers.new(File.open(file_data[:filename], 'r').read)
        rescue StandardError => e
          raise e unless e.message =~ /you shouldn't be able to get here/
          puts "ruby_parser blew up while trying to parse #{file_path}. You won't have method level Saikuro information for this file."
          next
        end

        out[file_data[:filename]] ||= {}
        file_data[:classes].each do |class_data|
          class_data[:methods].each do |method_data|
            line = line_numbers.start_line_for_method(method_data[:name])
            out[file_data[:filename]][line.to_s] ||= []
            out[file_data[:filename]][line.to_s] << {:type => :saikuro,
                                                      :description => "Complexity #{method_data[:complexity]}"}
          end
        end
      end
    end

    private
    def sort_methods(methods)
      methods.sort_by {|method| method.complexity.to_i}.reverse
    end

    def assemble_methods(files)
      methods = []
      files.each do |file|
        file.elements.each do |element|
          element.defs.each do |defn|
            defn.name = "#{element.name}##{defn.name}"
            methods << defn
          end
        end
      end
      methods
    end

    def sort_classes(classes)
      classes.sort_by {|k| k.complexity.to_i}.reverse
    end

    def assemble_classes(files)
      files.map {|f| f.elements}.flatten
    end

    def sort_files(files)
      files.sort_by do |file|
        file.elements.
             max {|a,b| a.complexity.to_i <=> b.complexity.to_i}.
             complexity.to_i
      end.reverse
    end

    def assemble_files
      files = []
      Dir.glob("#{metric_directory}/**/*.html").each do |path|
        if Saikuro::SFile.is_valid_text_file?(path)
          file = Saikuro::SFile.new(path)
          if file
            files << file
          end
        end
      end
      files
    end

  end

  class Saikuro::SFile

    attr_reader :elements

    def initialize(path)
      @path = path
      @file_handle = File.open(@path, "r")
      @elements = []
      get_elements
    ensure
      @file_handle.close if @file_handle
    end

    def self.is_valid_text_file?(path)
      File.open(path, "r") do |f|
        if f.eof? || !f.readline.match(/--/)
          return false
        else
          return true
        end
      end
    end

    def filename
      File.basename(@path, '_cyclo.html')
    end

    def filepath
      File.dirname(@path)
    end

    def to_h
      merge_classes
      {:classes => @elements}
    end

    def get_elements
      begin
        while (line = @file_handle.readline) do
          return [] if line.nil? || line !~ /\S/
          element ||= nil
          if line.match /START/
            unless element.nil?
              @elements << element
              element = nil
            end
            line = @file_handle.readline
            element = Saikuro::ParsingElement.new(line)
          elsif line.match /END/
            @elements << element if element
            element = nil
          else
            element << line if element
          end
        end
      rescue EOFError
        nil
      end
    end


    def merge_classes
      new_elements = []
      get_class_names.each do |target_class|
        elements = @elements.find_all {|el| el.name == target_class }
        complexity = 0
        lines = 0
        defns = []
        elements.each do |el|
          complexity += el.complexity.to_i
          lines += el.lines.to_i
          defns << el.defs
        end

        new_element = {:class_name => target_class,
                       :complexity => complexity,
                       :lines => lines,
                       :methods => defns.flatten.map {|d| d.to_h}}
        new_element[:methods] = new_element[:methods].
                                sort_by {|x| x[:complexity] }.
                                reverse

        new_elements << new_element
      end
      @elements = new_elements if new_elements
    end

    def get_class_names
      class_names = []
      @elements.each do |element|
        unless class_names.include?(element.name)
          class_names << element.name
        end
      end
      class_names
    end

  end

  class Saikuro::ParsingElement
    TYPE_REGEX=/Type:(.*) Name/
    NAME_REGEX=/Name:(.*) Complexity/
    COMPLEXITY_REGEX=/Complexity:(.*) Lines/
    LINES_REGEX=/Lines:(.*)/

    attr_reader :complexity, :lines, :defs, :element_type
    attr_accessor :name

    def initialize(line)
      @line = line
      @element_type = line.match(TYPE_REGEX)[1].strip
      @name = line.match(NAME_REGEX)[1].strip
      @complexity = line.match(COMPLEXITY_REGEX)[1].strip
      @lines = line.match(LINES_REGEX)[1].strip
      @defs = []
    end

    def <<(line)
      @defs << Saikuro::ParsingElement.new(line)
    end

    def to_h
      base = {:name => @name, :complexity => @complexity.to_i, :lines => @lines.to_i}
      unless @defs.empty?
        defs = @defs.map do |my_def|
          my_def = my_def.to_h
          my_def.delete(:defs)
          my_def
        end
        base[:defs] = defs
      end
      return base
    end
  end
end
