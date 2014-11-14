require 'rspec/core'

class Chef
  class Audit
    class RspecFormatter < RSpec::Core::Formatters::DocumentationFormatter
      RSpec::Core::Formatters.register self, :close

      # @api public
      #
      # Invoked at the very end, `close` allows the formatter to clean
      # up resources, e.g. open streams, etc.
      #
      # @param _notification [NullNotification] (Ignored)
      def close(_notification)
        # Normally Rspec closes the streams it's given. We don't want it for Chef.
      end
    end
  end
end
