#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
      # Chef::CouchDB object to inflate objects into.
      def initialize(solr_url=Chef::Config[:solr_url], couchdb = nil)
        super(solr_url)
        if couchdb.nil?
          @database = Chef::Config[:couchdb_database]
          @couchdb = Chef::CouchDB.new(nil, Chef::Config[:couchdb_database])
        else
          unless couchdb.kind_of?(Chef::CouchDB)
            Chef::Log.warn("Passing the database name to Chef::Solr::Query initialization is deprecated. Please pass in the Chef::CouchDB object instead.")
            @database = couchdb
            @couchdb = Chef::CouchDB.new(nil, couchdb)
          else
            @database = couchdb.couchdb_database
            @couchdb = couchdb
          end
        end 
      end

      # A raw query against CouchDB - takes the type of object to find, and raw
      # Solr options.
      #
      # You'll wind up having to page things yourself.
      def raw(type, options={})
        qtype = case type
                when "role",:role,"node",:node,"client",:client
                  type
                else
                  [ "data_bag_item", type ]
                end
        results = solr_select(@database, qtype, options)
        Chef::Log.debug("Searching #{@database} #{qtype.inspect} for #{options.inspect} with results:\n#{results.inspect}") 
        objects = if results["response"]["docs"].length > 0
                    bulk_objects = @couchdb.bulk_get( results["response"]["docs"].collect { |d| d["X_CHEF_id_CHEF_X"] } )
                    Chef::Log.debug("bulk get of objects: #{bulk_objects.inspect}")
                    bulk_objects
                  else
                    []
                  end
        [ objects, results["response"]["start"], results["response"]["numFound"], results["responseHeader"] ] 
      end

      # Search Solr for objects of a given type, for a given query. If you give
      # it a block, it will handle the paging for you dynamically.
      def search(type, query="*:*", sort='X_CHEF_id_CHEF_X asc', start=0, rows=1000, &block)
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

