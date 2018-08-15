class Chef
  module EventDispatch
    class EventsOutputStream
      # This is a fake stream that connects to events.
      #
      # == Arguments
      # events: the EventDispatch object to send data to (run_context.events)
      # options is a hash with these possible options:
      # - name: a string that identifies the stream to the user. Preferably short.

      def initialize(events, options = {})
        @events = events
        @options = options
        events.stream_opened(self, options)
      end

      attr_reader :options
      attr_reader :events

      def print(str)
        events.stream_output(self, str, options)
      end

      def <<(str)
        events.stream_output(self, str, options)
      end

      def write(str)
        events.stream_output(self, str, options)
      end

      def close
        events.stream_closed(self, options)
      end
    end
  end
end
