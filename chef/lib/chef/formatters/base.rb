require 'chef/event_dispatch/base'
require 'chef/formatters/error_inspectors'

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

    def self.by_name(name)
      formatters_by_name[name]
    end

    def self.available_formatters
      formatters_by_name.keys
    end

    #--
    # TODO: is it too clever to be defining new() on a module like this?
    def self.new(name, out, err)
      formatter_class = by_name(name) or
        raise UnknownFormatter, "No output formatter found for #{name} (available: #{available_formatters.join(', ')})"

      formatter_class.new(out, err)
    end

    # == Formatters::Base
    # Base class that all formatters should inherit from.
    class Base < EventDispatch::Base

      def self.cli_name(name)
        Chef::Formatters.register(name, self)
      end

      attr_reader :out
      attr_reader :err

      def initialize(out, err)
        out, err = out, err
      end

      def highlight_error
        puts "\n"
        puts "-" * 80
        yield
        puts "-" * 80
      end

      # Failed to register this client with the server.
      def registration_failed(node_name, exception, config)
        error_inspector = ErrorInspectors::RegistrationErrorInspector.new(node_name, exception, config)
        highlight_error do
          puts "Chef encountered an error attempting to create the client \"#{node_name}\""
          puts "\n"
          puts error_inspector.suspected_cause
        end
      end

      def node_load_failed(node_name, exception, config)
        error_inspector = ErrorInspectors::APIErrorInspector.new(node_name, exception, config)
        highlight_error do
          puts "Chef encountered an error attempting to load the node data for \"#{node_name}\""
          puts "\n"
          puts error_inspector.suspected_cause
        end
      end

      # Generic callback for any attribute/library/lwrp/recipe file in a
      # cookbook getting loaded. The per-filetype callbacks for file load are
      # overriden so that they call this instead. This means that a subclass of
      # Formatters::Base can implement #file_loaded to do the same thing for
      # every kind of file that Chef loads from a recipe instead of
      # implementing all the per-filetype callbacks.
      def file_loaded(path)
      end

      # Generic callback for any attribute/library/lwrp/recipe file throwing an
      # exception when loaded. Default behavior is to use CompileErrorInspector
      # to print contextual info about the failure.
      def file_load_failed(path, exception)
        wrapped_err = ErrorInspectors::CompileErrorInspector.new(path, exception)
        highlight_error do
          puts "Error compiling #{path}:"
          puts exception.to_s
          puts "\n"
          puts "Cookbook trace:"
          wrapped_err.filtered_bt.each do |bt_line|
            puts "  #{bt_line}"
          end
          puts "\n"
          puts "Most likely caused here:"
          puts wrapped_err.context
          puts "\n"
        end
      end

      # Delegates to #file_loaded
      def library_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def library_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def lwrp_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def lwrp_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def attribute_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def attribute_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def definition_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def definition_file_load_failed(path, exception)
        file_load_failed(path, exception)
      end

      # Delegates to #file_loaded
      def recipe_file_loaded(path)
        file_loaded(path)
      end

      # Delegates to #file_load_failed
      def recipe_file_load_failed(path, exception)
        file_load_failed(path, exception)
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

