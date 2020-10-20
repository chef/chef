autoload :JSON, 'json'

class Chef
  module Audit
    module Reporter
      class JsonFile
        def initialize(opts)
          @path = opts.fetch(:file)
        end

        def send_report(report)
          File.write(@path, JSON.generate(report))
        end
      end
    end
  end
end
