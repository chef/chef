#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/config"
require "chef/exceptions"
require "chef/server_api"

require "uri"
require "addressable/uri"

class Chef
  class Search
    class Query

      attr_accessor :rest
      attr_reader :config

      def initialize(url = nil, config: Chef::Config)
        @config = config
        @url = url
      end

      def rest
        @rest ||= Chef::ServerAPI.new(@url || @config[:chef_server_url])
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
      def search(type, query = "*:*", *args, &block)
        validate_type(type)

        args_h = hashify_args(*args)
        if args_h[:fuzz]
          if type == :node
            query = fuzzify_node_query(query)
          end
          # FIXME: can i haz proper ruby-2.x named parameters someday plz?
          args_h = args_h.reject { |k, v| k == :fuzz }
        end

        response = call_rest_service(type, query: query, **args_h)

        if block
          response["rows"].each { |row| yield(row) if row }
          #
          # args_h[:rows] and args_h[:start] are the page size and
          # start position requested of the search index backing the
          # search API.
          #
          # The response may contain fewer rows than arg_h[:rows] if
          # the page of index results included deleted nodes which
          # have been filtered from the returned data. In this case,
          # we still want to start the next page at start +
          # args_h[:rows] to avoid asking the search backend for
          # overlapping pages (which could result in duplicates).
          #
          next_start = response["start"] + (args_h[:rows] || response["rows"].length)
          unless next_start >= response["total"]
            args_h[:start] = next_start
            search(type, query, args_h, &block)
          end
          true
        else
          [ response["rows"], response["start"], response["total"] ]
        end
      end

      private

      def fuzzify_node_query(query)
        if query !~ /:/
          "tags:*#{query}* OR roles:*#{query}* OR fqdn:*#{query}* OR addresses:*#{query}* OR policy_name:*#{query}* OR policy_group:*#{query}*"
        else
          query
        end
      end

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
        # If we have 4 arguments, the first is the now-removed sort option, so
        # just ignore it.
        args.pop(0) if args.length == 4
        args_h[:start] = args[0] if args[0]
        args_h[:rows] = args[1]
        args_h[:filter_result] = args[2]
        args_h
      end

      QUERY_PARAM_VALUE = Addressable::URI::CharacterClasses::QUERY + "\\&\\;"

      def escape_value(s)
        s && Addressable::URI.encode_component(s.to_s, QUERY_PARAM_VALUE)
      end

      def create_query_string(type, query, rows, start)
        qstr = "search/#{type}?q=#{escape_value(query)}"
        qstr += "&start=#{escape_value(start)}" if start
        qstr += "&rows=#{escape_value(rows)}" if rows
        qstr
      end

      def call_rest_service(type, query: "*:*", rows: nil, start: 0, filter_result: nil)
        query_string = create_query_string(type, query, rows, start)

        if filter_result
          response = rest.post(query_string, filter_result)
          # response returns rows in the format of
          # { "url" => url_to_node, "data" => filter_result_hash }
          response["rows"].map! { |row| row["data"] }
        else
          response = rest.get(query_string)
          response["rows"].map! do |row|
            case type.to_s
            when "node"
              Chef::Node.from_hash(row)
            when "role"
              Chef::Role.from_hash(row)
            when "environment"
              Chef::Environment.from_hash(row)
            when "client"
              Chef::ApiClient.from_hash(row)
            else
              Chef::DataBagItem.from_hash(row)
            end
          end
        end

        response
      end

    end
  end
end
