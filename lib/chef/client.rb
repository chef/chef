#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "mixin", "params_validate")
require File.join(File.dirname(__FILE__), "mixin", "generate_url")
require File.join(File.dirname(__FILE__), "mixin", "checksum")

require 'rubygems'
require 'facter'

class Chef
  class Client
    
    include Chef::Mixin::GenerateURL
    include Chef::Mixin::Checksum
    
    attr_accessor :node, :registration, :safe_name
    
    # Creates a new Chef::Client.
    def initialize()
      @node = nil
      @safe_name = nil
      @registration = nil
      @rest = Chef::REST.new(Chef::Config[:registration_url])
    end
    
    # Do a full run for this Chef::Client.  Calls:
    # 
    #  * build_node - Get the last known state, merge with local changes
    #  * register - Make sure we have an openid
    #  * authenticate - Authenticate with our openid
    #  * sync_definitions - Populate the local cache with all the definitions
    #  * sync_recipes - Populate the local cache with all the recipes
    #  * do_attribute_files - Populate the local cache with all attributes, and execute them
    #  * save_node - Store the new node configuration
    #  * converge - Bring this system up to date, based on the local cache
    #  * save_node - Store the node again, in case convergence altered future state
    #
    # === Returns
    # true:: Always returns true.
    def run
      build_node
      register
      authenticate
      sync_definitions
      sync_recipes
      do_attribute_files
      save_node
      converge
      save_node
      true
    end
    
    # Builds a new node object for this client.  Starts with querying for the FQDN of the current
    # host (unless it is supplied), then merges in the facts from Facter.
    #
    # === Parameters
    # node_name<String>:: The name of the node to build - defaults to nil
    def build_node(node_name=nil)
      node_name ||= Facter["fqdn"].value ? Facter["fqdn"].value : Facter["hostname"].value
      @safe_name = node_name.gsub(/\./, '_')
      begin
        @node = @rest.get_rest("nodes/#{@safe_name}")
      rescue Net::HTTPServerException => e
        unless e.message =~ /^404/
          raise e
        end
      end
      unless @node
        @node ||= Chef::Node.new
        @node.name(node_name)
      end
      Facter.each do |field, value|
        @node[field] = value
      end
      @node
    end
    
    # If this node has been registered before, this method will fetch the current registration
    # data.
    #
    # If it has not, we register it by calling create_registration.
    def register 
      @registration = nil
      begin
        @registration = @rest.get_rest("registrations/#{@safe_name}")
      rescue Net::HTTPServerException => e
        unless e.message =~ /^404/
          raise e
        end
      end
      
      if @registration
        reg = Chef::FileStore.load("registration", @safe_name)
        @secret = reg["secret"]
      else
        create_registration
      end
    end
    
    # Generates a random secret, stores it in the Chef::Filestore with the "registration" key,
    # and posts our nodes registration information to the server.
    def create_registration
      @secret = random_password(500)
      Chef::FileStore.store("registration", @safe_name, { "secret" => @secret })
      @rest.post_rest("registrations", { :id => @safe_name, :password => @secret })
    end
    
    # Authenticates the node via OpenID.
    def authenticate
      response = @rest.post_rest('openid/consumer/start', { 
        "openid_identifier" => "#{Chef::Config[:openid_url]}/openid/server/node/#{@safe_name}",
        "submit" => "Verify"
      })
      @rest.post_rest(
        "#{Chef::Config[:openid_url]}#{response["action"]}",
        { "password" => @secret }
      )
    end
    
    # Update the file caches for a given cache segment.  Takes a segment name
    # and a hash that matches one of the cookbooks/_attribute_files style
    # remote file listings.
    #
    # === Parameters
    # segment<String>:: The cache segment to update
    # remote_list<Hash>:: A cookbooks/_attribute_files style remote file listing
    def update_file_cache(segment, remote_list)  
      # We need the list of known good attribute files, so we can delete any that are
      # just laying about.
      file_canonical = Hash.new
      
      remote_list.each do |rf|
        cache_file = File.join("cookbooks", rf['cookbook'], segment, rf['name'])
        file_canonical[cache_file] = true
      
        current_checksum = nil
        if Chef::FileCache.has_key?(cache_file)
          current_checksum = checksum(Chef::FileCache.load(cache_file, false))
        end
      
        rf_url = generate_cookbook_url(
          rf['name'], 
          rf['cookbook'], 
          segment, 
          @node, 
          current_checksum ? { 'checksum' => current_checksum } : nil
        )
        Chef::Log.debug(rf_url)
      
        changed = true
        begin
          raw_file = @rest.get_rest(rf_url, true)
        rescue Net::HTTPRetriableError => e
          if e.response.kind_of?(Net::HTTPNotModified)
            changed = false
            Chef::Log.debug("Cache file #{cache_file} is unchanged")
          else
            raise e
          end
        end
      
        if changed
          Chef::Log.debug("Storing updated #{cache_file}")
          Chef::FileCache.move_to(raw_file.path, cache_file)
        end
      end
      
      Chef::FileCache.list.each do |cache_file|
        if cache_file.match("cookbooks/.+?/#{segment}")
          unless file_canonical[cache_file]
            Chef::Log.info("Removing #{cache_file}, as it is no longer a valid.")
            Chef::FileCache.delete(cache_file)
          end
        end
      end
      
    end
    
    # Gets all the attribute files included in all the cookbooks available on the server,
    # and executes them.
    def do_attribute_files
      update_file_cache("attributes", @rest.get_rest('cookbooks/_attribute_files'))
      Chef::FileCache.list.each do |cache_file|
        if cache_file.match("cookbooks/.+?/attributes")
          Chef::Log.debug("Executing #{cache_file}")
          @node.from_file(Chef::FileCache.load(cache_file, false))
        end
      end
      true
    end
    
    def sync_definitions
      update_file_cache("definitions", @rest.get_rest('cookbooks/_definition_files'))
    end
    
    def sync_recipes
      update_file_cache("recipes", @rest.get_rest('cookbooks/_recipe_files'))
    end
    
    # Updates the current node configuration on the server.
    def save_node
      @rest.put_rest("nodes/#{@safe_name}", @node)
    end
    
    # Compiles the full list of recipes for the node from the local cache, and 
    # passes it to an instance of Chef::Runner.converge.
    def converge
      Chef::Config[:cookbook_path] = File.join(Chef::Config[:file_cache_path], "cookbooks")
      compile = Chef::Compile.new()
      compile.node = @node
      compile.load_definitions
      compile.load_recipes

      cr = Chef::Runner.new(@node, compile.collection)
      cr.converge
      true
    end
    
    protected
      # Generates a random password of "len" length.
      def random_password(len)
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        newpass = ""
        1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
        newpass
      end

  end
end