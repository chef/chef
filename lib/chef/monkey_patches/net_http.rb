
# Module gets mixed in to Net::HTTP exception classes so we can attach our
# RESTRequest object to them and get the request parameters back out later.
module ChefNetHTTPExceptionExtensions
  attr_accessor :chef_rest_request
end

require "net/http" unless defined?(Net::HTTP)
module Net
  class HTTPError < Net::ProtocolError
    include ChefNetHTTPExceptionExtensions
  end
  class HTTPRetriableError < Net::ProtoRetriableError
    include ChefNetHTTPExceptionExtensions
  end
  class HTTPClientException < Net::ProtoServerError
    include ChefNetHTTPExceptionExtensions
  end
  class HTTPFatalError < Net::ProtoFatalError
    include ChefNetHTTPExceptionExtensions
  end
end
