#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require "chef" / "mixin" / "checksum"
require "chef" / "cookbook_loader"

class ChefServerSlice::Application < Merb::Controller

  include Chef::Mixin::Checksum

  controller_for_slice
  
  # Generate the absolute url for a slice - takes the slice's :path_prefix into account.
  #
  # @param slice_name<Symbol> 
  #   The name of the slice - in identifier_sym format (underscored).
  # @param *args<Array[Symbol,Hash]> 
  #   There are several possibilities regarding arguments:
  #   - when passing a Hash only, the :default route of the current 
  #     slice will be used
  #   - when a Symbol is passed, it's used as the route name
  #   - a Hash with additional params can optionally be passed
  # 
  # @return <String> A uri based on the requested slice.
  #
  # @example absolute_slice_url(:awesome, :format => 'html')
  # @example absolute_slice_url(:forum, :posts, :format => 'xml')          
  def absolute_slice_url(slice_name, *args)
    options  = extract_options_from_args!(args) || {}
    protocol = options.delete(:protocol) || request.protocol
    host     = options.delete(:host) || request.host
    
    protocol + "://" + host + slice_url(slice_name,*args)
  end
  
  def fix_up_node_id
    if params.has_key?(:id)
      params[:id].gsub!(/_/, '.')
    end
  end
  
  def escape_node_id(arg=nil)
    unless arg
      arg = params[:id] if params.has_key?(:id)
    end
    arg.gsub(/\./, '_')
  end

  def login_required
    if session[:openid]
      return session[:openid]
    else  
      self.store_location
      throw(:halt, :access_denied)
    end
  end
  
  def authorized_node
    if session[:level] == :admin
      Chef::Log.debug("Authorized as Administrator")
      true
    elsif session[:level] == :node
      Chef::Log.debug("Authorized as node")
      if session[:node_name] == params[:id].gsub(/\./, '_')
        true
      else
        raise(
          Unauthorized,
          "You are not the correct node for this action: #{session[:node_name]} instead of #{params[:id]}"
        )
      end
    else
      Chef::Log.debug("Unauthorized")
      raise Unauthorized, "You are not allowed to take this action."
    end
  end
  
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.uri
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    loc = session[:return_to] || default
    session[:return_to] = nil
    redirect loc
  end
  
  def access_denied
    case content_type
    when :html
      store_location
      redirect slice_url(:openid_consumer), :message => { :error => "You don't have access to that, please login."}
    else
      raise Unauthorized, "You must authenticate first!"
    end
  end
  
  # Load a cookbook and return a hash with a list of all the files of a 
  # given segment (attributes, recipes, definitions, libraries)
  #
  # === Parameters
  # cookbook_id<String>:: The cookbook to load
  # segment<Symbol>:: :attributes, :recipes, :definitions, :libraries
  #
  # === Returns
  # <Hash>:: A hash consisting of the short name of the file in :name, and the full path
  #   to the file in :file.
  def load_cookbook_segment(cookbook_id, segment)
    cl = Chef::CookbookLoader.new
    cookbook = cl[cookbook_id]
    raise NotFound unless cookbook
    
    files_list = segment_files(segment, cookbook)
    
    files = Hash.new
    files_list.each do |f|
      full = File.expand_path(f)
      name = File.basename(full)
      files[name] = {
        :name => name,
        :file => full,
      }
    end
    files
  end
  
  def segment_files(segment, cookbook)
    files_list = nil
    case segment
    when :attributes
      files_list = cookbook.attribute_files
    when :recipes
      files_list = cookbook.recipe_files
    when :definitions
      files_list = cookbook.definition_files
    when :libraries
      files_list = cookbook.lib_files
    when :providers
      files_list = cookbook.provider_files
    when :resources
      files_list = cookbook.resource_files
    else
      raise ArgumentError, "segment must be one of :attributes, :recipes, :definitions, :libraries, :providers, or :resources"
    end
    files_list
  end

  def specific_cookbooks(node_name, cl)
    valid_cookbooks = Hash.new
    begin
      node = Chef::Node.load(node_name)
      recipes, default_attrs, override_attrs = node.run_list.expand('couchdb')
    rescue Net::HTTPServerException
      recipes = []
    end
    recipes.each do |recipe|
      valid_cookbooks = expand_cookbook_deps(valid_cookbooks, cl, recipe)
    end
    valid_cookbooks
  end

  def expand_cookbook_deps(valid_cookbooks, cl, recipe)
    cookbook = recipe
    if recipe =~ /^(.+)::/
      cookbook = $1
    end
    Chef::Log.debug("Node requires #{cookbook}")
    valid_cookbooks[cookbook] = true 
    cl.metadata[cookbook.to_sym].dependencies.each do |dep, versions|
      expand_cookbook_deps(valid_cookbooks, cl, dep) unless valid_cookbooks[dep]
    end
    valid_cookbooks
  end
  
  def load_all_files(segment, node_name=nil)
    cl = Chef::CookbookLoader.new
    files = Array.new
    valid_cookbooks = node_name ? specific_cookbooks(node_name, cl) : {} 
    cl.each do |cookbook|
      if node_name
        next unless valid_cookbooks[cookbook.name.to_s]
      end
      segment_files(segment, cookbook).each do |sf|
        mo = sf.match("cookbooks/#{cookbook.name}/#{segment}/(.+)")
        file_name = mo[1]
        files << { 
          :cookbook => cookbook.name, 
          :name => file_name,
          :checksum => checksum(sf)
        }
      end
    end
    files
  end

  def get_available_recipes
    cl = Chef::CookbookLoader.new
    available_recipes = cl.sort{ |a,b| a.name.to_s <=> b.name.to_s }.inject([]) do |result, element|
      element.recipes.sort.each do |r| 
        if r =~ /^(.+)::default$/
          result << $1
        else
          result << r
        end
      end
      result
    end
    available_recipes
  end

end
