require "rspec/core/formatters/base_formatter"
require "csv"

class CsvReportFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self, :example_passed, :example_failed, :close

  def initialize(output)
    super
    @test_results = []
  end

  def example_passed(notification)
    store_example(notification.example)
  end

  def example_failed(notification)
    store_example(notification.example)
  end

  def close(_notification)
    output.puts "\nTest Execution Report"
    output.puts "Category,File,Test Name"
    
    @test_results.sort.each do |result|
      output.puts result.join(",")
    end
  end

  private

  def store_example(example)
    file_path = example.metadata[:file_path]
    relative_path = file_path.sub("#{Dir.pwd}/", "")
    category = relative_path.match(/spec\/(.*?)(?:\/|$)/)[1] || "Uncategorized"
    
    # Build full test description from nested contexts/describes
    full_description = example.metadata[:full_description]
    
    # Escape any commas in the description to preserve CSV format
    escaped_description = full_description.gsub(",", "\\,")
    
    @test_results << [
      category,
      relative_path,
      escaped_description
    ]
  end
end