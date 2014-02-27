require 'chef/http'
require 'chef/http/authenticator'
require 'chef/http/decompressor'


class Chef
  class HTTP

    class Simple < HTTP

      use Decompressor
      use CookieManager

    end
  end
end
