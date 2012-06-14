class Chef
  module Formatters
    module ErrorInspectors

      # == APIErrorInspector
      # Wraps exceptions caused by API calls to the server.
      class APIErrorInspector
        attr_reader :exception
        attr_reader :node_name
        attr_reader :config

        def initialize(node_name, exception, config)
          @node_name = node_name
          @exception = exception
          @config = config
        end

        def suspected_cause
          case exception
          when Net::HTTPServerException, Net::HTTPFatalError
            humanize_http_exception
          when Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError
            m=<<-E
There was a network error connecting to the Chef Server:
#{exception.message}

Your chef_server_url may be misconfigured, or the network could be down.
  chef_server_url  "#{server_url}"
E
          when Chef::Exceptions::PrivateKeyMissing
            m=<<-E
Your private key could not be loaded from #{api_key}
Check your configuration file and ensure that your key is readable
E
          else
            "#{e.class.name}: #{e.message}"
          end
        end

        def humanize_http_exception
          response = exception.response
          explanation = case response
          when Net::HTTPUnauthorized
            # TODO: this is where you'd see conflicts b/c of username/clientname stuff
            if clock_skew?
              m=<<-E
Failed to authenticate to the chef server (http 401).
The request failed because your clock has drifted by more than 15 minutes.
Syncing your clock to an NTP Time source should resolve the issue.
E
            else
              m=<<-E
Failed to authenticate to the chef server (http 401).
Server response: '#{format_rest_error}'

One of these configuration options may be incorrect:
  chef_server_url   "#{server_url}"
  node_name         "#{username}"
  client_key        "#{api_key}"

If these settings are correct, your client_key may be invalid.
E
            end
          when Net::HTTPForbidden
            # TODO: we're rescuing errors from Node.find_or_create
            # * could be no write on nodes container
            # * could be no read on the node
            m=<<-E
Your client is not authorized to load the node data (HTTP 403).
Server response: '#{format_rest_error}'

Possible causes:
* Your client (#{username}) may have misconfigured authorization permissions.
E
          when Net::HTTPBadRequest
            # TODO: handle JSON responses from the server.
            m=<<-E
The data in your request was invalid (HTTP 400).
Server response: '#{format_rest_error}'
E
          when Net::HTTPNotFound
            m=<<-E
The server returned a HTTP 404. This usually indicates that your chef_server_url is incorrect.
  chef_server_url "#{server_url}"
E
          when Net::HTTPInternalServerError
            "Chef Server had a fatal error attempting to create the client."
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable
            "The Chef Server is temporarily unavailable"
          else
            exception.message
          end
          explanation
        end

        def username
          config[:node_name]
        end

        def api_key
          config[:client_key]
        end

        def server_url
          config[:chef_server_url]
        end

        def clock_skew?
          exception.response.body =~ /synchronize the clock/i
        end

        # Parses JSON from the error response sent by Chef Server and returns the
        # error message
        #--
        # TODO: this code belongs in Chef::REST
        def format_rest_error
          Array(Chef::JSONCompat.from_json(exception.response.body)["error"]).join('; ')
        rescue Exception
          response.body
        end

      end
      # == RegistrationErrorInspector
      # Wraps exceptions that occur during the client registration process and
      # suggests possible causes.
      class RegistrationErrorInspector
        attr_reader :exception
        attr_reader :node_name
        attr_reader :config

        def initialize(node_name, exception, config)
          @node_name = node_name
          @exception = exception
          @config = config
        end

        def suspected_cause
          case exception
          when Net::HTTPServerException, Net::HTTPFatalError
            humanize_http_exception
          when Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError
            m=<<-E
There was a network error connecting to the Chef Server:
#{exception.message}

Your chef_server_url may be misconfigured, or the network could be down.
  chef_server_url  "#{server_url}"
E
          when Chef::Exceptions::PrivateKeyMissing
            m=<<-E
Your validator private key could not be loaded from #{api_key}
Check your configuration file and ensure that your validator key is readable
E
          else
            "#{e.class.name}: #{e.message}"
          end
        end

        def humanize_http_exception
          response = exception.response
          explanation = case response
          when Net::HTTPUnauthorized
            if clock_skew?
              m=<<-E
Failed to authenticate to the chef server (http 401).
The request failed because your clock has drifted by more than 15 minutes.
Syncing your clock to an NTP Time source should resolve the issue.
E
            else
              m=<<-E
Failed to authenticate to the Chef Server (HTTP 401).

One of these configuration options may be incorrect:
  chef_server_url         "#{server_url}"
  validation_client_name  "#{username}"
  validation_key          "#{api_key}"

If these settings are correct, your validation_key may be invalid.
E
            end
          when Net::HTTPForbidden
            m=<<-E
Your validation client is not authorized to create the client for this node (HTTP 403).

Possible causes:
* There may already be a client named "#{config[:node_name]}"
* Your validation client (#{username}) may have misconfigured authorization permissions.
E
          when Net::HTTPBadRequest
            "The data in your request was invalid"
          when Net::HTTPNotFound
            m=<<-E
The server returned a HTTP 404. This usually indicates that your chef_server_url is incorrect.
  chef_server_url "#{server_url}"
E
          when Net::HTTPInternalServerError
            "Chef Server had a fatal error attempting to create the client."
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable
            "The Chef Server is temporarily unavailable"
          else
            response.message
          end
          explanation
        end

        def username
          #config[:node_name]
          config[:validation_client_name]
        end

        def api_key
          config[:validation_key]
          #config[:client_key]
        end

        def server_url
          config[:chef_server_url]
        end

        # Parses JSON from the error response sent by Chef Server and returns the
        # error message
        #--
        # TODO: this code belongs in Chef::REST
        def format_rest_error
          Array(Chef::JSONCompat.from_json(exception.response.body)["error"]).join('; ')
        rescue Exception
          response.body
        end

      end

    end
  end
end
