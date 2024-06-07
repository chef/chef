require_relative "file"

module TargetIO
  module TrainCompat
    class IO
      class << self
        def read(path)
          TargetIO::File.read(path)
        end
      end
    end
  end
end
