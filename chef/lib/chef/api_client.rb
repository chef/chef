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
require 'chef/couchdb'
require 'chef/certificate'
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
      @private_key = nil
      @couchdb_rev = nil
      @couchdb_id = nil
      @couchdb = Chef::CouchDB.new 
    end

    # Gets or sets the client name.
    #
    # @params [Optional String] The name must be alpha-numeric plus - and _.
    # @return [String] The current value of the name.
    def name(arg=nil) 
      set_or_return(
        :name,
        arg,
        :regex => /^[\-[:alnum:]_]+$/
      )
    end

    # Gets or sets the public key.
    # 
    # @params [Optional String] The string representation of the public key. 
    # @return [String] The current value.
    def public_key(arg=nil) 
      set_or_return(
        :public_key,
        arg,
        :kind_of => String
      )
    end

    # Gets or sets the public key.
    # 
    # @params [Optional String] The string representation of the private key.
    # @return [String] The current value.
    def private_key(arg=nil) 
      set_or_return(
        :private_key,
        arg,
        :kind_of => String
      )
    end

    # Creates a new public/private key pair, and populates the public_key and
    # private_key attributes.
    # 
    # @return [True]
    def create_keys
      results = Chef::Certificate.gen_keypair(self.name)
      self.public_key(results[0].to_s)
      self.private_key(results[1].to_s)
      true
    end

    # The hash representation of the object.  Includes the name and public_key,
    # but never the private key.
    # 
    # @return [Hash]
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

    # The JSON representation of the object.
    # 
    # @return [String] the JSON string.
    def to_json(*a)
      to_hash.to_json(*a)
    end
    
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
    
    # Load a client by name from CouchDB
    # 
    # @params [String] The name of the client to load
    # @return [Chef::ApiClient] The resulting Chef::ApiClient object
    def self.load(name)
      couchdb = Chef::CouchDB.new
      couchdb.load("client", name)
    end
    
    # Remove this client from the CouchDB
    #
    # @params [String] The name of the client to delete
    # @return [Chef::ApiClient] The last version of the object
    def destroy
      @couchdb.delete("client", @name, @couchdb_rev)
    end
    
    # Save this client to the CouchDB
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

