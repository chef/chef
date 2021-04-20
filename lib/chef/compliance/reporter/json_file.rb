require_relative "../../json_compat"

class Chef
  module Compliance
    module Reporter
      class JsonFile
        def initialize(opts)
          @path = opts.fetch(:file)
        end

        def send_report(report)
          FileUtils.mkdir_p(File.dirname(@path), mode: 0700)

          File.write(@path, Chef::JSONCompat.to_json(report))
        end

        def validate_config!
          if @path.nil? || @path.class != String || @path.empty?
            raise "CMPL007: json_file reporter: node['audit']['json_file']['location'] must contain a file path"
          end
        end
      end
    end
  end
end
