require_relative "base"

class Chef
  module EventDispatch

    # == EventDispatch::Dispatcher
    # The Dispatcher handles receiving event data from the sources
    # (Chef::Client, Resources and Providers, etc.) and publishing the data to
    # the registered subscribers.
    class Dispatcher < Base

      attr_reader :subscribers
      attr_reader :event_list

      def initialize(*subscribers)
        @subscribers = subscribers
        @event_list = []
      end

      # Add a new subscriber to the list of registered subscribers
      def register(subscriber)
        subscribers << subscriber
      end

      def unregister(subscriber)
        subscribers.reject! { |x| x == subscriber }
      end

      def enqueue(method_name, *args)
        event_list << [ method_name, *args ]
        process_events_until_done unless @in_call
      end

      (Base.instance_methods - Object.instance_methods).each do |method_name|
        class_eval <<-EOM
          def #{method_name}(*args)
            enqueue(#{method_name.inspect}, *args)
          end
        EOM
      end

      # Special case deprecation, since it needs to know its caller
      def deprecation(message, location = caller(2..2)[0])
        enqueue(:deprecation, message, location)
      end

      # Check to see if we are dispatching to a formatter
      # @api private
      def formatter?
        subscribers.any? { |s| s.respond_to?(:is_formatter?) && s.is_formatter? }
      end

      ####
      # All messages are unconditionally forwarded to all subscribers, so just
      # define the forwarding in one go:
      #

      # @api private
      def call_subscribers(method_name, *args)
        @in_call = true
        subscribers.each do |s|
          # Skip new/unsupported event names
          next if !s.respond_to?(method_name)
          mth = s.method(method_name)
          # Trim arguments to match what the subscriber expects to allow
          # adding new arguments without breaking compat.
          if mth.arity < args.size && mth.arity >= 0
            mth.call(*args.take(mth.arity))
          else
            mth.call(*args)
          end
        end
      ensure
        @in_call = false
      end

      private

      # events are allowed to enqueue chained events, so pop them off until
      # empty, rather than iterating over the list.
      #
      def process_events_until_done
        call_subscribers(*event_list.shift) until event_list.empty?
      end

    end
  end
end
