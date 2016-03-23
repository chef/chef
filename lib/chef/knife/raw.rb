require "chef/knife"
require "chef/http"

class Chef
  class Knife
    class Raw < Chef::Knife
      banner "knife raw REQUEST_PATH"

      deps do
        require "chef/json_compat"
        require "chef/config"
        require "chef/http"
        require "chef/http/authenticator"
        require "chef/http/cookie_manager"
        require "chef/http/decompressor"
        require "chef/http/json_output"
      end

      option :method,
        :long => "--method METHOD",
        :short => "-m METHOD",
        :default => "GET",
        :description => "Request method (GET, POST, PUT or DELETE). Default: GET"

      option :pretty,
        :long => "--[no-]pretty",
        :boolean => true,
        :default => true,
        :description => "Pretty-print JSON output. Default: true"

      option :input,
        :long => "--input FILE",
        :short => "-i FILE",
        :description => "Name of file to use for PUT or POST"

      option :proxy_auth,
        :long => "--proxy-auth",
        :boolean => true,
        :default => false,
        :description => "Use webui proxy authentication. Client key must be the webui key."

      class RawInputServerAPI < Chef::HTTP
        def initialize(options = {})
          options[:client_name] ||= Chef::Config[:node_name]
          options[:signing_key_filename] ||= Chef::Config[:client_key]
          super(Chef::Config[:chef_server_url], options)
        end
        use Chef::HTTP::JSONOutput
        use Chef::HTTP::CookieManager
        use Chef::HTTP::Decompressor
        use Chef::HTTP::Authenticator
        use Chef::HTTP::RemoteRequestID
      end

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("You must provide the path you want to hit on the server")
          exit(1)
        elsif name_args.length > 1
          show_usage
          ui.fatal("You must specify only a single path")
          exit(1)
        end

        path = name_args[0]
        data = false
        if config[:input]
          data = IO.read(config[:input])
        end
        begin
          method = config[:method].to_sym

          headers = { "Content-Type" => "application/json" }

          if config[:proxy_auth]
            headers["x-ops-request-source"] = "web"
          end

          if config[:pretty]
            chef_rest = RawInputServerAPI.new
            result = chef_rest.request(method, name_args[0], headers, data)
            unless result.is_a?(String)
              result = Chef::JSONCompat.to_json_pretty(result)
            end
          else
            chef_rest = RawInputServerAPI.new(:raw_output => true)
            result = chef_rest.request(method, name_args[0], headers, data)
          end
          output result
        rescue Timeout::Error => e
          ui.error "Server timeout"
          exit 1
        rescue Net::HTTPServerException => e
          ui.error "Server responded with error #{e.response.code} \"#{e.response.message}\""
          ui.error "Error Body: #{e.response.body}" if e.response.body && e.response.body != ""
          exit 1
        end
      end

    end # class Raw
  end
end
