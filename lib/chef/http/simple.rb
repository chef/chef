require 'chef/http'
require 'chef/http/authenticator'
require 'chef/http/decompressor'


class Chef
  class HTTP

    class Simple < HTTP
      # When we 'use' middleware the first middleware is applied last on requests and
      # first on responses (confusingly).  So validatecontentlength must come before
      # decompressor in order to be applied before decmopressing the response.
      use ValidateContentLength
      use Decompressor
      use CookieManager
    end
  end
end
