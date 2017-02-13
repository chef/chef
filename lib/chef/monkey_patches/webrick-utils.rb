require "webrick/utils"

module WEBrick
  module Utils
    ##
    # Creates TCP server sockets bound to +address+:+port+ and returns them.
    #
    # It will create IPV4 and IPV6 sockets on all interfaces.
    #
    # NOTE: We need to monkey patch this method because
    # create_listeners on Windows with Ruby > 2.0.0 does not
    # raise an error if we're already listening on a port.
    #
    def create_listeners(address, port, logger = nil)
      #
      # utils.rb -- Miscellaneous utilities
      #
      # Author: IPR -- Internet Programming with Ruby -- writers
      # Copyright 2001-2016, TAKAHASHI Masayoshi, GOTOU Yuuzou
      # Copyright 2002-2016, Internet Programming with Ruby writers. All rights
      # reserved.
      #
      # $IPR: utils.rb,v 1.10 2003/02/16 22:22:54 gotoyuzo Exp $
      unless port
        raise ArgumentError, "must specify port"
      end
      res = Socket.getaddrinfo(address, port,
                                Socket::AF_UNSPEC,   # address family
                                Socket::SOCK_STREAM, # socket type
                                0,                   # protocol
                                Socket::AI_PASSIVE)  # flag
      last_error = nil
      sockets = []
      res.each do |ai|
        begin
          logger.debug("TCPServer.new(#{ai[3]}, #{port})") if logger
          sock = TCPServer.new(ai[3], port)
          port = sock.addr[1] if port == 0
          Utils.set_close_on_exec(sock)
          sockets << sock
        rescue => ex
          logger.warn("TCPServer Error: #{ex}") if logger
          last_error = ex
        end
      end
      raise last_error if sockets.empty?
      sockets
    end
    module_function :create_listeners
  end
end
