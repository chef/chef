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
require 'chef/node'
require 'chef/role'
require 'chef/data_bag'
require 'chef/data_bag_item'

class Chef
  class Search
    class Query 
      def initialize(url=nil)
        url ||= Chef::Config[:search_url]
        @rest = Chef::REST.new(url)
      end

      # Search Solr for objects of a given type, for a given query. If you give
      # it a block, it will handle the paging for you dynamically.
      def search(type, query="*:*", sort=nil, start=0, rows=20, &block)
        unless type.kind_of?(String) || type.kind_of?(Symbol)
          raise ArgumentError, "Type must be a string or a symbol!" 
        end

        response = @rest.get_rest("search/#{type}?q=#{escape(query)}&sort=#{escape(sort)}&start=#{escape(start)}&rows=#{escape(rows)}")
        if block
          response["rows"].each { |o| block.call(o) }
          unless (response["start"] + response["rows"].length) >= response["total"]
            nstart = response["start"] + rows
            search(type, query, sort, nstart, rows, &block)
          end
          true
        else
          [ response["rows"], response["start"], response["total"] ]
        end
      end

      private
        # escapes a query key/value for http
        # Thanks to RSolr!
        def escape(s)
          s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
            '%'+$1.unpack('H2'*$1.size).join('%').upcase
          }.tr(' ', '+') 
        end
    end
  end
end
