#
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../knife"

class Chef
  class Knife
    class Raw < Chef::Knife
      banner "knife raw REQUEST_PATH (options)"

      deps do
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
        require "chef/config" unless defined?(Chef::Config)
        require "chef/http" unless defined?(Chef::HTTP)
        require "chef/http/authenticator" unless defined?(Chef::HTTP::Authenticator)
        require "chef/http/cookie_manager" unless defined?(Chef::HTTP::CookieManager)
        require "chef/http/decompressor" unless defined?(Chef::HTTP::Decompressor)
        require "chef/http/json_output" unless defined?(Chef::HTTP::JSONOutput)
      end

      option :method,
        long: "--method METHOD",
        short: "-m METHOD",
        default: "GET",
        description: "Request method (GET, POST, PUT or DELETE). Default: GET."

      option :pretty,
        long: "--[no-]pretty",
        boolean: true,
        default: true,
        description: "Pretty-print JSON output. Default: true."

      option :input,
        long: "--input FILE",
        short: "-i FILE",
        description: "Name of file to use for PUT or POST."

      option :proxy_auth,
        long: "--proxy-auth",
        boolean: true,
        default: false,
        description: "Use webui proxy authentication. Client key must be the webui key."

      # We need a custom HTTP client class here because we don't want to even
      # try to decode the body, in case we get back corrupted JSON or whatnot.
      class RawInputServerAPI < Chef::HTTP
        def initialize(options = {})
          # If making a change here, also update Chef::ServerAPI.
          options[:client_name] ||= Chef::Config[:node_name]
          options[:raw_key] ||= Chef::Config[:client_key_contents]
          options[:signing_key_filename] ||= Chef::Config[:client_key] unless options[:raw_key]
          options[:ssh_agent_signing] ||= Chef::Config[:ssh_agent_signing]
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
            chef_rest = RawInputServerAPI.new(raw_output: true)
            result = chef_rest.request(method, name_args[0], headers, data)
          end
          output result
        rescue Timeout::Error => e
          ui.error "Server timeout"
          exit 1
        rescue Net::HTTPClientException => e
          ui.error "Server responded with error #{e.response.code} \"#{e.response.message}\""
          ui.error "Error Body: #{e.response.body}" if e.response.body && e.response.body != ""
          exit 1
        end
      end

    end # class Raw
  end
end
