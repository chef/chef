#
# Author:: Steven Murawski (<smurawski@chef.io>)
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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
require_relative "winrm_knife_base"
require_relative "wsman_endpoint"

class Chef
  class Knife
    class WsmanTest < Knife

      include Chef::Knife::WinrmCommandSharedFunctions

      deps do
        require "httpclient"
        require_relative "../search/query"
      end

      banner "knife wsman test QUERY (options)"

      def run
        # pass a dummy password to avoid prompt for password
        # but it does nothing
        @config[:winrm_password] = "cute_little_kittens"

        configure_session
        verify_wsman_accessiblity_for_nodes
      end

      private

      def verify_wsman_accessiblity_for_nodes
        error_count = 0
        @winrm_sessions.each do |item|
          Chef::Log.debug("checking for WSMAN availability at #{item.endpoint}")

          ssl_error = nil
          begin
            response = post_identity_request(item.endpoint)
            ui.msg "Connected successfully to #{item.host} at #{item.endpoint}."
          rescue Exception => err
          end

          output_object = parse_response(item, response)
          output_object.error_message += "\r\nError returned from endpoint: #{err.message}" if err

          unless output_object.error_message.nil?
            ui.warn "Failed to connect to #{item.host} at #{item.endpoint}."
            if err.is_a?(OpenSSL::SSL::SSLError)
              ui.warn "Failure due to an issue with SSL; likely cause would be unsuccessful certificate verification."
              ui.warn "Either ensure your certificate is valid or use '--winrm-ssl-verify-mode verify_none' to ignore verification failures."
            end
            error_count += 1
          end

          if config[:verbosity] >= 1
            output(output_object)
          end
        end
        if error_count > 0
          ui.error "Failed to connect to #{error_count} nodes."
          exit 1
        end
      end

      def post_identity_request(endpoint)
        xml = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><s:Header/><s:Body><wsmid:Identify/></s:Body></s:Envelope>'
        header = {
          "WSMANIDENTIFY" => "unauthenticated",
          "Content-Type" => "application/soap+xml; charset=UTF-8",
        }

        client = HTTPClient.new
        Chef::HTTP::DefaultSSLPolicy.new(client.ssl_config).set_custom_certs
        client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE if no_ssl_peer_verification?
        client.post(endpoint, xml, header)
      end

      def parse_response(node, response)
        output_object = Chef::Knife::WsmanEndpoint.new(node.host, node.port, node.endpoint)
        output_object.response_status_code = response.status_code unless response.nil?

        if response.nil? || response.status_code != 200
          output_object.error_message = "No valid WSMan endoint listening at #{node.endpoint}."
        else
          doc = REXML::Document.new(response.body)
          output_object.protocol_version = search_xpath(doc, "//wsmid:ProtocolVersion")
          output_object.product_version  = search_xpath(doc, "//wsmid:ProductVersion")
          output_object.product_vendor = search_xpath(doc, "//wsmid:ProductVendor")
          if output_object.protocol_version.to_s.strip.length == 0
            output_object.error_message = "Endpoint #{node.endpoint} on #{node.host} does not appear to be a WSMAN endpoint. Response body was #{response.body}"
          end
        end
        output_object
      end

      def search_xpath(document, property_name)
        result = REXML::XPath.match(document, property_name)
        result[0].nil? ? "" : result[0].text
      end
    end
  end
end
