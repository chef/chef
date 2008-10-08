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
#

class Application < Merb::Controller

  def fix_up_node_id
    if params.has_key?(:id)
      params[:id].gsub!(/_/, '.')
    end
  end
  
  def escape_node_id
    if params.has_key?(:id)
      params[:id].gsub(/_/, '.')
    end
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
      redirect url(:openid_consumer)
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
    else
      raise ArgumentError, "segment must be one of :attributes, :recipes, :definitions or :libraries"
    end
    files_list
  end
  
  def load_all_files(segment)
    cl = Chef::CookbookLoader.new
    files = Array.new
    cl.each do |cookbook|
      segment_files(segment, cookbook).each do |sf|
        mo = sf.match("cookbooks/#{cookbook.name}/#{segment}/(.+)")
        file_name = mo[1]
        files << { 
          :cookbook => cookbook.name, 
          :name => file_name
        }
      end
    end
    files
  end

end