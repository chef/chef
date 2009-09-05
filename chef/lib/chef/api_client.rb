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
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/couchdb'
require 'extlib'
require 'json'

class Chef
  class ApiClient 
    
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    
    DESIGN_DOCUMENT = {
      "version" => 1,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "client") {
              emit(doc.name, doc);
            }
          }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "client") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        }
      }
    }

    attr_accessor :couchdb_rev, :couchdb_id
    
    # Create a new Chef::ApiClient object.
    def initialize
      @name = '' 
      @public_key = nil
      @default_attributes = Mash.new
      @override_attributes = Mash.new
      @recipes = Array.new 
      @couchdb_rev = nil
      @couchdb_id = nil
      @couchdb = Chef::CouchDB.new 
    end

    def name(arg=nil) 
      set_or_return(
        :name,
        arg,
        :regex => /^[\-[:alnum:]_]+$/
      )
    end

    def public_key(arg=nil) 
      set_or_return(
        :public_key,
        arg,
        :kind_of => String
      )
    end

    def to_hash
      result = {
        "name" => @name,
        "public_key" => @public_key,
        'json_class' => self.class.name,
        "chef_type" => "client"
      }
      result["_rev"] = @couchdb_rev if @couchdb_rev
      result
    end

    # Serialize this object as a hash 
    def to_json(*a)
      to_hash.to_json(*a)
    end
    
    # Create a Chef::Role from JSON
    def self.json_create(o)
      client = Chef::ApiClient.new
      client.name(o["name"])
      client.public_key(o["public_key"])
      client.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      client.couchdb_id = o["_id"] if o.has_key?("_id")
      client
    end
    
    # List all the Chef::ApiClient objects in the CouchDB.  If inflate is set
    # to true, you will get the full list of all ApiClients, fully inflated.
    def self.list(inflate=false)
      couchdb = Chef::CouchDB.new
      rs = couchdb.list("clients", inflate)
      if inflate
        rs["rows"].collect { |r| r["value"] }
      else
        rs["rows"].collect { |r| r["key"] }
      end
    end
    
    # Load a role by name from CouchDB
    def self.load(name)
      couchdb = Chef::CouchDB.new
      couchdb.load("clients", name)
    end
    
    # Remove this role from the CouchDB
    def destroy
      @couchdb.delete("client", @name, @couchdb_rev)
    end
    
    # Save this role to the CouchDB
    def save
      results = @couchdb.store("client", @name, self)
      @couchdb_rev = results["rev"]
    end
    
    # Set up our CouchDB design document
    def self.create_design_document
      couchdb = Chef::CouchDB.new
      couchdb.create_design_document("clients", DESIGN_DOCUMENT)
    end
    
    # As a string
    def to_s
      "client[#{@name}]"
    end

  end
end

