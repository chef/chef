require 'chef/event_dispatch/base'

class Chef
  module EventDispatch

    # == EventDispatch::Dispatcher
    # The Dispatcher handles receiving event data from the sources
    # (Chef::Client, Resources and Providers, etc.) and publishing the data to
    # the registered subscribers.
    class Dispatcher < Base

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
        class_eval(<<-END_OF_METHOD, __FILE__, __LINE__)
          def #{method_name}(*args)
            @subscribers.each {|s| s.#{method_name}(*args)}
          end
        END_OF_METHOD
      end

      (Base.instance_methods - Object.instance_methods).each do |method_name|
        def_forwarding_method(method_name)
      end

    end
  end
end

