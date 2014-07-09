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
require 'uri'
require 'chef/rest'
require 'chef/node'
require 'chef/role'
require 'chef/data_bag'
require 'chef/data_bag_item'

class Chef
  class Search
    class Query

      attr_accessor :rest

      def initialize(url=nil)
        @rest = Chef::REST.new(url ||Chef::Config[:chef_server_url])
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
        raise ArgumentError, "Type must be a string or a symbol!" unless (type.kind_of?(String) || type.kind_of?(Symbol))
        raise ArgumentError, "Invalid number of arguments!" if (args.size > 3)

        scrubbed_args = Hash.new

        # argify everything
        if args[0].kind_of?(Hash)
          scrubbed_args = args[0]
        else
          # This api will be deprecated in a future release
          scrubbed_args = { :sort => args[0], :start => args[1], :rows => args[2] }
        end

        # set defaults, if they haven't been set yet.
        scrubbed_args[:sort] ||= 'X_CHEF_id_CHEF_X asc'
        scrubbed_args[:start] ||= 0
        scrubbed_args[:rows] ||= 1000

        do_search(type, query, scrubbed_args, &block)
      end

      def list_indexes
        @rest.get_rest("search")
      end

      private
      def escape(s)
        s && URI.escape(s.to_s)
      end

      # new search api that allows for a cleaner implementation of things like return filters
      # (formerly known as 'partial search').
      # Also args should never be nil, but that is required for Ruby 1.8 compatibility
      def do_search(type, query="*:*", args=nil, &block)
        raise ArgumentError, "Type must be a string or a symbol!" unless (type.kind_of?(String) || type.kind_of?(Symbol))

        query_string = create_query_string(type, query, args)
        if !args.nil? && args.key?(:filter_result)
          response = @rest.post_rest(query_string, args[:filter_result])
          response_rows = response["rows"].map { |row| row['data'] }
        else
          response = @rest.get_rest(query_string)
          response_rows = response["rows"]
        end
        unless block.nil?
          response_rows.each { |rowset| block.call(rowset) unless rowset.nil?}
          unless (response["start"] + response_rows.length) >= response["total"]
            args[:start] = response["start"] + args[:rows]
            do_search(type, query, args, &block)
          end
          true
        else
          [ response_rows, response["start"], response["total"] ]
        end
      end

      # create the full rest url string
      def create_query_string(type, query, args)
        # create some default variables just so we don't break backwards compatibility
        sort = args[:sort]
        start = args[:start]
        rows = args[:rows]

        return "search/#{type}?q=#{escape(query)}&sort=#{escape(sort)}&start=#{escape(start)}&rows=#{escape(rows)}"
      end
    end
  end
end
