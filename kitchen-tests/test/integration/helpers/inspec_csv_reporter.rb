require "inspec"

module InspecPlugins
  module CsvReporter
    class Reporter < Inspec.plugin(2, :reporter)
      def render
        output.puts "\nKitchen Test Report"
        output.puts "Category,File,Test Name"
        
        run_data.controls.each do |control|
          output.puts [
            "Kitchen Test",
            control.source_location&.split("/")&.last || "unknown",
            "#{control.id} - #{control.title}".gsub(",", "\\,")
          ].join(",")
        end
      end
    end
  end
end