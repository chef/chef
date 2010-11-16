#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Author:: Seth Falcon (<sseth@opscode.com>)
# Copyright:: Copyright 2010 Opscode, Inc.
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
require 'chef/index_queue'


class Chef
  class Environment

    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::FromFile
    include Chef::IndexQueue::Indexable


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
      @attributes = Mash.new
      @cookbook_versions = Hash.new
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

    def attributes(arg=nil)
      set_or_return(
        :attributes,
        arg,
        :kind_of => Hash
      )
    end
    
    def cookbook_versions(arg=nil)
      set_or_return(
        :cookbook_versions,
        arg,
        {
          :kind_of => Hash,
          :callbacks => {
            "should be a valid set of cookbook version requirements" => lambda { |cv| Chef::Environment.validate_cookbook_versions(cv) }
          }
        }
      )
    end

    def cookbook(cookbook, version)
      validate({
        :version => version
      },{
        :version => {
          :callbacks => { "should be a valid version requirement" => lambda { |v| Chef::Environment.validate_cookbook_version(v) } }
        }
      })
      @cookbook_versions[cookbook] = version
    end

    def to_hash
      result = {
        "name" => @name,
        "description" => @description,
        "cookbook_versions" =>  @cookbook_versions,
        "json_class" => self.class.name,
        "chef_type" => "environment",
        "attributes" => @attributes
      }
      result["_rev"] = couchdb_rev if couchdb_rev
      result
    end

    def to_json(*a)
      to_hash.to_json(*a)
    end

    def update_from!(o)
      description(o.description)
      cookbook_versions(o.cookbook_versions)
      attributes(o.attributes)
      self
    end

    def self.json_create(o)
      environment = new
      environment.name(o["name"])
      environment.description(o["description"])
      environment.cookbook_versions(o["cookbook_versions"])
      environment.attributes(o["attributes"])
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

    # Loads the set of Chef::CookbookVersion objects available to a given environment
    # === Returns
    # Hash
    # i.e.
    # {
    #   "coobook_name" => [ Chef::CookbookVersion ... ] ## the array of CookbookVersions is sorted lowest to highest
    # }
    def self.cdb_load_filtered_cookbook_versions(name, couchdb=nil)
      cvs = begin
              Chef::Environment.cdb_load(name, couchdb).cookbook_versions.inject({}) {|res, (k,v)| res[k] = Chef::VersionConstraint.new(v); res}
            rescue Chef::Exceptions::CouchDBNotFound => e
              raise e
            end

      # inject all cookbooks into the hash while filtering out restricted versions, then sort the individual arrays
      Chef::CookbookVersion.cdb_list(true, couchdb).inject({}) {|res, cookbook|
        # FIXME: should cookbook.version return a Chef::Version?
        version               = Chef::Version.new(cookbook.version)
        requirement_satisfied = cvs.has_key?(cookbook.name) ? cvs[cookbook.name].include?(version) : true
        res[cookbook.name]    = (res[cookbook.name] || []) << cookbook if requirement_satisfied
        res
      }.inject({}) {|res, (cookbook_name, versions)|
        res[cookbook_name] = versions.sort
        res
      }
    end

    def to_s
      @name
    end

    def self.validate_cookbook_versions(cv)
      return false unless cv.kind_of?(Hash)
      cv.each do |cookbook, version|
        return false unless Chef::Environment.validate_cookbook_version(version)
      end
      true
    end

    def self.validate_cookbook_version(version)
      begin
        Chef::VersionConstraint.new version
        true
      rescue ArgumentError
        false
      end
    end

    def self.create_default_environment(couchdb=nil)
      couchdb = couchdb || Chef::CouchDB.new
      begin
        Chef::Environment.cdb_load('_default', couchdb)
      rescue Chef::Exceptions::CouchDBNotFound
        env = Chef::Environment.new(couchdb)
        env.name '_default'
        env.description 'The default Chef environment'
        env.cdb_save
      end
    end
  end
end
