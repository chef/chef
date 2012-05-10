require 'chef/event_dispatch/base'

class Chef

  # == Chef::Formatters
  # Formatters handle printing output about the progress/status of a chef
  # client run to the user's screen.
  module Formatters

    class UnknownFormatter < StandardError; end

    def self.formatters_by_name
      @formatters_by_name ||= {}
    end

    def self.register(name, formatter)
      formatters_by_name[name.to_s] = formatter
    end

    def self.lookup_by_name(name)
      formatters_by_name[name]
    end

    def self.available_formatters
      formatters_by_name.keys
    end

    #--
    # TODO: is it too clever to be defining new() on a module like this?
    def self.new(name, out, err)
      formatter_class = lookup_by_name(name) or
        raise UnknownFormatter, "No output formatter found for #{name} (available: #{available_formatters.join(', ')})"

      formatter_class.new(out, err)
    end

    # == Formatters::Base
    # Base class that all formatters should inherit from.
    #--
    # TODO: Provide aggregate methods for file load/fail/complete, so
    # implementors can easily do the same thing for all/most file types.
    class Base < EventDispatch::Base

      def self.cli_name(name)
        Chef::Formatters.register(name, self)
      end

      attr_reader :out
      attr_reader :err

      def initialize(out, err)
        out, err = out, err
      end

    end


    # == NullFormatter
    # Formatter that doesn't actually produce any ouput. You can use this to
    # disable the use of output formatters.
    class NullFormatter < Base

      cli_name(:null)

    end

  end
end

