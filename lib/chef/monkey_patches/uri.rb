# See http://bugs.ruby-lang.org/issues/3788
module URI
  class Generic
    unless method_defined?(:hostname)
      # extract the host part of the URI and unwrap brackets for IPv6 addresses.
      #
      # This method is same as URI::Generic#host except
      # brackets for IPv6 (andn future IP) addresses are removed.
      #
      # u = URI("http://[::1]/bar")
      # p u.hostname      #=> "::1"
      # p u.host          #=> "[::1]"
      #
      def hostname
        v = self.host
        /\A\[(.*)\]\z/ =~ v ? $1 : v
      end

      # set the host part of the URI as the argument with brackets for IPv6 addresses.
      #
      # This method is same as URI::Generic#host= except
      # the argument can be bare IPv6 address.
      #
      # u = URI("http://foo/bar")
      # p u.to_s                  #=> "http://foo/bar"
      # u.hostname = "::1"
      # p u.to_s                  #=> "http://[::1]/bar"
      #
      # If the arugument seems IPv6 address,
      # it is wrapped by brackets.
      #
      def hostname=(v)
        v = "[#{v}]" if /\A\[.*\]\z/ !~ v && /:/ =~ v
        self.host = v
      end
    end
  end
end

