class Chef
  module Formatters
    module ErrorInspectors

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
            ui.error "#{e.class.name}: #{e.message}"
          end
        end

        def humanize_http_exception
          response = exception.response
          explanation = case response
          when Net::HTTPUnauthorized
            # TODO: generate a different message for time skew error
            m=<<-E
Failed to authenticate to the Chef Server (HTTP 401).

One of these configuration options may be incorrect:
  chef_server_url         "#{server_url}"
  validation_client_name  "#{username}"
  validation_key          "#{api_key}"

If these settings are correct, your validation_key may be invalid.
E
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
