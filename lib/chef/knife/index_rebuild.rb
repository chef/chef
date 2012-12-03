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
        api_version_check
        nag
        output rest.post_rest("/search/reindex", {})
      end

      # Attempting to run 'knife index rebuild' on a Chef 11 (or
      # above) server is an error, as that functionality now exists as
      # a server-side utility.  If such a request is made, we print
      # out a helpful message to the user with further instructions,
      # based on the server they are interacting with.
      def api_version_check
        # Since we don't yet have any endpoints that implement an
        # OPTIONS handler, we need to get our version header
        # information in a more roundabout way.  We'll try to query
        # for a node we know won't exist; the 404 response that comes
        # back will give us what we want
        dummy_node = "knife_index_rebuild_test_#{rand(1000000)}"
        rest.get_rest("/nodes/#{dummy_node}")
      rescue Net::HTTPServerException => exception
        r = exception.response
        
        case r
        when Net::HTTPNotFound
          
          api_info = parse_api_info(r)
          version = api_info["version"]
          
          # version should always be present if we're on Chef 11+.  If
          # it's nil, we're on an earlier version which will still have
          # a functional index rebuilding API endpoint, so we'll just
          # exit.
          if version
            if parse_major(version) >= 11
              puts
              puts "Sorry, but rebuilding the index is not available via knife for #{server_type(api_info)}s version 11.0.0 and above."
              puts "Instead, run the '#{ctl_command(api_info)} reindex' command on the server itself."
              exit 1
            end
            # This should never execute, though, since no prior servers have API info headers
            raise "Unexpected x-ops-api-info header information: version #{version} is < 11.0.0"
          end        
        else
          puts "Unexpected exception when checking server API version"
          raise exception
        end
      end

      def nag
        unless config[:yes]
          puts
          puts "NOTICE: 'knife index rebuild' has been removed for Chef 11+ servers.  It will continue to work for prior versions, however."
          puts
          yea_or_nay = ask_question("This operation is destructive. Rebuilding the index may take some time. You sure? (yes/no): ")
          unless yea_or_nay =~ /^y/i
            puts "aborting"
            exit 7
          end
        end
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

      # Given a semantic version string (e.g., +"1.0.0"+), return the
      # major version number as an integer.
      def parse_major(semver)
        semver.split(".").first.to_i
      end

    end
  end
end
