#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008-2010 Opscode, Inc.
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

require 'chef/log'
require 'chef/node'
require 'chef/resource_definition_list'
require 'chef/recipe'

class Chef
  class Cookbook
    include Chef::IndexQueue::Indexable

    attr_accessor :definition_files, :template_files, :remote_files,
      :library_files, :resource_files, :provider_files, :root_files, :name,
      :metadata, :metadata_files, :status, :couchdb_rev, :couchdb
    attr_reader :couchdb_id
    attr_reader :file_vendor

    attr_reader :recipe_filename_by_name
    attr_reader :attribute_filename_by_short_filename
    
    COOKBOOK_SEGMENTS = [ :resources, :providers, :recipes, :definitions, :libraries, :attributes, :files, :templates, :root_files ]
    
    DESIGN_DOCUMENT = {
      "version" => 5,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "cookbook") {
              emit(doc.name, doc);
            }
          }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "cookbook") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        },
        "all_with_version" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "cookbook") {
              emit(doc.cookbook_name, doc.version);
            }
          }
          EOJS
        },
        "all_latest_version" => {
          "map" => %q@
          function(doc) { 
            if (doc.chef_type == "cookbook") {
              emit(doc.cookbook_name, doc.version);
            }
          }
          @,
          "reduce" => %q@
          function(keys, values, rereduce) {
            var result = null;

            for (var idx in values) {
              var value = values[idx];
              
              if (idx == 0) {
                result = value;
                continue;
              }
              
              var valueParts = value[1].split('.').map(function(v) { return parseInt(v); });
              var resultParts = result[1].split('.').map(function(v) { return parseInt(v); });

              if (valueParts[0] != resultParts[0]) {
                if (valueParts[0] > resultParts[0]) {
                  result = value;
                }
              }
              else if (valueParts[1] != resultParts[1]) {
                if (valueParts[1] > resultParts[1]) {
                  result = value;
                }
              }
              else if (valueParts[2] != resultParts[2]) {
                if (valueParts[2] > resultParts[2]) {
                  result = value;
                }
              }
            }
            return result;
          }
          @
        },
      }
    }
    
    # Creates a new Chef::Cookbook object.  
    #
    # === Returns
    # object<Chef::Cookbook>:: Duh. :)
    def initialize(name, couchdb=nil)
      @name = name
#       @attribute_files = Array.new
#       @attribute_names = Hash.new
#       @definition_files = Array.new
#       @template_files = Array.new
#       @remote_files = Array.new
#       @recipe_files = Array.new
#       @recipe_names = Hash.new
#       @lib_files = Array.new
#       @resource_files = Array.new
#       @provider_files = Array.new
#       @metadata_files = Array.new
      @couchdb_id = nil
      @couchdb = couchdb || Chef::CouchDB.new
      @couchdb_rev = nil
      @status = :ready
      @manifest = nil
      @file_vendor = nil
      @metadata = {}
    end

    def version
      metadata.version
    end
    
    def version=(new_version)
      manifest["version"] = new_version
      metadata.version(new_version)
    end

    def manifest
      unless @manifest
        generate_manifest
      end
      @manifest
    end
    
    def manifest=(new_manifest)
      self.manifest = new_manifest
      self.checksums = extract_checksums_from_manifest(new_manifest)
    end
    
    # Returns a hash of checksums to either nil or the on disk path (which is
    # done by generate_manifest).
    def checksums
      unless @checksums
        generate_manifest
      end
      @checksums
    end

    def full_name
      "#{name}-#{version}"
    end

    def attribute_filenames=(*filenames)
      self.attribute_filenames = filenames.flatten
      self.attribute_filename_by_short_filename = filenames_by_name(filenames)
      attribute_filenames
    end
    
    # Return recipe names in the form of cookbook_name::recipe_name
    def fully_qualified_recipe_names
      results = Array.new
      recipe_filename_by_name.each_key do |rname|
        results << "#{name}::#{rname}"
      end
      results
    end
    
    def recipe_filenames=(*filenames)
      self.recipe_filenames = filenames.flatten
      self.recipe_filename_by_name = filenames_by_name(filenames)
      recipe_filenames
    end
    
    # called from DSL
    def load_recipe(recipe_name, run_context)
      cookbook_name = self.name
      
      unless recipe_filename_by_name.has_key?(recipe_name)
        raise ArgumentError, "Cannot find a recipe matching #{recipe_name} in cookbook #{name}"
      end
      Chef::Log.debug("Found recipe #{recipe_name} in cookbook #{cookbook_name}")
      recipe = Chef::Recipe.new(cookbook_name, recipe_name, run_context)
      recipe_filename = recipe_filenames_by_name[recipe_name]
      raise Chef::Exceptions::RecipeNotFound, "could not find recipe #{recipe_name} for cookbook #{self.name}" unless recipe_filename
      
      recipe.from_file(recipe_filename)
      recipe
    end

    def segment_filenames(segment)
      raise ArgumentError, "invalid segment #{segment}: must be one of #{COOKBOOK_SEGMENTS.join(', ')}"
      if manifest[segment]
        manifest[segment].map{|segment_file| file_vendor.get_filename(segment_file["path"]) }
      else
        []
      end
    end

    def preferred_filename(node, segment, filename)
      platform, version = Chef::Platform.find_platform_and_version(node)
      fqdn = node[:fqdn]

      # Most specific to least specific places to find the filename
      preferences = [
        File.join("host-#{fqdn}", filename),
        File.join("#{platform}-#{version}", filename),
        File.join(platform, filename),
        File.join("default", filename)
      ]
      
      found_pref = preferences.find{ |preferred_file| manifest[segment.to_s][preferred_file] }
      if found_pref
        manifest_record = manifest[segment.to_s][found_pref]
        file_vendor.get_filename(manifest_record)
      else
        raise Chef::Exceptions::FileNotFound, "cookbook #{name} does not contain file #{segment}/#{filename}"
      end
    end

    def to_json(*a)
      result = manifest.dup
      result['json_class'] = self.class.name
      result['chef_type'] = 'cookbook'
      result["_rev"] = couchdb_rev if couchdb_rev
      result.to_json(*a)
    end

    def self.json_create(o)
      cookbook = new(o["cookbook_name"])
      if o.has_key?('_rev')
        cookbook.couchdb_rev = o["_rev"] if o.has_key?("_rev")
        o.delete("_rev")
      end
      if o.has_key?("_id")
        cookbook.couchdb_id = o["_id"] if o.has_key?("_id")
        cookbook.index_id = cookbook.couchdb_id
        o.delete("_id")
      end
      cookbook.manifest = o
      # We want the Chef::Cookbook::Metadata object to always be inflated
      cookbook.metadata = Chef::Cookbook::Metadata.from_hash(o["metadata"])
      cookbook
    end
    
    # Parses a potentially fully-qualified recipe name into its
    # cookbook name and recipe short name.
    #
    # For example:
    #   "aws::elastic_ip" returns ["aws", "elastic_ip"]
    #   "aws" returns ["aws", "default"]
    def self.parse_recipe_name(recipe_name)
      rmatch = recipe_name.match(/(.+?)::(.+)/)
      if rmatch
        [ rmatch[1], rmatch[2] ]
      else
        [ recipe_name, "default" ]
      end
    end

    def generate_manifest_with_urls(&url_generator)
      rendered_manifest = manifest.dup
      COOKBOOK_SEGMENTS.map{|s|s.to_s}.each do |segment|
        if rendered_manifest.has_key?(segment)
          rendered_manifest[segment].each do |segment_file|
            url_options = { :cookbook_name => name.to_s, :cookbook_version => version, :checksum => segment_file["checksum"] }
            segment_file["uri"] = url_generator.call(url_options)
          end
        end
      end
      rendered_manifest
    end

    ##
    # REST API
    ##
    def chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def save
      chef_server_rest.put_rest("cookbooks/#{name}/#{version}", self)
      self
    end
    alias :create :save

    def destroy
      chef_server_rest.delete_rest("cookbooks/#{name}/#{version}")
      self
    end

    def self.load(name, version="_latest")
      version = "_latest" if version == "latest"
      Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("cookbooks/#{name}/#{version}")
    end

    ##
    # Couchdb
    ##
    
    def self.cdb_by_version(cookbook_name=nil, couchdb=nil)
      cdb = couchdb || Chef::CouchDB.new
      options = cookbook_name ? { :startkey => cookbook_name, :endkey => cookbook_name } : {}
      rs = cdb.get_view("cookbooks", "all_with_version", options)
      rs["rows"].inject({}) { |memo, row| memo.has_key?(row["key"]) ? memo[row["key"]] << row["value"] : memo[row["key"]] = [ row["value"] ]; memo }
    end

    def self.create_design_document(couchdb=nil)
      (couchdb || Chef::CouchDB.new).create_design_document("cookbooks", DESIGN_DOCUMENT)
    end
    
    def self.cdb_list(inflate=false, couchdb=nil)
      rs = (couchdb || Chef::CouchDB.new).list("cookbooks", inflate)
      lookup = (inflate ? "value" : "key")
      rs["rows"].collect { |r| r[lookup] }            
    end

    def self.cdb_load(name, version='latest', couchdb=nil)
      cdb = couchdb || Chef::CouchDB.new
      if version == "latest" || version == "_latest"
        rs = cdb.get_view("cookbooks", "all_latest_version", :key => name, :descending => true, :group => true, :reduce => true)["rows"].first
        cdb.load("cookbook", "#{rs["key"]}-#{rs["value"]}")
      else
        cdb.load("cookbook", "#{name}-#{version}")
      end
    end

    def cdb_destroy
      (couchdb || Chef::CouchDB.new).delete("cookbook", full_name, couchdb_rev)
    end

    def cdb_save
      self.couchdb_rev = couchdb.store("cookbook", full_name, self)["rev"]
    end

    def couchdb_id=(value)
      self.couchdb_id = value
      self.index_id = value
    end

    private
    
    # for each filename, produce a mapping of base filename (i.e. recipe name or attribute file) to on disk location
    def filenames_by_name(filenames)
      filenames.select{|filename| filename =~ /\.rb$/}.inject({}){|memo, filename| memo[File.basename(filename, '.rb')] = filename ; memo }
    end
    
    def generate_manifest
      manifest = {
        :recipes => Array.new,
        :definitions => Array.new,
        :libraries => Array.new,
        :attributes => Array.new,
        :files => Array.new,
        :templates => Array.new,
        :resources => Array.new,
        :providers => Array.new,
        :root_files => Array.new
      }
      checksums_to_on_disk_paths = {}

      COOKBOOK_SEGMENTS.each do |segment|
        segment_filenames(segment).each do |segment_file|
          next if File.directory?(segment_file)

          file_name = nil
          path = nil
          specificity = "default"

          if segment == :root_files
            matcher = segment_file.match("/#{name}/(.+)")
            file_name = matcher[1]
            path = file_name
          elsif segment == :templates || segment == :files
            matcher = segment_file.match("/#{name}/(#{segment}/(.+?)/(.+))")
            unless matcher
              Chef::Log.debug("Skipping file #{segment_file}, as it doesn't have a proper segment.")
              next
            end
            path = matcher[1]
            specificity = matcher[2]
            file_name = matcher[3]
          else
            matcher = segment_file.match("/#{name}/(#{segment}/(.+))")
            path = matcher[1]
            file_name = matcher[2]
          end

          csum = checksum(segment_file)
          checksums_to_on_disk_paths[csum] = segment_file
          rs = {
            :name => file_name,
            :path => path,
            :checksum => csum
          }
          rs[:specificity] = specificity

          manifest[segment] << rs
        end
      end

      manifest[:cookbook_name] = name.to_s
      manifest[:metadata] = metadata
      manifest[:version] = metadata.version
      manifest[:name] = full_name

      self.checksums = checksums_to_on_disk_paths
      self.file_vendor = Chef::CookbookFileVendor.new(manifest)
      self.manifest = manifest
    end

    def extract_checksums_from_manifest(manifest)
      checksums = {}
      COOKBOOK_SEGMENTS.map{|s|s.to_s}.each do |segment|
        next unless manifest.has_key?(segment)
        manifest[segment].each do |segment_file|
          checksums[segment_file["checksum"]] = nil
        end
      end
      checksums
    end
  end
end
