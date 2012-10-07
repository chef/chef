#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: John Keiser (<jkeiser@ospcode.com>)
# Copyright:: Copyright 2010-2011 Opscode, Inc.
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
require 'chef/mash'
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/couchdb'
require 'chef/index_queue'
require 'chef/version_constraint'

class Chef
  class Environment

    DEFAULT = "default"

    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::FromFile
    include Chef::IndexQueue::Indexable

    COMBINED_COOKBOOK_CONSTRAINT = /(.+)(?:[\s]+)((?:#{Chef::VersionConstraint::OPS.join('|')})(?:[\s]+).+)$/.freeze

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
      @default_attributes = Mash.new
      @override_attributes = Mash.new
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

    def default_attributes(arg=nil)
      set_or_return(
        :default_attributes,
        arg,
        :kind_of => Hash
      )
    end

    def default_attributes=(attrs)
      default_attributes(attrs)
    end

    def override_attributes(arg=nil)
      set_or_return(
        :override_attributes,
        arg,
        :kind_of => Hash
      )
    end

    def override_attributes=(attrs)
      override_attributes(attrs)
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
        "default_attributes" => @default_attributes,
        "override_attributes" => @override_attributes
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
      default_attributes(o.default_attributes)
      override_attributes(o.override_attributes)
      self
    end


    def update_attributes_from_params(params)
      unless params[:default_attributes].nil? || params[:default_attributes].size == 0
        default_attributes(Chef::JSONCompat.from_json(params[:default_attributes]))
      end
      unless params[:override_attributes].nil? || params[:override_attributes].size == 0
        override_attributes(Chef::JSONCompat.from_json(params[:override_attributes]))
      end
    end

    def update_from_params(params)
      # reset because everything we need will be in the params, this is necessary because certain constraints
      # may have been removed in the params and need to be removed from cookbook_versions as well.
      bkup_cb_versions = cookbook_versions
      cookbook_versions(Hash.new)
      valid = true

      begin
        name(params[:name])
      rescue Chef::Exceptions::ValidationFailed => e
        invalid_fields[:name] = e.message
        valid = false
      end
      description(params[:description])

      unless params[:cookbook_version].nil?
        params[:cookbook_version].each do |index, cookbook_constraint_spec|
          unless (cookbook_constraint_spec.nil? || cookbook_constraint_spec.size == 0)
            valid = valid && update_cookbook_constraint_from_param(index, cookbook_constraint_spec)
          end
        end
      end

      update_attributes_from_params(params)

      valid = validate_required_attrs_present && valid
      cookbook_versions(bkup_cb_versions) unless valid # restore the old cookbook_versions if valid is false
      valid
    end

    def update_cookbook_constraint_from_param(index, cookbook_constraint_spec)
      valid = true
      md = cookbook_constraint_spec.match(COMBINED_COOKBOOK_CONSTRAINT)
      if md.nil? || md[2].nil?
        valid = false
        add_cookbook_constraint_error(index, cookbook_constraint_spec)
      elsif self.class.validate_cookbook_version(md[2])
        cookbook_versions[md[1]] = md[2]
      else
        valid = false
        add_cookbook_constraint_error(index, cookbook_constraint_spec)
      end
      valid
    end

    def add_cookbook_constraint_error(index, cookbook_constraint_spec)
      invalid_fields[:cookbook_version] ||= {}
      invalid_fields[:cookbook_version][index] = "#{cookbook_constraint_spec} is not a valid cookbook constraint"
    end

    def invalid_fields
      @invalid_fields ||= {}
    end

    def validate_required_attrs_present
      if name.nil? || name.size == 0
        invalid_fields[:name] ||= "name cannot be empty"
        false
      else
        true
      end
    end


    def self.json_create(o)
      environment = new
      environment.name(o["name"])
      environment.description(o["description"])
      environment.cookbook_versions(o["cookbook_versions"])
      environment.default_attributes(o["default_attributes"])
      environment.override_attributes(o["override_attributes"])
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
        response = Hash.new
        Chef::Search::Query.new.search(:environment) do |e|
          response[e.name] = e unless e.nil?
        end
        response
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
    #   "cookbook_name" => [ Chef::CookbookVersion ... ] ## the array of CookbookVersions is sorted highest to lowest
    # }
    #
    # There will be a key for every cookbook.  If no CookbookVersions
    # are available for the specified environment the value will be an
    # empty list.
    #
    def self.cdb_load_filtered_cookbook_versions(name, couchdb=nil)
      version_constraints = cdb_load(name, couchdb).cookbook_versions.inject({}) {|res, (k,v)| res[k] = Chef::VersionConstraint.new(v); res}

      # inject all cookbooks into the hash while filtering out restricted versions, then sort the individual arrays
      cookbook_list = Chef::CookbookVersion.cdb_list(true, couchdb)

      filtered_list = cookbook_list.inject({}) do |res, cookbook|
        # FIXME: should cookbook.version return a Chef::Version?
        version               = Chef::Version.new(cookbook.version)
        requirement_satisfied = version_constraints.has_key?(cookbook.name) ? version_constraints[cookbook.name].include?(version) : true
        # we want a key for every cookbook, even if no versions are available
        res[cookbook.name] ||= []
        res[cookbook.name] << cookbook if requirement_satisfied
        res
      end

      sorted_list = filtered_list.inject({}) do |res, (cookbook_name, versions)|
        res[cookbook_name] = versions.sort.reverse
        res
      end

      sorted_list
    end

    # Like +cdb_load_filtered_cookbook_versions+, loads the set of
    # cookbooks available in a given environment. The difference is that
    # this method will load Chef::MinimalCookbookVersion objects that
    # contain only the information necessary for solving a cookbook
    # collection for a given run list. The user of this method must call
    # Chef::MinimalCookbookVersion.load_full_versions_of() after solving
    # the cookbook collection to get the full objects.
    # === Returns
    # Hash
    # i.e.
    # {
    #   "cookbook_name" => [ Chef::CookbookVersion ... ] ## the array of CookbookVersions is sorted highest to lowest
    # }
    #
    # There will be a key for every cookbook.  If no CookbookVersions
    # are available for the specified environment the value will be an
    # empty list.
    def self.cdb_minimal_filtered_versions(name, couchdb=nil)
      version_constraints = cdb_load(name, couchdb).cookbook_versions.inject({}) {|res, (k,v)| res[k] = Chef::VersionConstraint.new(v); res}

      # inject all cookbooks into the hash while filtering out restricted versions, then sort the individual arrays
      cookbook_list = Chef::MinimalCookbookVersion.load_all(couchdb)

      filtered_list = cookbook_list.inject({}) do |res, cookbook|
        # FIXME: should cookbook.version return a Chef::Version?
        version               = Chef::Version.new(cookbook.version)
        requirement_satisfied = version_constraints.has_key?(cookbook.name) ? version_constraints[cookbook.name].include?(version) : true
        # we want a key for every cookbook, even if no versions are available
        res[cookbook.name] ||= []
        res[cookbook.name] << cookbook if requirement_satisfied
        res
      end

      sorted_list = filtered_list.inject({}) do |res, (cookbook_name, versions)|
        res[cookbook_name] = versions.sort.reverse
        res
      end

      sorted_list
    end

    def self.cdb_load_filtered_recipe_list(name, couchdb=nil)
      cdb_load_filtered_cookbook_versions(name, couchdb).map do |cb_name, cb|
        if cb.empty?            # no available versions
          []                    # empty list elided with flatten
        else
          latest_version = cb.first
          latest_version.recipe_filenames_by_name.keys.map do |recipe|
            case recipe
            when DEFAULT
              cb_name
            else
              "#{cb_name}::#{recipe}"
            end
          end
        end
      end.flatten
    end

    def self.load_filtered_recipe_list(environment)
      chef_server_rest.get_rest("environments/#{environment}/recipes")
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
