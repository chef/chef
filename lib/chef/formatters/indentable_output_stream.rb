class Chef
  module Formatters
    # Handles basic indentation and colorization tasks
    class IndentableOutputStream

      attr_reader :out
      attr_reader :err
      attr_accessor :indent
      attr_reader :line_started
      attr_accessor :current_stream
      attr_reader :semaphore

      def initialize(out, err)
        @out, @err = out, err
        @indent = 0
        @line_started = false
        @semaphore = Mutex.new
      end

      def highline
        @highline ||= begin
          require "highline"
          HighLine.new
        end
      end

      # Print text.  This will start a new line and indent if necessary
      # but will not terminate the line (future print and puts statements
      # will start off where this print left off).
      def color(string, *args)
        print(string, from_args(args))
      end

      # Print the start of a new line.  This will terminate any existing lines and
      # cause indentation but will not move to the next line yet (future 'print'
      # and 'puts' statements will stay on this line).
      def start_line(string, *args)
        print(string, from_args(args, :start_line => true))
      end

      # Print a line.  This will continue from the last start_line or print,
      # or start a new line and indent if necessary.
      def puts(string, *args)
        print(string, from_args(args, :end_line => true))
      end

      # Print an entire line from start to end.  This will terminate any existing
      # lines and cause indentation.
      def puts_line(string, *args)
        print(string, from_args(args, :start_line => true, :end_line => true))
      end

      # Print a raw chunk
      def <<(obj)
        print(obj)
      end

      # Print a string.
      #
      # == Arguments
      # string: string to print.
      # options: a hash with these possible options:
      # - :stream => OBJ: unique identifier for a stream. If two prints have
      #           different streams, they will print on separate lines.
      #           Otherwise, they will stay together.
      # - :start_line => BOOLEAN: if true, print will begin on a blank (indented) line.
      # - :end_line => BOOLEAN: if true, current line will be ended.
      # - :name => STRING: a name to prefix in front of a stream. It will be printed
      #           once (with the first line of the stream) and subsequent lines
      #           will be indented to match.
      #
      # == Alternative
      #
      # You may also call print('string', :red) (a list of colors a la Highline.color)
      def print(string, *args)
        options = from_args(args)

        # Make sure each line stays a unit even with threads sending output
        semaphore.synchronize do
          if should_start_line?(options)
            move_to_next_line
          end

          print_string(string, options)

          if should_end_line?(options)
            move_to_next_line
          end
        end
      end

      private

      def should_start_line?(options)
        options[:start_line] || @current_stream != options[:stream]
      end

      def should_end_line?(options)
        options[:end_line] && @line_started
      end

      def from_args(colors, merge_options = {})
        if colors.size == 1 && colors[0].kind_of?(Hash)
          merge_options.merge(colors[0])
        else
          merge_options.merge({ :colors => colors })
        end
      end

      def print_string(string, options)
        if string.empty?
          if options[:end_line]
            print_line("", options)
          end
        else
          string.lines.each do |line|
            print_line(line, options)
          end
        end
      end

      def print_line(line, options)
        indent_line(options)

        # Note that the next line will need to be started
        if line[-1..-1] == "\n"
          @line_started = false
        end

        if Chef::Config[:color] && options[:colors]
          @out.print highline.color(line, *options[:colors])
        else
          @out.print line
        end
      end

      def move_to_next_line
        if @line_started
          @out.puts ""
          @line_started = false
        end
      end

      def indent_line(options)
        if !@line_started

          # Print indents.  If there is a stream name, either print it (if we're
          # switching streams) or print enough blanks to match
          # the indents.
          if options[:name]
            if @current_stream != options[:stream]
              @out.print "#{(' ' * indent)}[#{options[:name]}] "
            else
              @out.print " " * (indent + 3 + options[:name].size)
            end
          else
            # Otherwise, just print indents.
            @out.print " " * indent
          end

          if @current_stream != options[:stream]
            @current_stream = options[:stream]
          end

          @line_started = true
        end
      end
    end
  end
end
