#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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
require 'chef/mash'
require 'chef/json_compat'
require 'chef/search/query'

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

    attr_accessor :couchdb_rev, :couchdb
    attr_reader :couchdb_id

    # Create a new Chef::Role object.
    def initialize(couchdb=nil)
      @name = ''
      @description = ''
      @default_attributes = Mash.new
      @override_attributes = Mash.new
      @env_run_lists = {"_default" => Chef::RunList.new}
      @couchdb_rev = nil
      @couchdb_id = nil
      @couchdb = couchdb || Chef::CouchDB.new
    end

    def couchdb_id=(value)
      @couchdb_id = value
      self.index_id = value
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
      if (args.length > 0)
        @env_run_lists["_default"].reset!(args)
      end
      @env_run_lists["_default"]
    end

    alias_method :recipes, :run_list

    # For run_list expansion
    def run_list_for(environment)
      if env_run_lists[environment].nil?
        env_run_lists["_default"]
      else
        env_run_lists[environment]
      end
    end

    def active_run_list_for(environment)
      @env_run_lists.has_key?(environment) ? environment : '_default'
    end

    # Per environment run lists
    def env_run_lists(env_run_lists=nil)
      if (!env_run_lists.nil?)
        unless env_run_lists.key?("_default")
          msg = "_default key is required in env_run_lists.\n"
          msg << "(env_run_lists: #{env_run_lists.inspect})"
          raise Chef::Exceptions::InvalidEnvironmentRunListSpecification, msg
        end
        @env_run_lists.clear
        env_run_lists.each { |k,v| @env_run_lists[k] = Chef::RunList.new(*Array(v))}
      end
      @env_run_lists
    end

    alias :env_run_list :env_run_lists

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
      env_run_lists_without_default = @env_run_lists.dup
      env_run_lists_without_default.delete("_default")
      result = {
        "name" => @name,
        "description" => @description,
        'json_class' => self.class.name,
        "default_attributes" => @default_attributes,
        "override_attributes" => @override_attributes,
        "chef_type" => "role",
        "run_list" => run_list,
        "env_run_lists" => env_run_lists_without_default
      }
      result["_rev"] = couchdb_rev if couchdb_rev
      result
    end

    # Serialize this object as a hash
    def to_json(*a)
      to_hash.to_json(*a)
    end

    def update_from!(o)
      description(o.description)
      recipes(o.recipes) if defined?(o.recipes)
      default_attributes(o.default_attributes)
      override_attributes(o.override_attributes)
      env_run_lists(o.env_run_lists) unless o.env_run_lists.nil?
      self
    end

    # Create a Chef::Role from JSON
    def self.json_create(o)
      role = new
      role.name(o["name"])
      role.description(o["description"])
      role.default_attributes(o["default_attributes"])
      role.override_attributes(o["override_attributes"])

      # _default run_list is in 'run_list' for newer clients, and
      # 'recipes' for older clients.
      env_run_list_hash = {"_default" => (o.has_key?("run_list") ? o["run_list"] : o["recipes"])}

      # Clients before 0.10 do not include env_run_lists, so only
      # merge if it's there.
      if o["env_run_lists"]
        env_run_list_hash.merge!(o["env_run_lists"])
      end
      role.env_run_lists(env_run_list_hash)

      role.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      role.index_id = role.couchdb_id
      role.couchdb_id = o["_id"] if o.has_key?("_id")
      role
    end

    # List all the Chef::Role objects in the CouchDB.  If inflate is set to true, you will get
    # the full list of all Roles, fully inflated.
    def self.cdb_list(inflate=false, couchdb=nil)
      rs = (couchdb || Chef::CouchDB.new).list("roles", inflate)
      lookup = (inflate ? "value" : "key")
      rs["rows"].collect { |r| r[lookup] }
    end

    # Get the list of all roles from the API.
    def self.list(inflate=false)
      if inflate
        response = Hash.new
        Chef::Search::Query.new.search(:role) do |n|
          response[n.name] = n unless n.nil?
        end
        response
      else
        chef_server_rest.get_rest("roles")
      end
    end

    # Load a role by name from CouchDB
    def self.cdb_load(name, couchdb=nil)
      (couchdb || Chef::CouchDB.new).load("role", name)
    end

    # Load a role by name from the API
    def self.load(name)
      chef_server_rest.get_rest("roles/#{name}")
    end

    def self.exists?(rolename, couchdb)
      begin
        self.cdb_load(rolename, couchdb)
      rescue Chef::Exceptions::CouchDBNotFound
        nil
      end
    end

    def environment(env_name)
      chef_server_rest.get_rest("roles/#{@name}/environments/#{env_name}")
    end

    def environments
      chef_server_rest.get_rest("roles/#{@name}/environments")
    end

    # Remove this role from the CouchDB
    def cdb_destroy
      couchdb.delete("role", @name, couchdb_rev)
    end

    # Remove this role via the REST API
    def destroy
      chef_server_rest.delete_rest("roles/#{@name}")
    end

    # Save this role to the CouchDB
    def cdb_save
      self.couchdb_rev = couchdb.store("role", @name, self)["rev"]
    end

    # Save this role via the REST API
    def save
      begin
        chef_server_rest.put_rest("roles/#{@name}", self)
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        chef_server_rest.post_rest("roles", self)
      end
      self
    end

    # Create the role via the REST API
    def create
      chef_server_rest.post_rest("roles", self)
      self
    end

    # Set up our CouchDB design document
    def self.create_design_document(couchdb=nil)
      (couchdb || Chef::CouchDB.new).create_design_document("roles", DESIGN_DOCUMENT)
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
        # from_json returns object.class => json_class in the JSON.
        Chef::JSONCompat.from_json(IO.read(js_file))
      elsif File.exists?(rb_file) || force == "ruby"
        role = Chef::Role.new
        role.name(name)
        role.from_file(rb_file)
        role
      else
        raise Chef::Exceptions::RoleNotFound, "Role '#{name}' could not be loaded from disk"
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
