
# Module gets mixed in to Net::HTTP exception classes so we can attach our
# RESTRequest object to them and get the request parameters back out later.
module ChefNetHTTPExceptionExtensions
  attr_accessor :chef_rest_request
end

require 'net/http'
module Net
  class HTTPError
    include ChefNetHTTPExceptionExtensions
  end
  class HTTPRetriableError
    include ChefNetHTTPExceptionExtensions
  end
  class HTTPServerException
    include ChefNetHTTPExceptionExtensions
  end
  class HTTPFatalError
    include ChefNetHTTPExceptionExtensions
  end
end
