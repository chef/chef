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

require 'chef/cookbook_loader'
require 'chef/cookbook_version'

class Cookbooks < Application
  
  provides :html
  before :login_required
  before :params_helper
  
  attr_reader :cookbook_id
  def params_helper
    @cookbook_id = params[:id] || params[:cookbook_id]
  end
  
  def index
    @cl = begin
            if session[:environment]
              result = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("environments/#{session[:environment]}/cookbooks")
            else
              result = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("cookbooks/_latest")
            end
            result.inject({}) do |res, (cookbook, url)|
              # get the version number from the url
              res[cookbook] = url.split("/").last
              res
            end
          rescue => e
            Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
            @_message = {:error => $!}
            {}
          end 
    render
  end

  def show
    begin
      # array of versions, sorted from large to small e.g. ["0.20.0", "0.1.0"]
      versions = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("cookbooks/#{cookbook_id}")[cookbook_id].sort!{|x,y| y <=> x }      
      # if version is not specified in the url, get the most recent version, otherwise get the specified version
      version = if params[:cb_version].nil? || params[:cb_version].empty?
                  versions.first
                else
                  params[:cb_version]
                end
                
      @cookbook = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("cookbooks/#{cookbook_id}/#{version}")
      
      # by default always show the largest version number (assuming largest means most recent)
      @other_versions = versions - [version]
      raise NotFound unless @cookbook

      @manifest = @cookbook.manifest
      display @cookbook
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = {:error => $!}
      @cl = {}
      render :index
    end 
  end
  
  def recipe_files
    # node = params.has_key?('node') ? params[:node] : nil 
    # @recipe_files = load_all_files(:recipes, node)
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/recipes")        
    display @recipe_files
  end

  def attribute_files
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/attributes")
    display @attribute_files
  end
  
  def definition_files
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/definitions")
    display @definition_files
  end
  
  def library_files
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/libraries")
    display @lib_files
  end
  
end
