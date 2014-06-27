require 'chef/http'
require 'chef/http/authenticator'
require 'chef/http/decompressor'
require 'chef/http/cookie_manager'
require 'chef/http/validate_content_length'

class Chef
  class HTTP

    class Simple < HTTP

      use Decompressor
      use CookieManager

      # ValidateContentLength should come after Decompressor
      # because the order of middlewares is reversed when handling
      # responses.
      use ValidateContentLength

    end
  end
end
