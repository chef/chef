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

require 'chef/mixin/params_validate'
require 'chef/config'
require 'chef/rest'
require 'chef/log'
require 'digest/sha2'
require 'json'
require 'uuidtools'
require 'chef/nanite'

class Chef
  class CouchDB
    include Chef::Mixin::ParamsValidate

    def initialize(url=nil, db=Chef::Config[:couchdb_database])
      url ||= Chef::Config[:couchdb_url]
      @db = db
      @rest = Chef::REST.new(url, nil, nil)
    end

    def couchdb_database(args=nil)
      if args
        @db = args
      else
        @db
      end
    end

    def create_id_map
      create_design_document(
        "id_map", 
        {
          "version" => 1,
          "language" => "javascript",
          "views" => {
            "name_to_id" => {
              "map" => <<-EOJS
                function(doc) {
                  emit([ doc.chef_type, doc.name], doc._id);
                }
              EOJS
            },
            "id_to_name" => {
              "map" => <<-EOJS
                function(doc) { 
                  emit(doc._id, [ doc.chef_type, doc.name ]);
                }
              EOJS
            }
          }
        }
      )
    end

    def create_db
      @database_list = @rest.get_rest("_all_dbs")
      unless @database_list.detect { |db| db == couchdb_database }
        response = @rest.put_rest(couchdb_database, Hash.new)
      end
      couchdb_database
    end
    
    def create_design_document(name, data)
      create_db
      to_update = true
      begin
        old_doc = @rest.get_rest("#{couchdb_database}/_design/#{name}")
        if data["version"] != old_doc["version"]
          data["_rev"] = old_doc["_rev"]
          Chef::Log.debug("Updating #{name} views")
        else
          to_update = false
        end
      rescue 
        Chef::Log.debug("Creating #{name} views for the first time because: #{$!}")
      end
      if to_update
        @rest.put_rest("#{couchdb_database}/_design%2F#{name}", data)
      end
      true
    end

    def store(obj_type, name, object)
      validate(
        {
          :obj_type => obj_type,
          :name => name,
          :object => object,
        },
        {
          :object => { :respond_to => :to_json },
        }
      )
      r = get_view("id_map", "name_to_id", :key => [ obj_type, name ])
      uuid = nil
      if r["rows"].length == 1
        uuid = r["rows"][0]["id"]
      else
        uuid = UUIDTools::UUID.random_create.to_s
      end
        
      r = @rest.put_rest("#{couchdb_database}/#{uuid}", object)
      Chef::Log.info("Sending #{uuid} to Nanite for indexing..")
      n = Chef::Nanite.request(
        "/index/add",
        { 
          :id => uuid,
          :database => couchdb_database,
          :type => obj_type,
          :item => object
        },
        :persistent => true
      ) do |response_full|
        Chef::Log.debug("Finished indexing #{obj_type} #{uuid} in #{couchdb_database}");
      end
      r
    end

    def load(obj_type, name)
      validate(
        {
          :obj_type => obj_type,
          :name => name,
        },
        {
          :obj_type => { :kind_of => String },
          :name => { :kind_of => String },
        }
      )
      doc = find_by_name(obj_type, name)
      doc.couchdb = self if doc.respond_to?(:couchdb)
      doc 
    end
  
    def delete(obj_type, name, rev=nil)
      validate(
        {
          :obj_type => obj_type,
          :name => name,
        },
        {
          :obj_type => { :kind_of => String },
          :name => { :kind_of => String },
        }
      )
      del_id = nil 
      last_obj, obj_id = find_by_name(obj_type, name, true)
      unless rev
        if last_obj.respond_to?(:couchdb_rev)
          rev = last_obj.couchdb_rev
        else
          rev = last_obj['_rev']
        end
      end
      r = @rest.delete_rest("#{couchdb_database}/#{obj_id}?rev=#{rev}")
      r.couchdb = self if r.respond_to?(:couchdb)
      Chef::Log.info("Sending #{obj_id} to Nanite for deletion..")
      n = Chef::Nanite.request(
        "/index/delete",
        { 
          :id => obj_id,
          :database => couchdb_database,
          :type => obj_type
        },
        :persistent => true
      ) do |response_full|
        Chef::Log.debug("Finished Deleting #{obj_type} #{obj_id} in #{couchdb_database}");
      end
      r
    end
  
    def list(view, inflate=false)
      validate(
        { 
          :view => view,
        },
        {
          :view => { :kind_of => String }
        }
      )
      if inflate
        r = @rest.get_rest(view_uri(view, "all"))
        r["rows"].each { |i| i["value"].couchdb = self if i["value"].respond_to?(:couchdb=) }
        r
      else
        r = @rest.get_rest(view_uri(view, "all_id"))
      end
      r
    end
  
    def has_key?(obj_type, name)
      validate(
        {
          :obj_type => obj_type,
          :name => name,
        },
        {
          :obj_type => { :kind_of => String },
          :name => { :kind_of => String },
        }
      )
      begin
        find_by_name(obj_type, name)
        true
      rescue
        false
      end
    end

    def find_by_name(obj_type, name, with_id=false)
      r = get_view("id_map", "name_to_id", :key => [ obj_type, name ], :include_docs => true)
      if r["rows"].length == 0
        raise Chef::Exceptions::CouchDBNotFound, "Cannot find #{obj_type} #{name} in CouchDB!"
      end
      if with_id
        [ r["rows"][0]["doc"], r["rows"][0]["id"] ]
      else
        r["rows"][0]["doc"] 
      end
    end

    def get_view(design, view, options={})
      view_string = view_uri(design, view)
      view_string << "?" if options.length != 0
      first = true;
      options.each { |k,v| view_string << "#{first ? '' : '&'}#{k}=#{URI.escape(v.to_json)}"; first = false }
      @rest.get_rest(view_string)
    end

    def bulk_get(*to_fetch)
      response = @rest.post_rest("#{couchdb_database}/_all_docs?include_docs=true", { "keys" => to_fetch.flatten })
      response["rows"].collect { |r| r["doc"].couchdb = self; r["doc"] }
    end
    
    def view_uri(design, view)
      Chef::Config[:couchdb_version] ||= @rest.run_request(:GET, URI.parse(@rest.url + "/"), {}, false, 10, false)["version"].gsub(/-.+/,"").to_f
      case Chef::Config[:couchdb_version]
      when 0.9
        "#{couchdb_database}/_design/#{design}/_view/#{view}"
      when 0.8
        "#{couchdb_database}/_view/#{design}/#{view}"
      else
        "#{couchdb_database}/_design/#{design}/_view/#{view}"
      end
    end
    
    private
    
      def safe_name(name)
        name.gsub(/\./, "_")
      end

  end
end
