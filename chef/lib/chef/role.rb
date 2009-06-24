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
  class Role 
    
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    
    DESIGN_DOCUMENT = {
      "version" => 3,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "role") {
              emit(doc.name, doc);
            }
          }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "role") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        },
      },
    }

    attr_accessor :couchdb_rev
    
    # Create a new Chef::Role object.
    def initialize()
      @name = '' 
      @description = '' 
      @default_attributes = Mash.new
      @override_attributes = Mash.new
      @recipes = Array.new 
      @couchdb_rev = nil
      @couchdb = Chef::CouchDB.new
    end

    def name(arg=nil) 
      set_or_return(
        :name,
        arg,
        :regex => /^[\-[:alnum:]_]+$/
      )
    end

    def description(arg=nil) 
      set_or_return(
        :description,
        arg,
        :kind_of => String
      )
    end

    def recipes(*arg) 
      arg.flatten!
      if arg.length == 0
        @recipes
      else
        arg.each do |entry|
          raise ArgumentError, 'Recipes must be strings!' unless entry.kind_of?(String)
        end
        @recipes = arg
      end
    end

    def default_attributes(arg=nil)
      set_or_return(
        :default_attributes,
        arg,
        :kind_of => Hash
      )
    end

    def override_attributes(arg=nil)
      set_or_return(
        :override_attributes,
        arg,
        :kind_of => Hash
      )
    end

    def to_hash
      result = {
        "name" => @name,
        "description" => @description,
        'json_class' => self.class.name,
        "default_attributes" => @default_attributes,
        "override_attributes" => @override_attributes,
        "chef_type" => "role",
        "recipes" => @recipes,
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
      role = new
      role.name(o["name"])
      role.description(o["description"])
      role.default_attributes(o["default_attributes"])
      role.override_attributes(o["override_attributes"])
      role.recipes(o["recipes"])
      role.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      role 
    end
    
    # List all the Chef::Role objects in the CouchDB.  If inflate is set to true, you will get
    # the full list of all Roles, fully inflated.
    def self.list(inflate=false)
      rs = Chef::CouchDB.new.list("roles", inflate)
      if inflate
        rs["rows"].collect { |r| r["value"] }
      else
        rs["rows"].collect { |r| r["key"] }
      end
    end
    
    # Load a role by name from CouchDB
    def self.load(name)
      Chef::CouchDB.new.load("role", name)
    end
    
    # Remove this role from the CouchDB
    def destroy
      @couchdb.delete("role", @name, @couchdb_rev)

      if Chef::Config[:couchdb_version] == 0.9
        rs = @couchdb.get_view("nodes", "by_run_list", :startkey => "role[#{@name}]", :endkey => "role[#{@name}]", :include_docs => true)
        rs["rows"].each do |row| 
          node = row["doc"]
          node.run_list.remove("role[#{@name}]")
          node.save
        end
      else
       Chef::Node.list.each do |node|
         n = Chef::Node.load(node)
         n.run_list.remove("role[#{@name}]")
         n.save
       end
      end
    end
    
    # Save this role to the CouchDB
    def save
      results = @couchdb.store("role", @name, self)
      @couchdb_rev = results["rev"]
    end
    
    # Set up our CouchDB design document
    def self.create_design_document
      Chef::CouchDB.new.create_design_document("roles", DESIGN_DOCUMENT)
    end
    
    # As a string
    def to_s
      "role[#{@name}]"
    end

    # Load a role from disk - prefers to load the JSON, but will happily load
    # the raw rb files as well.
    def self.from_disk(name, force=nil)
      js_file = File.join(Chef::Config[:role_path], "#{name}.json")
      rb_file = File.join(Chef::Config[:role_path], "#{name}.rb")

      if File.exists?(js_file) || force == "json"
        JSON.parse(IO.read(js_file))
      elsif File.exists?(rb_file) || force == "ruby"
        role = Chef::Role.new
        role.name(name)
        role.from_file(rb_file)
        role
      end
    end

    # Sync all the json roles with couchdb from disk
    def self.sync_from_disk_to_couchdb
      Dir[File.join(Chef::Config[:role_path], "*.json")].each do |role_file|
        short_name = File.basename(role_file, ".json") 
        Chef::Log.warn("Loading #{short_name}")
        r = Chef::Role.from_disk(short_name, "json")
        begin
          couch_role = Chef::Role.load(short_name)
          r.couchdb_rev = couch_role.couchdb_rev
          Chef::Log.debug("Replacing role #{short_name} with data from #{role_file}")
        rescue Net::HTTPServerException
          Chef::Log.debug("Creating role #{short_name} with data from #{role_file}")
        end
        r.save
      end
    end

  end
end
