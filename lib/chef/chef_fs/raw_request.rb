class Chef
  module ChefFS
    module RawRequest
      def self.raw_json(chef_rest, api_path)
        JSON.parse(raw_request(chef_rest, api_path), :create_additions => false)
      end

      def self.raw_request(chef_rest, api_path)
        api_request(chef_rest, :GET, chef_rest.create_url(api_path), {}, false)
      end

      def self.api_request(chef_rest, method, url, headers={}, data=false)
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
            response_body
          elsif redirect_location = redirected_to(response)
            if [:GET, :HEAD].include?(method)
              chef_rest.follow_redirect do
                api_request(chef_rest, method, chef_rest.create_url(redirect_location))
              end
            else
              raise Exceptions::InvalidRedirect, "#{method} request was redirected from #{url} to #{redirect_location}. Only GET and HEAD support redirects."
            end
          else
            # have to decompress the body before making an exception for it. But the body could be nil.
            response.body.replace(chef_rest.decompress_body(response)) if response.body.respond_to?(:replace)

            if response['content-type'] =~ /json/
              exception = response_body
              msg = "HTTP Request Returned #{response.code} #{response.message}: "
              msg << (exception["error"].respond_to?(:join) ? exception["error"].join(", ") : exception["error"].to_s)
              Chef::Log.info(msg)
            end
            response.error!
          end
        end
      end

      private

      # Copied so that it does not automatically inflate an object
      # This is also used by knife raw_essentials

      ACCEPT_ENCODING = "Accept-Encoding".freeze
      ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3".freeze

      def self.redirected_to(response)
        return nil  unless response.kind_of?(Net::HTTPRedirection)
        # Net::HTTPNotModified is undesired subclass of Net::HTTPRedirection so test for this
        return nil  if response.kind_of?(Net::HTTPNotModified)
        response['location']
      end

      def self.build_headers(chef_rest, method, url, headers={}, json_body=false, raw=false)
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
