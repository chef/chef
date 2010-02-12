#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/couchdb'
require 'chef/node'
require 'chef/role'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'chef/solr'
require 'chef/log'
require 'chef/config'

class Chef
  class Solr
    class Query < Chef::Solr
      
      # Create a new Query object - takes the solr_url and optional
      # couchdb_database to inflate objects into.
      def initialize(solr_url=Chef::Config[:solr_url], database=Chef::Config[:couchdb_database])
        super(solr_url)
        @database = database
        @couchdb = Chef::CouchDB.new(nil, database)
      end

      # A raw query against CouchDB - takes the type of object to find, and raw
      # Solr options.
      #
      # You'll wind up having to page things yourself.
      def raw(type, options={})
        case type
        when "role",:role,"node",:node,"client",:client
          qtype = type
        else
          qtype = [ "data_bag_item", type ]
        end
        Chef::Log.debug("Searching #{@database} #{qtype.inspect} for #{options.inspect}")
        results = solr_select(@database, qtype, options)
        if results["response"]["docs"].length > 0
          objects = @couchdb.bulk_get(
            results["response"]["docs"].collect { |d| d["X_CHEF_id_CHEF_X"] }
          )
        else
          objects = []
        end
        [ objects, results["response"]["start"], results["response"]["numFound"], results["responseHeader"] ] 
      end

      # Search Solr for objects of a given type, for a given query. If you give
      # it a block, it will handle the paging for you dynamically.
      def search(type, query="*:*", sort=nil, start=0, rows=20, &block)
        options = {
          :q => query,
          :start => start,
          :rows => rows 
        }
        options[:sort] = sort if sort && ! sort.empty?
        objects, start, total, response_header = raw(type, options)
        if block
          objects.each { |o| block.call(o) }
          unless (start + objects.length) >= total
            nstart = start + rows
            search(type, query, sort, nstart, rows, &block)
          end
          true
        else
          [ objects, start, total ]
        end
      end
    end
  end
end

