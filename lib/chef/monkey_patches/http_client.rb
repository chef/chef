
module HTTPClient
  # Monkey patch to handle wildcard proxy
  # there is an outstanding PR for a year on http_client
  # see: https://github.com/nahi/httpclient/pull/400
  def no_proxy=(no_proxy)
    @no_proxy = no_proxy
    @no_proxy_regexps.clear
    if @no_proxy
      @no_proxy.scan(/([^\s:,]+)(?::(\d+))?/) do |host, port|
        if host[0] == ?.
          regexp = /#{Regexp.quote(host)}\z/i
        else
          regexp = /(\A|\.)#{Regexp.quote(host).gsub('\*', '.+')}\z/i
        end
        @no_proxy_regexps << [regexp, port]
      end
    end
    reset_all
  end
end
