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
      attr_reader :config

      def initialize(url=nil, config:Chef::Config)
        @config = config
        @url = url
      end

      def rest
        @rest ||= Chef::REST.new(@url || @config[:chef_server_url])
      end

      # Backwards compatability for cookbooks.
      # This can be removed in Chef > 12.
      def partial_search(type, query='*:*', *args, &block)
        Chef::Log.warn(<<-WARNDEP)
DEPRECATED: The 'partial_search' API is deprecated and will be removed in
future releases. Please use 'search' with a :filter_result argument to get
partial search data.
WARNDEP

        if !args.empty? && args.first.is_a?(Hash)
          # partial_search uses :keys instead of :filter_result for
          # result filtering.
          args_h = args.first.dup
          args_h[:filter_result] = args_h[:keys]
          args_h.delete(:keys)

          search(type, query, args_h, &block)
        else
          search(type, query, *args, &block)
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
      def search(type, query='*:*', *args, &block)
        validate_type(type)

        args_h = hashify_args(*args)
        response = call_rest_service(type, query: query, **args_h)

        if block
          response["rows"].each { |row| block.call(row) if row }
          unless (response["start"] + response["rows"].length) >= response["total"]
            args_h[:start] = response["start"] + response["rows"].length
            search(type, query, args_h, &block)
          end
          true
        else
          [ response["rows"], response["start"], response["total"] ]
        end
      end

      private
      def validate_type(t)
        unless t.kind_of?(String) || t.kind_of?(Symbol)
          msg = "Invalid search object type #{t.inspect} (#{t.class}), must be a String or Symbol." +
          "Usage: search(:node, QUERY[, OPTIONAL_ARGS])" +
          "        `knife search environment QUERY (options)`"
          raise Chef::Exceptions::InvalidSearchQuery, msg
        end
      end

      def hashify_args(*args)
        return Hash.new if args.empty?
        return args.first if args.first.is_a?(Hash)

        args_h = Hash.new
        args_h[:sort] = args[0] if args[0]
        args_h[:start] = args[1] if args[1]
        args_h[:rows] = args[2]
        args_h[:filter_result] = args[3]
        args_h
      end

      def escape(s)
        s && URI.escape(s.to_s)
      end

      def create_query_string(type, query, rows, start, sort)
        qstr = "search/#{type}?q=#{escape(query)}"
        qstr += "&sort=#{escape(sort)}" if sort
        qstr += "&start=#{escape(start)}" if start
        qstr += "&rows=#{escape(rows)}" if rows
        qstr
      end

      def call_rest_service(type, query:'*:*', rows:nil, start:0, sort:'X_CHEF_id_CHEF_X asc', filter_result:nil)
        query_string = create_query_string(type, query, rows, start, sort)

        if filter_result
          response = rest.post_rest(query_string, filter_result)
          # response returns rows in the format of
          # { "url" => url_to_node, "data" => filter_result_hash }
          response['rows'].map! { |row| row['data'] }
        else
          response = rest.get_rest(query_string)
        end

        response
      end

    end
  end
end
