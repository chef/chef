require "kitchen"
require "csv"

module Kitchen
  module TestCsvFormatter
    class Reporter < Kitchen::Logger::BaseReporter
      def initialize(stdout: $stdout, **opts)
        super(**opts)
        @stdout = stdout
        @test_results = []
      end

      def record_test_result(suite, platform, test_result)
        file_name = suite.name
        test_name = test_result.source_location&.first || "unknown"
        
        @test_results << [
          "Kitchen Test",
          test_name,
          "#{suite.name} - #{test_result.description}"
        ]
      end

      def write_report
        @stdout.puts "\nKitchen Test Execution Report"
        @stdout.puts "Category,File,Test Name"
        
        @test_results.sort.each do |result|
          @stdout.puts result.join(",")
        end
      end
    end
  end
end