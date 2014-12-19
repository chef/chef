#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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


require 'chef/config'
require 'chef/exceptions'
require 'chef/rest'

require 'uri'

class Chef
  class Search
    class Query

      attr_accessor :rest

      def initialize(url=nil)
        @rest = Chef::REST.new(url || Chef::Config[:chef_server_url])
      end

      # Backwards compatability for cookbooks.
      # This can be removed in Chef > 12.
      def partial_search(type, query="*:*", *args, &block)
        Chef::Log.warn(<<-WARNDEP)
DEPRECATED: The 'partial_search' API is deprecated and will be removed in
future releases. Please use 'search' with a :filter_result argument to get
partial search data.
WARNDEP

        # Users can pass either a hash or a list of arguments.
        if args.length == 1 && args.first.is_a?(Hash)
          args_h = args.first
          rows = args_h[:rows]
          start = args_h[:start]
          sort = args_h[:sort]
          keys = args_h[:keys]
        else
          rows = args[0]
          start = args[1]
          sort = args[2]
          keys = args[3]
        end

        # Set defaults. Otherwise, search may receive nil arguments.
        # We could pass nil arguments along to search, assuming that default values will be
        # filled in later. However, since this is a deprecated method, it will be easier to
        # do a little more work here than to change search in the future.
        rows ||= 1000
        start ||= 0
        sort ||= 'X_CHEF_id_CHEF_X asc'

        unless block.nil? #@TODO: IS THIS CORRECT? THIS DOESN'T SEEM CORRECT. WHY DO WE EVEN NEED IT?
          search(type, query, filter_result: keys, rows: rows, start: start, sort: sort)
        else
          search(type, query, filter_result: keys.dup, rows: rows, start: start, sort: sort, &block)
        end
      end

      #
      # New search input, designed to be backwards compatible with the old method signature
      # 'type' and 'query' are the same as before, args now will accept either a Hash of
      # search arguments with symbols as the keys (ie :sort, :start, :rows) and a :filter_result
      # option.
      #
      # :filter_result should be in the format of another Hash with the structure of:
      # {
      #   :returned_name1 => ["path", "to", "variable"],
      #   :returned_name2 => ["shorter", "path"]
      # }
      # a real world example might be something like:
      # {
      #   :ip_address => ["ipaddress"],
      #   :ruby_version => ["languages", "ruby", "version"]
      # }
      #  this will bring back 2 variables 'ip_address' and 'ruby_version' with whatever value was found
      # an example of the returned json may be:
      # {"ip_address":"127.0.0.1", "ruby_version": "1.9.3"}
      #
      def search(type, query="*:*", filter_result:nil, rows:1000, start:0, sort:'X_CHEF_id_CHEF_X asc', &block)
        validate_type(type)

        query_string = create_query_string(type, query, rows, start, sort)
        response = call_rest_service(query_string, filter_result)

        if block
          response["rows"].each { |row| block.call(row) if row }
          if response["start"] + response["rows"].size < response["total"]
            start = response["start"] + rows
            search(type, query, filter_result: filter_result, rows: rows, start: start, sort: sort, &block)
          end
          true
        else
          [
            response["rows"],
            response["start"],
            response["total"]
          ]
        end
      end

      private
      def validate_type(t)
        unless t.kind_of?(String) || t.kind_of?(Symbol)
          msg = "Invalid search object type #{t.inspect} (#{t.class}), must be a String or Symbol." +
            "Useage: search(:node, QUERY[, OPTIONAL_ARGS])" +
            "        `knife search environment QUERY (options)`"
          raise Chef::Exceptions::InvalidSearchQuery, msg
        end
      end

      def create_query_string(type, query, rows, start, sort)
        "search/#{type}?q=#{escape(query)}&sort=#{escape(sort)}&start=#{escape(start)}&rows=#{escape(rows)}"
      end

      def escape(s)
        s && URI.escape(s.to_s)
      end

      def call_rest_service(query_string, filter_result)
        if filter_result
          response = rest.post_rest(query_string, filter_result)
          response['rows'].map! { |row| row['data'] }
        else
          response = rest.get_rest(query_string)
        end

        response
      end

    end
  end
end
