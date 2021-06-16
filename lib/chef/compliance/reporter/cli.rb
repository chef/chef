class Chef
  module Compliance
    module Reporter
      class Cli
        def send_report(report)
          # iterate over each profile and control
          output = ["\nCompliance report:"]
          report[:profiles].each do |profile|
            next if profile[:controls].nil?

            output << " * #{profile[:title]}"
            profile[:controls].each do |control|
              next if control[:results].nil?

              output << "#{" " * 6}#{control[:title]}"
              control[:results].each do |result|
                output << format_result(result)
              end
            end
          end
          output << "\n"
          puts output.join("\n")
        end

        def validate_config!
          true
        end

        private

        # pastel.decorate is a lightweight replacement for highline.color
        def pastel
          @pastel ||= begin
            require "pastel" unless defined?(Pastel)
            Pastel.new
          end
        end

        def format_result(result)
          output = []
          found = false
          if result[:status] == "failed"
            if result[:code_desc]
              found = true
              output << pastel.red("#{" " * 9}- #{result[:code_desc]}")
            end
            if result[:message]
              if found
                result[:message].split(/\n/).reject(&:empty?).each do |m|
                  output << pastel.red("#{" " * 12}#{m}")
                end
              else
                result[:message].split(/\n/).reject(&:empty?).each do |m|
                  output << pastel.red("#{" " * 9}#{m}")
                end
              end
              found = true
            end
            unless found
              output << pastel.red("#{" " * 9}- #{result[:status]}")
            end
          else
            found = false
            if result[:code_desc]
              found = true
              output << pastel.green("#{" " * 9}+ #{result[:code_desc]}")
            end
            unless found
              output << pastel.green("#{" " * 9}+ #{result[:status]}")
            end
          end
          output
        end
      end
    end
  end
end
