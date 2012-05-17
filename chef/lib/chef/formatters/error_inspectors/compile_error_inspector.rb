class Chef
  module Formatters
    module ErrorInspectors

      # == CompileErrorInspector
      # Wraps exceptions that occur during the compile phase of a Chef run and
      # tries to find the code responsible for the error.
      class CompileErrorInspector

        attr_reader :path
        attr_reader :exception

        def initialize(path, exception)
          @path, @exception = path, exception
        end

        def context
          context_lines = ""
          Range.new(display_lower_bound, display_upper_bound).each do |i|
            line_nr = (i + 1).to_s.rjust(3)
            indicator = (i + 1) == culprit_line ? ">> " : ":  "
            context_lines << "#{line_nr}#{indicator}#{file_lines[i]}"
          end
          context_lines
        end

        def display_lower_bound
          lower = (culprit_line - 8)
          lower = 0 if lower < 0
          lower
        end

        def display_upper_bound
          upper = (culprit_line + 8)
          upper = file_lines.size if upper > file_lines.size
          upper
        end

        def file_lines
          @file_lines ||= IO.readlines(path)
        end

        def culprit_backtrace_entry
          @culprit_backtrace_entry ||= exception.backtrace.find {|line| line =~ /^#{@path}/ }
        end

        def culprit_line
          @culprit_line ||= culprit_backtrace_entry[/^#{@path}:([\d]+)/,1].to_i
        end

        def filtered_bt
          exception.backtrace.select {|l| l =~ /^#{Chef::Config.file_cache_path}/ }
        end

      end

    end
  end
end
