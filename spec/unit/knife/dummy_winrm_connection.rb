module Dummy
  class WinRMTransport
    attr_reader :httpcli

    def initialize
      @httpcli = HTTPClient.new
    end
  end

  class Connection
    attr_reader :transport
    attr_accessor :logger

    def initialize
      @transport = WinRMTransport.new
    end

    def shell; end
  end
end
