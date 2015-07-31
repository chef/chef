require 'chef/event_dispatch/base'

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

      ####
      # All messages are unconditionally forwarded to all subscribers, so just
      # define the forwarding in one go:
      #

      # Define a method that will be forwarded to all
      def self.def_forwarding_method(method_name)
        define_method(method_name) do |*args|
          @subscribers.each do |s|
            # Skip new/unsupported event names.
            if s.respond_to?(method_name)
              mth = s.method(method_name)
              # Anything with a *args is arity -1, so use all arguments.
              arity = mth.arity < 0 ? args.length : mth.arity
              # Trim arguments to match what the subscriber expects to allow
              # adding new arguments without breaking compat.
              mth.call(*args.take(arity))
            end
          end
        end
      end

      (Base.instance_methods - Object.instance_methods).each do |method_name|
        def_forwarding_method(method_name)
      end

    end
  end
end

