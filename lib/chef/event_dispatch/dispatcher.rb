require "chef/event_dispatch/base"

class Chef
  module EventDispatch

    # == EventDispatch::Dispatcher
    # The Dispatcher handles receiving event data from the sources
    # (Chef::Client, Resources and Providers, etc.) and publishing the data to
    # the registered subscribers.
    class Dispatcher < Base

      attr_reader :subscribers

      def initialize(*subscribers)
        @subscribers = subscribers
      end

      # Add a new subscriber to the list of registered subscribers
      def register(subscriber)
        @subscribers << subscriber
      end

      # Check to see if we are dispatching to a formatter
      def formatter?
        @subscribers.any? { |s| s.respond_to?(:is_formatter?) && s.is_formatter? }
      end

      ####
      # All messages are unconditionally forwarded to all subscribers, so just
      # define the forwarding in one go:
      #

      def call_subscribers(method_name, *args)
        @subscribers.each do |s|
          # Skip new/unsupported event names.
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
      end

      (Base.instance_methods - Object.instance_methods).each do |method_name|
        class_eval <<-EOM
          def #{method_name}(*args)
            call_subscribers(#{method_name.inspect}, *args)
          end
        EOM
      end

      # Special case deprecation, since it needs to know its caller
      def deprecation(message, location = caller(2..2)[0])
        call_subscribers(:deprecation, message, location)
      end
    end
  end
end
