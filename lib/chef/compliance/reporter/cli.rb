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

              output << "      #{control[:title]}"
              control[:results].each do |result|
                output << format_result(result)
              end
            end
          end
          output << "\n"
          puts output.join("\n")
        end

        private

        def format_result(result)
          output = []
          found = false
          if result[:status] == 'failed'
            if result[:code_desc]
              found = true
              output << "         \033[31m\xE2\x9D\x8C #{result[:code_desc]}\033[0m"
            end
            if result[:message]
              if found
                result[:message].split(/\n/).reject(&:empty?).each do |m|
                  output << "            \033[31m#{m}\033[0m"
                end
              else
                prefix = "\xE2\x9D\x8C"
                result[:message].split(/\n/).reject(&:empty?).each do |m|
                  output << "         \033[31m#{prefix}#{m}\033[0m"
                  prefix = ''
                end
              end
              found = true
            end
            unless found
              output << "         \033[31m\xE2\x9D\x8C #{result[:status]}\033[0m"
            end
          else
            found = false
            if result[:code_desc]
              found = true
              output << "         \033[32m\xE2\x9C\x94 #{result[:code_desc]}\033[0m"
            end
            unless found
              output << "         \033[32m\xE2\x9C\x94 #{result[:status]}\033[0m"
            end
          end
          output
        end
      end
    end
  end
end
