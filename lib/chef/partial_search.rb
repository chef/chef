#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
# These are needed so that JSON can inflate search results
require 'chef/node'
require 'chef/role'
require 'chef/environment'
require 'chef/data_bag'
require 'chef/data_bag_item'

class Chef
  class PartialSearch

    attr_accessor :rest

    def initialize(url=nil)
      @rest = ::Chef::REST.new(url || ::Chef::Config[:search_url])
    end

    # Search Solr for objects of a given type, for a given query. If you give
    # it a block, it will handle the paging for you dynamically.
    def search(type, query='*:*', args={}, &block)
      raise ArgumentError, "Type must be a string or a symbol!" unless (type.kind_of?(String) || type.kind_of?(Symbol))

      sort = args.include?(:sort) ? args[:sort] : 'X_CHEF_id_CHEF_X asc'
      start = args.include?(:start) ? args[:start] : 0
      rows = args.include?(:rows) ? args[:rows] : 1000
      query_string = "search/#{type}?q=#{escape(query)}&sort=#{escape(sort)}&start=#{escape(start)}&rows=#{escape(rows)}"
      if args[:keys]
        response = @rest.post_rest(query_string, args[:keys])
        response_rows = response['rows'].map { |row| row['data'] }
      else
        response = @rest.get_rest(query_string)
        response_rows = response['rows']
      end
      if block
        response_rows.each { |o| block.call(o) unless o.nil?}
        unless (response["start"] + response_rows.length) >= response["total"]
          nstart = response["start"] + rows
          args_hash = {
            :keys => args[:keys],
            :sort => sort,
            :start => nstart,
            :rows => rows
          }
          search(type, query, args_hash, &block)  
        end
        true
      else
        [ response_rows, response["start"], response["total"] ]
      end
    end

    def list_indexes
      response = @rest.get_rest("search")
    end

    private
      def escape(s)
        s && URI.escape(s.to_s)
      end
  end
end

# partial_search(type, query, options, &block)
#
# Searches for nodes, roles, etc. and returns the results.  This method may
# perform more than one search request, if there are a large number of results.
#
# ==== Parameters
# * +type+: index type (:role, :node, :client, :environment, data bag name)
# * +query+: SOLR query.  "*:*", "role:blah", "not role:blah", etc.  Defaults to '*:*'
# * +options+: hash with options:
# ** +:start+: First row to return (:start => 50, :rows => 100 means "return the
#               50th through 150th result")
# ** +:rows+: Number of rows to return.  Defaults to 1000.
# ** +:sort+: a SOLR sort specification.  Defaults to 'X_CHEF_id_CHEF_X asc'.
# ** +:keys+: partial search keys.  If this is not specified, the search will
#             not be partial.
#
# ==== Returns
#
# This method returns an array of search results.  Partial search results will
# be JSON hashes with the structure specified in the +keys+ option.  Other
# results include +Chef::Node+, +Chef::Role+, +Chef::Client+, +Chef::Environment+,
# +Chef::DataBag+ and +Chef::DataBagItem+ objects, depending on the search type.
#
# If a block is specified, the block will be called with each result instead of
# returning an array.  This method will not block if it returns
#
# If start or row is specified, and no block is given, the result will be a
# triple containing the list, the start and total:
#
#     [ [ row1, row2, ... ], start, total ]
#
# ==== Example
#
#     partial_search(:node, 'role:webserver',
#                    keys: {
#                      name: [ 'name' ],
#                      ip: [ 'amazon', 'ip', 'public' ]
#                    }
#     ).each do |node|
#       puts "#{node[:name]}: #{node[:ip]}"
#     end
#
def partial_search(type, query='*:*', *args, &block)
  # Support both the old (positional args) and new (hash args) styles of calling
  if args.length == 1 && args[0].is_a?(Hash)
    args_hash = args[0]
  else
    args_hash = {}
    args_hash[:sort] = args[0] if args.length >= 1
    args_hash[:start] = args[1] if args.length >= 2
    args_hash[:rows] = args[2] if args.length >= 3
  end
  # If you pass a block, or have the start or rows arguments, do raw result parsing
  if Kernel.block_given? || args_hash[:start] || args_hash[:rows]
    Chef::PartialSearch.new.search(type, query, args_hash, &block)
  # Otherwise, do the iteration for the end user
  else
    results = Array.new
    Chef::PartialSearch.new.search(type, query, args_hash) do |o|
      results << o
    end
    results
  end
end
