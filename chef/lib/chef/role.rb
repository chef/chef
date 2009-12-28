#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
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
require 'chef/run_list'
require 'chef/index_queue'
require 'extlib'
require 'json'

class Chef
  class Role 
    
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    include Chef::IndexQueue::Indexable
    
    DESIGN_DOCUMENT = {
      "version" => 6,
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
        }
      }
    }

    attr_accessor :couchdb_rev, :couchdb_id
    
    # Create a new Chef::Role object.
    def initialize
      @name = '' 
      @description = '' 
      @default_attributes = Mash.new
      @override_attributes = Mash.new
      @run_list = Chef::RunList.new 
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

    def description(arg=nil) 
      set_or_return(
        :description,
        arg,
        :kind_of => String
      )
    end

    def run_list(*args)
      if args.length > 0
        @run_list.reset(args)
      else
        @run_list
      end
    end
        
    def recipes(*args) 
      if args.length > 0
        @run_list.reset(args)
      else
        @run_list.recipes
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
        "run_list" => @run_list.run_list
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
      if o.has_key?("run_list")
        role.run_list(o["run_list"]) if o.has_key?("run_list")
      else
        role.run_list(o["recipes"]) 
      end
      role.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      role.couchdb_id = o["_id"] if o.has_key?("_id")
      role 
    end
    
    # List all the Chef::Role objects in the CouchDB.  If inflate is set to true, you will get
    # the full list of all Roles, fully inflated.
    def self.cdb_list(inflate=false)
      couchdb = Chef::CouchDB.new
      rs = couchdb.list("roles", inflate)
      if inflate
        rs["rows"].collect { |r| r["value"] }
      else
        rs["rows"].collect { |r| r["key"] }
      end
    end

    # Get the list of all roles from the API.
    def self.list(inflate=false)
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      if inflate
        response = Hash.new
        Chef::Search::Query.new.search(:role) do |n|
          response[n.name] = n unless n.nil?
        end
        response
      else
        r.get_rest("roles")
      end
    end
    
    # Load a role by name from CouchDB
    def self.cdb_load(name)
      couchdb = Chef::CouchDB.new
      couchdb.load("role", name)
    end
    
    # Load a role by name from the API
    def self.load(name)
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      r.get_rest("roles/#{name}")
    end
    
    # Remove this role from the CouchDB
    def cdb_destroy
      @couchdb.delete("role", @name, @couchdb_rev)

      if Chef::Config[:couchdb_version] == 0.9
        rs = @couchdb.get_view("nodes", "by_run_list", :startkey => "role[#{@name}]", :endkey => "role[#{@name}]", :include_docs => true)
        rs["rows"].each do |row| 
          node = row["doc"]
          node.run_list.remove("role[#{@name}]")
          node.cdb_save
        end
      else
       Chef::Node.cdb_list.each do |node|
         n = Chef::Node.cdb_load(node)
         n.run_list.remove("role[#{@name}]")
         n.cdb_save
       end
      end
    end
    
    # Remove this role via the REST API
    def destroy
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      r.delete_rest("roles/#{@name}")
      
      Chef::Node.list.each do |node|
        n = Chef::Node.load(node[0])
        n.run_list.remove("role[#{@name}]")
        n.save
      end
      
    end
    
    # Save this role to the CouchDB
    def cdb_save
      results = @couchdb.store("role", @name, self)
      @couchdb_rev = results["rev"]
    end
    
    # Save this role via the REST API
    def save
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      begin
        r.put_rest("roles/#{@name}", self)
      rescue Net::HTTPServerException => e
        if e.response.code == "404"
          r.post_rest("roles", self)
        else
          raise e
        end
      end
      self
    end
    
    # Create the role via the REST API
    def create
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      r.post_rest("roles", self)
      self
    end 
    
    # Set up our CouchDB design document
    def self.create_design_document
      couchdb = Chef::CouchDB.new
      couchdb.create_design_document("roles", DESIGN_DOCUMENT)
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
          couch_role = Chef::Role.cdb_load(short_name)
          r.couchdb_rev = couch_role.couchdb_rev
          Chef::Log.debug("Replacing role #{short_name} with data from #{role_file}")
        rescue Chef::Exceptions::CouchDBNotFound 
          Chef::Log.debug("Creating role #{short_name} with data from #{role_file}")
        end
        r.cdb_save
      end
    end

  end
end
