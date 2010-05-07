#
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
require "mixlib/authentication/signatureverification"

class ChefServerApi::Application < Merb::Controller

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
    options = {}
    if args.length == 1 && args[0].respond_to?(:keys)
      options = args[0]
    else
      options  = extract_options_from_args!(args) || {}
    end
    protocol = options.delete(:protocol) || request.protocol
    host     = options.delete(:host) || request.host
    protocol + "://" + host + slice_url(slice_name, *args)
  end
  
  def authenticate_every
    authenticator = Mixlib::Authentication::SignatureVerification.new

    auth = begin
             headers = request.env.inject({ }) { |memo, kv| memo[$2.downcase.gsub(/\-/,"_").to_sym] = kv[1] if kv[0] =~ /^(HTTP_)(.*)/; memo }
             Chef::Log.debug("Headers in authenticate_every: #{headers.inspect}")
             username = headers[:x_ops_userid].chomp
             Chef::Log.info("Authenticating client #{username}")
             user = Chef::ApiClient.cdb_load(username)
             Chef::Log.debug("Found API Client: #{user.inspect}")
             user_key = OpenSSL::PKey::RSA.new(user.public_key)
             Chef::Log.debug "Authenticating:\n #{user.inspect}\n"
             # Store this for later..
             @auth_user = user
             authenticator.authenticate_user_request(request, user_key)
           rescue StandardError => se
             Chef::Log.debug "Authentication failed: #{se}, #{se.backtrace.join("\n")}"
             nil
           end

    raise Unauthorized, "Failed to authenticate!" unless auth

    auth
  end
  
  def is_admin 
    if @auth_user.admin
      true
    else
      raise Unauthorized, "You are not allowed to take this action."
    end
  end

  def is_admin_or_validator
    if @auth_user.admin || @auth_user.name == Chef::Config[:validation_client_name]
      true
    else
      raise Unauthorized, "You are not allowed to take this action."
    end
  end

  def is_correct_node
    if @auth_user.admin || @auth_user.name == params[:id]
      true
    else
      raise Unauthorized, "You are not the correct node (auth_user name: #{@auth_user.name}, params[:id]: #{params[:id]}), or are not an API administrator (admin: #{@auth_user.admin})."
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
  def load_cookbook_segment(cookbook, segment)
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
    when :files
      files_list = cookbook.remote_files
    when :templates
      files_list = cookbook.template_files
    else
      raise ArgumentError, "segment must be one of :attributes, :recipes, :definitions, :remote_files, :template_files, :resources, :providers or :libraries"
    end
    files_list
  end

  def specific_cookbooks(node_name, cl)
    valid_cookbooks = Hash.new
    begin
      node = Chef::Node.cdb_load(node_name)
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

  def load_cookbook_files(cookbook)
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
      segment_files(segment, cookbook).each do |sf|
        next if File.directory?(sf)
        file_name = nil
        file_url = nil
        file_specificity = nil

        if segment == :templates || segment == :files
          mo = sf.match("cookbooks/#{cookbook.name}/#{segment}/(.+?)/(.+)")
          unless mo
            Chef::Log.debug("Skipping file #{sf}, as it doesn't have a proper segment.")
            next
          end
          specificity = mo[1]
          file_name = mo[2]
          url_options = { :cookbook_id => cookbook.name.to_s, :segment => segment, :id => file_name }
          
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
          
          file_specificity = specificity
          file_url = absolute_slice_url(:cookbook_segment, url_options)
        else
          mo = sf.match("cookbooks/#{cookbook.name}/#{segment}/(.+)")
          file_name = mo[1]
          url_options = { :cookbook_id => cookbook.name.to_s, :segment => segment, :id => file_name }
          file_url = absolute_slice_url(:cookbook_segment, url_options)
        end
        rs = {
          :name => file_name, 
          :uri => file_url, 
          :checksum => checksum(sf)
        }
        rs[:specificity] = file_specificity if file_specificity
        response[segment] << rs 
      end
    end
    response
  end
  
  def load_all_files(node_name=nil)
    cl = Chef::CookbookLoader.new
    valid_cookbooks = node_name ? specific_cookbooks(node_name, cl) : {} 
    cookbook_list = Hash.new
    cl.each do |cookbook|
      if node_name
        next unless valid_cookbooks[cookbook.name.to_s]
      end
      cookbook_list[cookbook.name.to_s] = load_cookbook_files(cookbook) 
    end
    cookbook_list
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

