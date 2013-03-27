class Chef
  module Formatters
    module ErrorInspectors

      # == RegistrationErrorInspector
      # Wraps exceptions that occur during the client registration process and
      # suggests possible causes.
      #--
      # TODO: Lots of duplication with the node_load_error_inspector, just
      # slightly tweaked to talk about validation keys instead of other keys.
      class RegistrationErrorInspector
        attr_reader :exception
        attr_reader :node_name
        attr_reader :config

        def initialize(node_name, exception, config)
          @node_name = node_name
          @exception = exception
          @config = config
        end

        def add_explanation(error_description)
          case exception
          when Net::HTTPServerException, Net::HTTPFatalError
            humanize_http_exception(error_description)
          when Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError
            error_description.section("Network Error:",<<-E)
There was a network error connecting to the Chef Server:
#{exception.message}
E
            error_description.section("Relevant Config Settings:",<<-E)
chef_server_url  "#{server_url}"

If your chef_server_url is correct, your network could be down.
E
          when Chef::Exceptions::PrivateKeyMissing
            error_description.section("Private Key Not Found:",<<-E)
Your private key could not be loaded. If the key file exists, ensure that it is
readable by chef-client.
E
            error_description.section("Relevant Config Settings:",<<-E)
validation_key "#{api_key}"
E
          when Chef::Exceptions::InvalidRedirect
            error_description.section("Invalid Redirect:",<<-E)
Change your server location in client.rb to the server's FQDN to avoid unwanted redirections.
E
          else
            "#{exception.class.name}: #{exception.message}"
          end
        end

        def humanize_http_exception(error_description)
          response = exception.response
          case response
          when Net::HTTPUnauthorized
            if clock_skew?
              error_description.section("Authentication Error:",<<-E)
Failed to authenticate to the chef server (http 401).
The request failed because your clock has drifted by more than 15 minutes.
Syncing your clock to an NTP Time source should resolve the issue.
E
            else
              error_description.section("Authentication Error:",<<-E)
Failed to authenticate to the chef server (http 401).
E

              error_description.section("Server Response:", format_rest_error)
              error_description.section("Relevant Config Settings:",<<-E)
chef_server_url         "#{server_url}"
validation_client_name  "#{username}"
validation_key          "#{api_key}"

If these settings are correct, your validation_key may be invalid.
E
            end
          when Net::HTTPForbidden
            error_description.section("Authorization Error:",<<-E)
Your validation client is not authorized to create the client for this node (HTTP 403).
E
            error_description.section("Possible Causes:",<<-E)
* There may already be a client named "#{config[:node_name]}"
* Your validation client (#{username}) may have misconfigured authorization permissions.
E
          when Net::HTTPBadRequest
            error_description.section("Invalid Request Data:",<<-E)
The data in your request was invalid (HTTP 400).
E
            error_description.section("Server Response:",format_rest_error)
          when Net::HTTPNotFound
            error_description.section("Resource Not Found:",<<-E)
The server returned a HTTP 404. This usually indicates that your chef_server_url is incorrect.
E
            error_description.section("Relevant Config Settings:",<<-E)
chef_server_url "#{server_url}"
E
          when Net::HTTPInternalServerError
            error_description.section("Unknown Server Error:",<<-E)
The server had a fatal error attempting to load the node data.
E
            error_description.section("Server Response:", format_rest_error)
          when Net::HTTPBadGateway, Net::HTTPServiceUnavailable
            error_description.section("Server Unavailable","The Chef Server is temporarily unavailable")
            error_description.section("Server Response:", format_rest_error)
          else
            error_description.section("Unexpected API Request Failure:", format_rest_error)
          end
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
          exception.response.body
        end

      end
    end
  end
end
