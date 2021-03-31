#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "forwardable" unless defined?(Forwardable)
require "chef/platform/query_helpers" # NOTE - this require doesn't defined any const we can check.
require_relative "generic_presenter"
require "tempfile" unless defined?(Tempfile)

class Chef
  class Knife

    # The User Interaction class used by knife.
    class UI

      extend Forwardable

      attr_reader :stdout
      attr_reader :stderr
      attr_reader :stdin
      attr_reader :config

      attr_reader :presenter

      def_delegator :@presenter, :format_list_for_display
      def_delegator :@presenter, :format_for_display
      def_delegator :@presenter, :format_cookbook_list_for_display

      def initialize(stdout, stderr, stdin, config)
        @stdout, @stderr, @stdin, @config = stdout, stderr, stdin, config
        @presenter = Chef::Knife::Core::GenericPresenter.new(self, config)
      end

      # Creates a new +presenter_class+ object and uses it to format structured
      # data for display. By default, a Chef::Knife::Core::GenericPresenter
      # object is used.
      def use_presenter(presenter_class)
        @presenter = presenter_class.new(self, config)
      end

      def highline
        @highline ||= begin
          require "highline"
          HighLine.new
        end
      end

      # Creates a new object of class TTY::Prompt
      # with interrupt as exit so that it can be terminated with status code.
      def prompt
        @prompt ||= begin
          require "tty-prompt"
          TTY::Prompt.new(interrupt: :exit)
        end
      end

      # pastel.decorate is a lightweight replacement for highline.color
      def pastel
        @pastel ||= begin
          require "pastel" unless defined?(Pastel)
          Pastel.new
        end
      end

      # Prints a message to stdout. Aliased as +info+ for compatibility with
      # the logger API.
      #
      # @param message [String] the text string
      def msg(message)
        stdout.puts message
      rescue Errno::EPIPE => e
        raise e if @config[:verbosity] >= 2

        exit 0
      end

      # Prints a msg to stderr. Used for info, warn, error, and fatal.
      #
      # @param message [String] the text string
      def log(message)
        lines = message.split("\n")
        first_line = lines.shift
        stderr.puts first_line
        # If the message is multiple lines,
        # indent subsequent lines to align with the
        # log type prefix ("ERROR: ", etc)
        unless lines.empty?
          prefix, = first_line.split(":", 2)
          return if prefix.nil?

          prefix_len = prefix.length
          prefix_len -= 9 if color? # prefix includes 9 bytes of color escape sequences
          prefix_len += 2 # include room to align to the ": " following PREFIX
          padding = " " * prefix_len
          lines.each do |line|
            stderr.puts "#{padding}#{line}"
          end
        end
      rescue Errno::EPIPE => e
        raise e if @config[:verbosity] >= 2

        exit 0
      end

      alias :info :log
      alias :err :log

      # Print a Debug
      #
      # @param message [String] the text string
      def debug(message)
        log("#{color("DEBUG:", :blue, :bold)} #{message}")
      end

      # Print a warning message
      #
      # @param message [String] the text string
      def warn(message)
        log("#{color("WARNING:", :yellow, :bold)} #{message}")
      end

      # Print an error message
      #
      # @param message [String] the text string
      def error(message)
        log("#{color("ERROR:", :red, :bold)} #{message}")
      end

      # Print a message describing a fatal error.
      #
      # @param message [String] the text string
      def fatal(message)
        log("#{color("FATAL:", :red, :bold)} #{message}")
      end

      # Print a message describing a fatal error and exit 1
      #
      # @param message [String] the text string
      def fatal!(message)
        fatal(message)
        exit 1
      end

      def color(string, *colors)
        if color?
          pastel.decorate(string, *colors)
        else
          string
        end
      end

      # Should colored output be used? For output to a terminal, this is
      # determined by the value of `config[:color]`. When output is not to a
      # terminal, colored output is never used
      def color?
        Chef::Config[:color] && stdout.tty?
      end

      def ask(*args, **options, &block)
        prompt.ask(*args, **options, &block)
      end

      def list(*args)
        highline.list(*args)
      end

      # Formats +data+ using the configured presenter and outputs the result
      # via +msg+. Formatting can be customized by configuring a different
      # presenter. See +use_presenter+
      def output(data)
        msg @presenter.format(data)
      end

      # Determines if the output format is a data interchange format, i.e.,
      # JSON or YAML
      def interchange?
        @presenter.interchange?
      end

      def ask_question(question, opts = {})
        question += "[#{opts[:default]}] " if opts[:default]

        if opts[:default] && config[:defaults]
          opts[:default]
        else
          stdout.print question
          a = stdin.readline.strip

          if opts[:default]
            a.empty? ? opts[:default] : a
          else
            a
          end
        end
      end

      def pretty_print(data)
        stdout.puts data
      rescue Errno::EPIPE => e
        raise e if @config[:verbosity] >= 2

        exit 0
      end

      # Hash -> Hash
      # Works the same as edit_data but
      # returns a hash rather than a JSON string/Fully inflated object
      def edit_hash(hash)
        raw = edit_data(hash, false)
        Chef::JSONCompat.parse(raw)
      end

      def edit_data(data, parse_output = true, object_class: nil)
        output = Chef::JSONCompat.to_json_pretty(data)
        unless config[:disable_editing]
          Tempfile.open([ "knife-edit-", ".json" ]) do |tf|
            tf.sync = true
            tf.puts output
            tf.close
            raise "Please set EDITOR environment variable. See https://docs.chef.io/knife_setup/ for details." unless system("#{config[:editor]} #{tf.path}")

            output = IO.read(tf.path)
          end
        end

        if parse_output
          if object_class.nil?
            raise ArgumentError, "Please pass in the object class to hydrate or use #edit_hash"
          else
            object_class.from_hash(Chef::JSONCompat.parse(output))
          end
        else
          output
        end
      end

      def edit_object(klass, name)
        object = klass.load(name)

        output = edit_data(object, object_class: klass)

        # Only make the save if the user changed the object.
        #
        # Output JSON for the original (object) and edited (output), then parse
        # them without reconstituting the objects into real classes
        # (create_additions=false). Then, compare the resulting simple objects,
        # which will be Array/Hash/String/etc.
        #
        # We wouldn't have to do these shenanigans if all the editable objects
        # implemented to_hash, or if to_json against a hash returned a string
        # with stable key order.
        object_parsed_again = Chef::JSONCompat.parse(Chef::JSONCompat.to_json(object))
        output_parsed_again = Chef::JSONCompat.parse(Chef::JSONCompat.to_json(output))
        if object_parsed_again != output_parsed_again
          output.save
          msg("Saved #{output}")
        else
          msg("Object unchanged, not saving")
        end
        output(format_for_display(object)) if config[:print_after]
      end

      def confirmation_instructions(default_choice)
        case default_choice
        when true
          "? (Y/n) "
        when false
          "? (y/N) "
        else
          "? (Y/N) "
        end
      end

      # See confirm method for argument information
      def confirm_without_exit(question, append_instructions = true, default_choice = nil)
        return true if config[:yes]

        stdout.print question
        stdout.print confirmation_instructions(default_choice) if append_instructions

        answer = stdin.readline
        answer.chomp!

        case answer
        when "Y", "y"
          true
        when "N", "n"
          msg("You said no, so I'm done here.")
          false
        when ""
          unless default_choice.nil?
            default_choice
          else
            msg("I have no idea what to do with '#{answer}'")
            msg("Just say Y or N, please.")
            confirm_without_exit(question, append_instructions, default_choice)
          end
        else
          msg("I have no idea what to do with '#{answer}'")
          msg("Just say Y or N, please.")
          confirm_without_exit(question, append_instructions, default_choice)
        end
      end

      #
      # Not the ideal signature for a function but we need to stick with this
      # for now until we get a chance to break our API in Chef 12.
      #
      # question => Question to print  before asking for confirmation
      # append_instructions => Should print '? (Y/N)' as instructions
      # default_choice => Set to true for 'Y', and false for 'N' as default answer
      #
      def confirm(question, append_instructions = true, default_choice = nil)
        unless confirm_without_exit(question, append_instructions, default_choice)
          exit 3
        end
        true
      end

    end
  end
end
