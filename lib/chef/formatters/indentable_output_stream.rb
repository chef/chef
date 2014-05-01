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
          require 'highline'
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
          # If we aren't printing to the same stream, move to the next line
          # and print the stream header (if any)
          if @current_stream != options[:stream]
            @current_stream = options[:stream]
            if @line_started
              @out.puts ''
            end
            if options[:name]
              @out.print "#{(' ' * indent)}[#{options[:name]}] "
            else
              @out.print ' ' * indent
            end
            @line_started = true

          # if start_line is true, move to the next line.
          elsif options[:start_line]
            if @line_started
              @out.puts ''
              @line_started = false
            end
          end

          # Split the output by line and indent each
          printed_anything = false
          string.lines.each do |line|
            printed_anything = true
            print_line(line, options)
          end

          if options[:end_line]
            # If we're supposed to end the line, and the string did not end with
            # \n, then we end the line.
            if @line_started
              @out.puts ''
              @line_started = false
            elsif !printed_anything
              if options[:name]
                @out.puts ' ' * (indent + 3 + options[:name].size)
              else
                @out.puts ' ' * indent
              end
            end
          end
        end
      end

      private

      def from_args(colors, merge_options = {})
        if colors.size == 1 && colors[0].kind_of?(Hash)
          merge_options.merge(colors[0])
        else
          merge_options.merge({ :colors => colors })
        end
      end

      def print_line(line, options)
        # Start the line with indent if it is not started
        if !@line_started
          if options[:name]
            @out.print ' ' * (indent + 3 + options[:name].size)
          else
            @out.print ' ' * indent
          end
          @line_started = true
        end
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
    end
  end
end
