#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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

require 'chef/log'
require 'chef/node'
require 'chef/resource_definition_list'
require 'chef/recipe'
require 'chef/mixin/convert_to_class_name'

class Chef
  class Cookbook
    include Chef::Mixin::ConvertToClassName
    include Chef::Mixin::Checksum
    include Chef::IndexQueue::Indexable
    
    attr_accessor :definition_files, :template_files, :remote_files,
      :lib_files, :resource_files, :provider_files, :name, :manifest,
      :metadata, :metadata_files, :status, :couchdb_rev, :couchdb
    attr_reader :recipe_files, :attribute_files, :couchdb_id

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
      @attribute_files = Array.new
      @attribute_names = Hash.new
      @definition_files = Array.new
      @template_files = Array.new
      @remote_files = Array.new
      @recipe_files = Array.new
      @recipe_names = Hash.new
      @lib_files = Array.new
      @resource_files = Array.new
      @provider_files = Array.new
      @metadata_files = Array.new
      @couchdb_id = nil
      @couchdb = couchdb || Chef::CouchDB.new
      @couchdb_rev = nil 
      @status = :ready
      @manifest = nil 
      @metadata = {}
    end
    
    def version
      @metadata.version
    end
    
    def version=(new_version)
      @manifest["version"] = new_version
      @metadata.version(new_version)
    end

    def full_name
      "#{name}-#{version}"
    end
    
    # Loads all the library files in this cookbook via require.
    #
    # === Returns
    # true:: Always returns true
    def load_libraries
      @lib_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name} library file: #{file}")
        require file
      end
      true
    end
    
    # Loads all the attribute files in this cookbook within a particular <Chef::Node>.
    #
    # === Parameters
    # node<Chef::Node>:: The Chef::Node to apply the attributes to
    #
    # === Returns
    # node<Chef::Node>:: The updated Chef::Node object
    #
    # === Raises
    # <ArgumentError>:: If the argument is not a kind_of? <Chef::Node>
    def load_attributes(node)
      @attribute_files.each do |file|
        load_attribute_file(file, node)
      end
      node
    end

    def load_attribute_file(file, node)
      Chef::Log.debug("Loading attributes from #{file}")
      node.from_file(file)
    end

    def load_attribute(name, node)
      attr_name = shorten_name(name)
      file = @attribute_files[@attribute_names[attr_name]]
      load_attribute_file(file, node)
      node
    end
    
    # Loads all the resource definitions in this cookbook.
    #
    # === Returns
    # definitions<Hash>: A hash of <Chef::ResourceDefinition> objects, keyed by name.
    def load_definitions
      results = Hash.new
      @definition_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name}'s definitions from #{file}")
        resourcelist = Chef::ResourceDefinitionList.new
        resourcelist.from_file(file)
        results.merge!(resourcelist.defines) do |key, oldval, newval|
          Chef::Log.info("Overriding duplicate definition #{key}, new found in #{file}")
          newval
        end
      end
      results
    end

    # Loads all the resources in this cookbook.
    #
    # === Returns
    # true:: Always returns true
    def load_resources
      @resource_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name}'s resources from #{file}")
        Chef::Resource.build_from_file(name, file)
      end
    end
    
    # Loads all the providers in this cookbook.
    #
    # === Returns
    # true:: Always returns true
    def load_providers
      @provider_files.each do |file|
        Chef::Log.debug("Loading cookbook #{name}'s providers from #{file}")
        Chef::Provider.build_from_file(name, file)
      end
    end
    
    def recipe_files=(*args)
      @recipe_files, @recipe_names = set_with_names(args.flatten)
      @recipe_files
    end

    def attribute_files=(*args)
      @attribute_files, @attribute_names = set_with_names(args.flatten)
      @attribute_files
    end
    
    def recipe?(name)
      lookup_name = name
      if name =~ /(.+)::(.+)/
        cookbook_name = $1
        lookup_name = $2
        return false unless cookbook_name == @name
      end
      @recipe_names.has_key?(lookup_name)
    end
    
    def recipes
      results = Array.new
      @recipe_names.each_key do |rname|
        results << "#{@name}::#{rname}"
      end
      results
    end
    
    def load_recipe(name, node, collection=nil, definitions=nil, cookbook_loader=nil)
      cookbook_name = @name
      recipe_name = shorten_name(name) 
      
      unless @recipe_names.has_key?(recipe_name)
        raise ArgumentError, "Cannot find a recipe matching #{recipe_name} in cookbook #{@name}"
      end
      Chef::Log.debug("Found recipe #{recipe_name} in cookbook #{cookbook_name}") if Chef::Log.debug?
      recipe = Chef::Recipe.new(cookbook_name, recipe_name, node, 
                                collection, definitions, cookbook_loader)
      recipe.from_file(@recipe_files[@recipe_names[recipe_name]])
      recipe
    end

    def segment_files(segment)
      files_list = nil
      case segment
      when :attributes
        files_list = attribute_files
      when :recipes
        files_list = recipe_files
      when :definitions
        files_list = definition_files
      when :libraries
        files_list = lib_files
      when :providers
        files_list = provider_files
      when :resources
        files_list = resource_files
      when :files
        files_list = remote_files
      when :templates
        files_list = template_files
      else
        raise ArgumentError, "segment must be one of :attributes, :recipes, :definitions, :remote_files, :template_files, :resources, :providers or :libraries"
      end
      files_list
    end

    def to_json(*a)
      result = self.manifest ? self.manifest : self.generate_manifest
      result['json_class'] = self.class.name
      result['chef_type'] = 'cookbook'
      result["_rev"] = @couchdb_rev if @couchdb_rev
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

    def display_manifest(&url_generation)
      self.manifest ? self.manifest : self.generate_manifest
      [ 'resources', 'providers', 'recipes', 'definitions', 'libraries', 'attributes', 'files', 'templates' ].each do |segment|
        if manifest.has_key?(segment)
          manifest[segment].each do |segment_item|
            puts segment_item.inspect
            url_options = { :cookbook_id => name.to_s, :segment => segment, :id => segment_item["name"], :cookbook_version => version }
            set_specificity_arguments(segment_item["specificity"], url_options)
            segment_item["uri"] = url_generation.call(url_options)
          end
        end
      end
      manifest
    end

    def set_specificity_arguments(specificity, url_options={})
      case specificity
      when "default"
      when /^host-(.+)$/
        url_options[:fqdn] = $1
      when /^(.+)-(.+)$/
        url_options[:platform] = $1
        url_options[:version] = $2
      when /^(.+)$/
        url_options[:platform] = $1
      end
      url_options
    end

    def generate_manifest(&url_generation)
      response = {
        :recipes => Array.new,
        :definitions => Array.new,
        :libraries => Array.new,
        :attributes => Array.new,
        :files => Array.new,
        :templates => Array.new,
        :resources => Array.new,
        :providers => Array.new
      }

      [ :resources, :providers, :recipes, :definitions, :libraries, :attributes, :files, :templates ].each do |segment|
        segment_files(segment).each do |sf|
          next if File.directory?(sf)

          file_name = nil
          file_url = nil
          file_specificity = nil
          url_options = nil

          if segment == :templates || segment == :files
            mo = sf.match("cookbooks/#{name}/#{segment}/(.+?)/(.+)")
            unless mo
              Chef::Log.debug("Skipping file #{sf}, as it doesn't have a proper segment.")
              next
            end
            specificity = mo[1]
            file_name = mo[2]
            url_options = { :cookbook_id => name.to_s, :segment => segment, :id => file_name, :cookbook_version => version }
            set_specificity_arguments(specificity, url_options)
            file_specificity = specificity
          else
            mo = sf.match("cookbooks/#{name}/#{segment}/(.+)")
            file_name = mo[1]
            url_options = { :cookbook_id => name.to_s, :segment => segment, :id => file_name }
          end

          if url_generation
            file_url = url_generation.call(url_options)
          else
            file_url = nil
          end

          rs = {
            :name => file_name, 
            :uri => file_url, 
            :path => sf.match("cookbooks/#{name}/(#{segment}/.+)")[1],
            :on_disk_path => sf,
            :checksum => checksum(sf)
          }
          rs[:specificity] = file_specificity if file_specificity

          response[segment] << rs 
        end
      end
      response[:cookbook_name] = name.to_s
      response[:metadata] = metadata 
      response[:version] = metadata.version
      response[:name] = full_name 
      @manifest = response
    end

    ##
    # REST API
    ##
    def chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def self.chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def save
      chef_server_rest.put_rest("cookbooks/#{@name}/#{version}", self)
      self
    end
    alias :create :save

    def destroy
      chef_server_rest.delete_rest("cookbooks/#{@name}/#{version}")
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
      (couchdb || Chef::CouchDB.new).delete("cookbook", full_name, @couchdb_rev)
    end

    def cdb_save
      @couchdb_rev = @couchdb.store("cookbook", full_name, self)["rev"]
    end

    def couchdb_id=(value)
      @couchdb_id = value
      self.index_id = value
    end

    private

      def shorten_name(name)
        short_name = nil
        nmatch = name.match(/^(.+?)::(.+)$/)
        short_name = nmatch ? nmatch[2] : name
      end

      def set_with_names(file_list)
        files = file_list
        names = Hash.new
        files.each_index do |i|
          file = files[i]
          case file
          when /(.+\/)(.+).rb$/
            names[$2] = i
          when /(.+).rb$/
            names[$1] = i
          else  
            names[file] = i
          end
        end
        [ files, names ]
      end
    
  end
end
