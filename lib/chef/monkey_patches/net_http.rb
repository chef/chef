
# Module gets mixed in to Net::HTTP exception classes so we can attach our
# RESTRequest object to them and get the request parameters back out later.
module ChefNetHTTPExceptionExtensions
  attr_accessor :chef_rest_request
end

require "net/http"
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

if Net::HTTP.instance_methods.map { |m| m.to_s }.include?("proxy_uri")
  begin
    # Ruby 2.0 changes the way proxy support is implemented in Net::HTTP.
    # The implementation does not work correctly with IPv6 literals because it
    # concatenates the address into a URI without adding square brackets for
    # IPv6 addresses.
    #
    # If the bug is present, a call to Net::HTTP#proxy_uri when the host is an
    # IPv6 address will fail by creating an invalid URI, like so:
    #
    #    ruby -r'net/http' -e 'Net::HTTP.new("::1", 80).proxy_uri'
    #    /Users/ddeleo/.rbenv/versions/2.0.0-p247/lib/ruby/2.0.0/uri/generic.rb:214:in `initialize': the scheme http does not accept registry part: ::1:80 (or bad hostname?) (URI::InvalidURIError)
    #    	from /Users/ddeleo/.rbenv/versions/2.0.0-p247/lib/ruby/2.0.0/uri/http.rb:84:in `initialize'
    #    	from /Users/ddeleo/.rbenv/versions/2.0.0-p247/lib/ruby/2.0.0/uri/common.rb:214:in `new'
    #    	from /Users/ddeleo/.rbenv/versions/2.0.0-p247/lib/ruby/2.0.0/uri/common.rb:214:in `parse'
    #    	from /Users/ddeleo/.rbenv/versions/2.0.0-p247/lib/ruby/2.0.0/uri/common.rb:747:in `parse'
    #    	from /Users/ddeleo/.rbenv/versions/2.0.0-p247/lib/ruby/2.0.0/uri/common.rb:994:in `URI'
    #    	from /Users/ddeleo/.rbenv/versions/2.0.0-p247/lib/ruby/2.0.0/net/http.rb:1027:in `proxy_uri'
    #    	from -e:1:in `<main>'
    #
    # https://bugs.ruby-lang.org/issues/9129
    #
    # NOTE: This should be fixed in Ruby 2.2.0, and backported to Ruby 2.0 and
    # 2.1 (not yet released so the version/patchlevel required isn't known
    # yet).
    Net::HTTP.new("::1", 80).proxy_uri
  rescue URI::InvalidURIError
    class Net::HTTP

      def proxy_uri # :nodoc:
        ipv6_safe_addr = address.to_s.include?(":") ? "[#{address}]" : address
        @proxy_uri ||= URI("http://#{ipv6_safe_addr}:#{port}").find_proxy
      end

    end
  end
end
