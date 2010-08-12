#
# Author:: Stephen Delano (<stephen@opscode.com>)
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

require 'chef/config'
require 'chef/mixin/params_validate'
require 'chef/couchdb'

class Chef
  class Environment

    include Chef::Mixin::ParamsValidate

    attr_accessor :couchdb, :couchdb_rev
    attr_reader :couchdb_id

    DESIGN_DOCUMENT = {
      "version" => 1,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
          function(doc) {
            if (doc.chef_type == "environment") {
              emit(doc.name, doc);
            }
          }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) {
            if (doc.chef_type == "environment") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        }
      }
    }

    def initialize(couchdb=nil)
      @name = ''
      @description = ''
      @couchdb_rev = nil
      @couchdb_id = nil
      @couchdb = couchdb || Chef::CouchDB.new
    end

    def couchdb_id=(value)
      @couchdb_id = value
    end

    def chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def self.chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def name(arg=nil)
      set_or_return(
        :name,
        arg,
        { :regex => /^[\-[:alnum:]_]+$/, :kind_of => String }
      )
    end

    def description(arg=nil)
      set_or_return(
        :description,
        arg,
        :kind_of => String
      )
    end

    def to_hash
      result = {
        "name" => @name,
        "description" => @description,
        "json_class" => self.class.name,
        "chef_type" => "environment"
      }
      result["_rev"] = couchdb_rev if couchdb_rev
      result
    end

    def to_json(*a)
      to_hash.to_json(*a)
    end

    def self.json_create(o)
      environment = new
      environment.name(o["name"])
      environment.description(o["description"])
      environment.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      environment.couchdb_id = o["_id"] if o.has_key?("_id")
      environment
    end

    def self.cdb_list(inflate=false, couchdb=nil)
      es = (couchdb || Chef::CouchDB.new).list("environments", inflate)
      lookup = (inflate ? "value" : "key")
      es["rows"].collect { |e| e[lookup] }
    end

    def self.list(inflate=false)
      if inflate
        # TODO: index the environments and use search to inflate - don't inflate for now :(
        chef_server_rest.get_rest("environments")
      else
        chef_server_rest.get_rest("environments")
      end
    end

    def self.cdb_load(name, couchdb=nil)
      (couchdb || Chef::CouchDB.new).load("environment", name)
    end

    def self.load(name)
      chef_server_rest.get_rest("environments/#{name}")
    end

    def self.exists?(name, couchdb)
      begin
        self.cdb_load(name, couchdb)
      rescue Chef::Exceptions::CouchDBNotFound
        nil
      end
    end

    def cdb_destroy
      couchdb.delete("environment", @name, couchdb_rev)
    end

    def destroy
      chef_server_rest.delete_rest("environments/#{@name}")
    end

    def cdb_save
      self.couchdb_rev = couchdb.store("environment", @name, self)["rev"]
    end

    def save
      begin
        chef_server_rest.put_rest("environments/#{@name}", self)
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        chef_server_rest.post_rest("environments", self)
      end
      self
    end

    def create
      chef_server_rest.post_rest("environments", self)
      self
    end

    # Set up our CouchDB design document
    def self.create_design_document(couchdb=nil)
      (couchdb || Chef::CouchDB.new).create_design_document("environments", DESIGN_DOCUMENT)
    end

    def to_s
      @name
    end

  end
end
