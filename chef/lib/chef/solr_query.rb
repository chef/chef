#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2009-2011 Opscode, Inc.
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

require 'chef/mixin/xml_escape'
require 'chef/log'
require 'chef/config'
require 'chef/couchdb'
require 'chef/solr_query/solr_http_request'
require 'chef/solr_query/query_transform'

class Chef
  class SolrQuery

    ID_KEY = "X_CHEF_id_CHEF_X"
    DEFAULT_PARAMS = Mash.new(:start => 0, :rows => 1000, :sort => "#{ID_KEY} asc", :wt => 'json', :indent => 'off').freeze
    FILTER_PARAM_MAP = {:database => 'X_CHEF_database_CHEF_X', :type => "X_CHEF_type_CHEF_X", :data_bag  => 'data_bag'}
    VALID_PARAMS = [:start,:rows,:sort,:q,:type]
    BUILTIN_SEARCH_TYPES = ["role","node","client","environment"]
    DATA_BAG_ITEM = 'data_bag_item'

    include Chef::Mixin::XMLEscape

    attr_accessor :query
    attr_accessor :params

    # Create a new Query object - takes the solr_url and optional
    # Chef::CouchDB object to inflate objects into.
    def initialize(couchdb = nil)
      @filter_query = {}
      @params = {}

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

    def self.from_params(params, couchdb=nil)
      query = new(couchdb)
      query.params = VALID_PARAMS.inject({}) do |p, param_name|
        p[param_name] = params[param_name] if params.key?(param_name)
        p
      end
      query.update_filter_query_from_params
      query.update_query_from_params
      query
    end

    def filter_by(filter_query_params)
      filter_query_params.each do |key, value|
        @filter_query[FILTER_PARAM_MAP[key]] = value
      end
    end

    def filter_query
      @filter_query.map { |param, value| "+#{param}:#{value}" }.join(' ')
    end

    def filter_by_type(type)
      case type
      when *BUILTIN_SEARCH_TYPES
        filter_by(:type => type)
      else
        filter_by(:type => DATA_BAG_ITEM, :data_bag => type)
      end
    end

    def update_filter_query_from_params
      filter_by(:database => @database)
      filter_by_type(params.delete(:type))
    end

    def update_query_from_params
      original_query = URI.decode(params.delete(:q) || "*:*")
      @query = Chef::SolrQuery::QueryTransform.transform(original_query)
    end

    def objects
      if !object_ids.empty?
        @bulk_objects ||= @couchdb.bulk_get(object_ids)
        Chef::Log.debug { "Bulk get of objects: #{@bulk_objects.inspect}" }
        @bulk_objects
      else
        []
      end
    end

    def object_ids
      @object_ids ||= results["response"]["docs"].map { |d| d[ID_KEY] }
    end

    def results
      @results ||= SolrHTTPRequest.select(self.to_hash)
    end

    # Search Solr for objects of a given type, for a given query.
    def search
      { "rows" => objects, "start" => results["response"]["start"],
        "total" => results["response"]["numFound"] }
    end

    def to_hash
      options = DEFAULT_PARAMS.merge(params)
      options[:fq] = filter_query
      options[:q] = @query
      options
    end

    START_XML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".freeze
    START_DELETE_BY_QUERY = "<delete><query>".freeze
    END_DELETE_BY_QUERY = "</query></delete>\n".freeze
    COMMIT = "<commit/>\n".freeze

    def commit(opts={})
      SolrHTTPRequest.update("#{START_XML}#{COMMIT}")
    end

    def delete_database(db)
      query_data = xml_escape("X_CHEF_database_CHEF_X:#{db}")
      xml = "#{START_XML}#{START_DELETE_BY_QUERY}#{query_data}#{END_DELETE_BY_QUERY}"
      SolrHTTPRequest.update(xml)
      commit
    end

    def rebuild_index(db=Chef::Config[:couchdb_database])
      delete_database(db)

      results = {}
      [Chef::ApiClient, Chef::Node, Chef::Role].each do |klass|
        results[klass.name] = reindex_all(klass) ? "success" : "failed"
      end
      databags = Chef::DataBag.cdb_list(true)
      Chef::Log.info("Reloading #{databags.size.to_s} #{Chef::DataBag} objects into the indexer")
      databags.each { |i| i.add_to_index; i.list(true).each { |x| x.add_to_index } }
      results[Chef::DataBag.name] = "success"
      results
    end

    def reindex_all(klass, metadata={})
      begin
        items = klass.cdb_list(true)
        Chef::Log.info("Reloading #{items.size.to_s} #{klass.name} objects into the indexer")
        items.each { |i| i.add_to_index }
      rescue Net::HTTPServerException => e
        # 404s are okay, there might not be any of that kind of object...
        if e.message =~ /Not Found/
          Chef::Log.warn("Could not load #{klass.name} objects from couch for re-indexing (this is ok if you don't have any of these)")
          return false
        else
          raise e
        end
      rescue Exception => e
        Chef::Log.fatal("Chef encountered an error while attempting to load #{klass.name} objects back into the index")
        raise e
      end
      true
    end


  end
end
