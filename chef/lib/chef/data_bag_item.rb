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

require 'chef/config'
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/couchdb'
require 'extlib'
require 'json'

class Chef
  class DataBagItem
    
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    
    DESIGN_DOCUMENT = {
      "version" => 1,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "data_bag_item") {
              emit(doc.name, doc);
            }
          }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "data_bag_item") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        }
      }
    }

    attr_accessor :couchdb_rev, :raw_data
    
    # Create a new Chef::DataBagItem
    def initialize(couchdb=nil)
      @couchdb_rev = nil
      @data_bag = nil
      @raw_data = Hash.new
      @couchdb = Chef::CouchDB.new 
    end

    def raw_data
      @raw_data
    end

    def raw_data=(new_data)
      unless new_data.kind_of?(Hash) || new_data.kind_of?(Mash)
        raise ArgumentError, "Data Bag Items must contain a Hash or Mash!"
      end
      unless new_data.has_key?("id")
        raise ArgumentError, "Data Bag Items must have an id key in the hash! #{new_data.inspect}"
      end
      unless new_data["id"] =~ /^[\-[:alnum:]_]+$/
        raise ArgumentError, "Data Bag Item id does not match alphanumeric/-/_!"
      end
      @raw_data = new_data
    end

    def data_bag(arg=nil) 
      set_or_return(
        :data_bag,
        arg,
        :regex => /^[\-[:alnum:]_]+$/
      )
    end

    def name
      object_name
    end

    def object_name
      if raw_data.has_key?('id')
        id = raw_data['id']
      else
        raise ArgumentError, "You must have an 'id' or :id key in the raw data"
      end
     
      data_bag_name = self.data_bag
      unless data_bag_name
        raise ArgumentError, "You must have declared what bag this item belongs to!"
      end
      "data_bag_item_#{data_bag_name}_#{id}"
    end

    def self.object_name(data_bag_name, id)
      "data_bag_item_#{data_bag_name}_#{id}"
    end

    def to_hash
      result = self.raw_data
      result["chef_type"] = "data_bag_item"
      result["data_bag"] = self.data_bag
      result["_rev"] = @couchdb_rev if @couchdb_rev
      result
    end

    # Serialize this object as a hash 
    def to_json(*a)
      result = {
        "name" => self.object_name,
        "json_class" => self.class.name,
        "chef_type" => "data_bag_item",
        "data_bag" => self.data_bag,
        "raw_data" => self.raw_data
      }
      result["_rev"] = @couchdb_rev if @couchdb_rev
      result.to_json(*a)
    end
    
    # Create a Chef::DataBagItem from JSON
    def self.json_create(o)
      bag_item = new
      bag_item.data_bag(o["data_bag"])
      o.delete("data_bag")
      o.delete("chef_type")
      o.delete("json_class")
      o.delete("name")
      if o.has_key?("_rev")
        bag_item.couchdb_rev = o["_rev"] 
        o.delete("_rev")
      end
      bag_item.raw_data = o["raw_data"]
      bag_item
    end

    # The Data Bag Item behaves like a hash - we pass all that stuff along to @raw_data.
    def method_missing(method_symbol, *args, &block) 
      self.raw_data.send(method_symbol, *args, &block)
    end
    
    # Load a Data Bag Item by name from CouchDB
    def self.load(data_bag, name)
      couchdb = Chef::CouchDB.new
      couchdb.load("data_bag_item", object_name(data_bag, name))
    end
    
    # Remove this Data Bag Item from CouchDB
    def destroy
      removed = @couchdb.delete("data_bag_item", object_name, @couchdb_rev)
      removed
    end
    
    # Save this Data Bag Item to CouchDB
    def save
      results = @couchdb.store("data_bag_item", object_name, self)
      @couchdb_rev = results["rev"]
    end
    
    # Set up our CouchDB design document
    def self.create_design_document
      couchdb = Chef::CouchDB.new
      couchdb.create_design_document("data_bag_items", DESIGN_DOCUMENT)
    end
    
    # As a string
    def to_s
      "data_bag_item[#{@name}]"
    end

  end
end


