require 'json'

class Chef
  class Knife
    class Raw < Chef::Knife
      banner "knife raw REQUEST_PATH"

      option :method,
        :long => '--method METHOD',
        :short => '-m METHOD',
        :default => "GET",
        :description => "Request method (GET, POST, PUT or DELETE)"

      option :pretty,
        :long => '--[no-]pretty',
        :boolean => true,
        :default => true,
        :description => "Pretty-print JSON output"

      option :input,
        :long => '--input FILE',
        :short => '-i FILE',
        :description => "Name of file to use for PUT or POST"

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("You must provide the path you want to hit on the server")
          exit(1)
        elsif name_args.length > 1
          show_usage
          ui.fatal("Only one path accepted for knife raw")
          exit(1)
        end

        path = name_args[0]
        data = false
        if config[:input]
          data = IO.read(config[:input])
        end
        chef_rest = Chef::REST.new(Chef::Config[:chef_server_url])
        puts api_request(chef_rest, config[:method].to_sym, chef_rest.create_url(name_args[0]), {}, data)
      end

      ACCEPT_ENCODING = "Accept-Encoding".freeze
      ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3".freeze

      def redirected_to(response)
        return nil  unless response.kind_of?(Net::HTTPRedirection)
        # Net::HTTPNotModified is undesired subclass of Net::HTTPRedirection so test for this
        return nil  if response.kind_of?(Net::HTTPNotModified)
        response['location']
      end

      def api_request(chef_rest, method, url, headers={}, data=false)
        json_body = data
#        json_body = data ? Chef::JSONCompat.to_json(data) : nil
        # Force encoding to binary to fix SSL related EOFErrors
        # cf. http://tickets.opscode.com/browse/CHEF-2363
        # http://redmine.ruby-lang.org/issues/5233
#        json_body.force_encoding(Encoding::BINARY) if json_body.respond_to?(:force_encoding)
        headers = build_headers(chef_rest, method, url, headers, json_body)

        chef_rest.retriable_rest_request(method, url, json_body, headers) do |rest_request|
          response = rest_request.call {|r| r.read_body}

          response_body = chef_rest.decompress_body(response)

          if response.kind_of?(Net::HTTPSuccess)
            if config[:pretty] && response['content-type'] =~ /json/
              JSON.pretty_generate(JSON.parse(response_body, :create_additions => false))
            else
              response_body
            end
          elsif redirect_location = redirected_to(response)
            raise "Redirected to #{create_url(redirect_location)}"
            follow_redirect {api_request(:GET, create_url(redirect_location))}
          else
            # have to decompress the body before making an exception for it. But the body could be nil.
            response.body.replace(chef_rest.decompress_body(response)) if response.body.respond_to?(:replace)

            if response['content-type'] =~ /json/
              exception = response_body
              msg = "HTTP Request Returned #{response.code} #{response.message}: "
              msg << (exception["error"].respond_to?(:join) ? exception["error"].join(", ") : exception["error"].to_s)
              Chef::Log.info(msg)
            end
            puts response.body
            response.error!
          end
        end
      end

      def build_headers(chef_rest, method, url, headers={}, json_body=false, raw=false)
#        headers                 = @default_headers.merge(headers)
        #headers['Accept']       = "application/json" unless raw
        headers['Accept']       = "application/json" unless raw
        headers["Content-Type"] = 'application/json' if json_body
        headers['Content-Length'] = json_body.bytesize.to_s if json_body
        headers[Chef::REST::RESTRequest::ACCEPT_ENCODING] = Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE
        headers.merge!(chef_rest.authentication_headers(method, url, json_body)) if chef_rest.sign_requests?
        headers.merge!(Chef::Config[:custom_http_headers]) if Chef::Config[:custom_http_headers]
        headers
      end
    end
  end
end

