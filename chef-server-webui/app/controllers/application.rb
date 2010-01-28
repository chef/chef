#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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

require "chef" / "mixin" / "checksum"
require "chef" / "cookbook_loader"

class ChefServerWebui::Application < Merb::Controller

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
  
  # Check if the user is logged in and if the user still exists
  def login_required
   if session[:user]
     begin
       Chef::WebUIUser.load(session[:user]) rescue (raise NotFound, "Cannot find User #{session[:user]}, maybe it got deleted by an Administrator.")
     rescue   
       logout_and_redirect_to_login
     else 
       return session[:user]
     end 
   else  
     self.store_location
     throw(:halt, :access_denied)
   end
  end
  
  def cleanup_session
    [:user,:level].each { |n| session.delete(n) }
  end 
  
  def logout_and_redirect_to_login
    cleanup_session
    @user = Chef::WebUIUser.new
    redirect(slice_url(:users_login), {:message => { :error => $! }, :permanent => true})
  end 
  
  
  def is_admin(name)
    user = Chef::WebUIUser.load(name)
    return user.admin
  end
  
  #return true if there is only one admin left, false otehrwise
  def is_last_admin
    count = 0
    users = Chef::WebUIUser.list
    users.each do |u, url|
      user = Chef::WebUIUser.load(u)
      if user.admin
        count = count + 1
        return false if count == 2
      end
    end
    true
  end
  
  #whether or not the user should be able to edit a user's admin status
  def edit_admin
    is_admin(params[:user_id]) ? (!is_last_admin) : true
  end 
  
  def authorized_node
  #  if session[:level] == :admin
  #    Chef::Log.debug("Authorized as Administrator")
  #    true
  #  elsif session[:level] == :node
  #    Chef::Log.debug("Authorized as node")
  #    if session[:node_name] == params[:id].gsub(/\./, '_')
  #      true
  #    else
  #      raise(
  #        Unauthorized,
  #        "You are not the correct node for this action: #{session[:node_name]} instead of #{params[:id]}"
  #      )
  #    end
  #  else
  #    Chef::Log.debug("Unauthorized")
  #    raise Unauthorized, "You are not allowed to take this action."
  #  end
  end
  
  def authorized_user
    if session[:level] == :admin
      Chef::Log.debug("Authorized as Administrator")
      true
    else
      Chef::Log.debug("Unauthorized")
      raise Unauthorized, "The current user is not an Administrator, you can only Show and Edit the user itself. To control other users, login as an Administrator."
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
      redirect slice_url(:users_login), :message => { :error => "You don't have access to that, please login."}
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
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    cookbook = r.get_rest("cookbooks/#{cookbook_id}")

    raise NotFound unless cookbook
    
    files_list = segment_files(segment, cookbook)
    
    files = Hash.new
    files_list.each do |f|
      files[f['name']] = {
        :name => f["name"],
        :file => f["uri"],
      }
    end
    files
  end
  
  def segment_files(segment, cookbook)
    files_list = nil
    case segment
    when :attributes
      files_list = cookbook["attributes"]
    when :recipes
      files_list = cookbook["recipes"]
    when :definitions
      files_list = cookbook["definitions"]
    when :libraries
      files_list = cookbook["libraries"]
    else
      raise ArgumentError, "segment must be one of :attributes, :recipes, :definitions or :libraries"
    end
    files_list
  end

  #
  # The following should no longer be necessary for the re-factored cookbooks replated webui controllers (which talks to the API) 
  # But I want to wait until further verified before removing the code. [nuo]
  #
  # def specific_cookbooks(node_name, cl)
  #   valid_cookbooks = Hash.new
  #   begin
  #     node = Chef::Node.load(node_name)
  #     recipes, default_attrs, override_attrs = node.run_list.expand
  #   rescue Net::HTTPServerException
  #     recipes = []
  #   end
  #   recipes.each do |recipe|
  #     valid_cookbooks = expand_cookbook_deps(valid_cookbooks, cl, recipe)
  #   end
  #   valid_cookbooks
  # end
  # 
  # def expand_cookbook_deps(valid_cookbooks, cl, recipe)
  #   cookbook = recipe
  #   if recipe =~ /^(.+)::/
  #     cookbook = $1
  #   end
  #   Chef::Log.debug("Node requires #{cookbook}")
  #   valid_cookbooks[cookbook] = true 
  #   cl.metadata[cookbook.to_sym].dependencies.each do |dep, versions|
  #     expand_cookbook_deps(valid_cookbooks, cl, dep) unless valid_cookbooks[dep]
  #   end
  #   valid_cookbooks
  # end
  # 
  # def load_all_files(segment, node_name=nil)
  #   r = Chef::REST.new(Chef::Config[:chef_server_url])
  #   cookbooks = r.get_rest("cookbooks")
  #   
  #   files = Array.new
  #   valid_cookbooks = node_name ? specific_cookbooks(node_name, cookbooks) : {} 
  #   cl.each do |cookbook|
  #     if node_name
  #       next unless valid_cookbooks[cookbook.name.to_s]
  #     end
  #     segment_files(segment, cookbook).each do |sf|
  #       mo = sf.match("cookbooks/#{cookbook.name}/#{segment}/(.+)")
  #       file_name = mo[1]
  #       files << { 
  #         :cookbook => cookbook.name, 
  #         :name => file_name,
  #         :checksum => checksum(sf)
  #       }
  #     end
  #   end
  #   files
  # end

  def get_available_recipes
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    result = Array.new
    cookbooks = r.get_rest("cookbooks")
    cookbooks.keys.sort.each do |key|
      cb = r.get_rest(cookbooks[key])
      cb["recipes"].each do |recipe|
        recipe["name"] =~ /(.+)\.rb/
        r_name = $1;
        if r_name == "default" 
          result << key
        else
          result << "#{key}::#{r_name}"
        end
      end
    end
    result
  end
  
  def convert_newline_to_br(string)
    string.to_s.gsub(/\n/, '<br />') unless string.nil?
  end

end
