# frozen_string_literal: true
require_relative "base"
class Chef
  class Telemetry
    class Null < Base
      def run_starting(_opts); end
      def run_ending(_opts); end
    end
  end
end
