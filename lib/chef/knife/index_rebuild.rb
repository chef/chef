#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

require 'chef/knife'

class Chef
  class Knife
    class IndexRebuild < Knife

      banner "knife index rebuild (options)"
      option :yes,
        :short        => "-y",
        :long         => "--yes",
        :boolean      => true,
        :description  => "don't bother to ask if I'm sure"

      def run
        api_info = grab_api_info

        if unsupported_version?(api_info)
          unsupported_server_message(api_info)
          exit 1
        else
          deprecated_server_message
          nag
          output rest.post_rest("/search/reindex", {})
        end
        
      end

      def grab_api_info
        # Since we don't yet have any endpoints that implement an
        # OPTIONS handler, we need to get our version header
        # information in a more roundabout way.  We'll try to query
        # for a node we know won't exist; the 404 response that comes
        # back will give us what we want
        dummy_node = "knife_index_rebuild_test_#{rand(1000000)}"
        rest.get_rest("/nodes/#{dummy_node}")
      rescue Net::HTTPServerException => exception
        r = exception.response
        parse_api_info(r)
      end
      
      # Only Chef 11+ servers will have version information in their
      # headers, and only those servers will lack an API endpoint for
      # index rebuilding.
      def unsupported_version?(api_info)
        !!api_info["version"]
      end

      def unsupported_server_message(api_info)
        ui.error("Rebuilding the index is not available via knife for #{server_type(api_info)}s version 11.0.0 and above.")
        ui.info("Instead, run the '#{ctl_command(api_info)} reindex' command on the server itself.")
      end

      def deprecated_server_message
        ui.warn("'knife index rebuild' has been removed for Chef 11+ servers.  It will continue to work for prior versions, however.")
      end

      def nag
        ui.info("This operation is destructive.  Rebuilding the index may take some time.")
        ui.confirm("Continue")
      end

      # Chef 11 (and above) servers return various pieces of
      # information about the server in an +x-ops-api-info+ header.
      # This is a +;+ delimited string of key / value pairs, separated
      # by +=+.
      #
      # Given a Net::HTTPResponse object, this method extracts this
      # information (if present), and returns it as a hash.  If no
      # such header is found, an empty hash is returned.
      def parse_api_info(response)
        value = response["x-ops-api-info"]
        if value
          kv = value.split(";")
          kv.inject({}) do |acc, pair|
            k, v = pair.split("=")
            acc[k] = v
            acc
          end
        else
          {}
        end
      end

      # Given an API info hash (see +#parse_api_info(response)+),
      # return a string describing the kind of server we're
      # interacting with (based on the +flavor+ field)
      def server_type(api_info)
        case api_info["flavor"]
        when "osc"
          "Open Source Chef Server"
        when "opc"
          "Private Chef Server"
        else
          # Generic fallback
          "Chef Server"
        end
      end

      # Given an API info hash (see +#parse_api_info(response)+),
      # return the name of the "server-ctl" command for the kind of
      # server we're interacting with (based on the +flavor+ field)
      def ctl_command(api_info)
        case api_info["flavor"]
        when "osc"
          "chef-server-ctl"
        when "opc"
          "private-chef-ctl"
        else
          # Generic fallback
          "chef-server-ctl"
        end
      end

    end
  end
end
