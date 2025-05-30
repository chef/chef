require "rspec/core/formatters/base_formatter"
require "csv"
require "fileutils"

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
    # Ensure pkg directory exists
    FileUtils.mkdir_p("pkg")
    
    # Generate unique identifier using timestamp and process id
    unique_id = "#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{Process.pid}"
    csv_filename = "pkg/test_report_#{unique_id}.csv"
    
    # Write to both console and file
    write_report(output)
    
    # Write to CSV file
    CSV.open(csv_filename, "w") do |csv|
      csv << ["Category", "File", "Test Name"]
      @test_results.sort.each do |result|
        csv << result
      end
    end
  end

  private

  def write_report(output_target)
    output_target.puts "\nTest Execution Report"
    output_target.puts "Category,File,Test Name"
    
    @test_results.sort.each do |result|
      output_target.puts result.join(",")
    end
  end

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