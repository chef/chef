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

require 'chef' / 'cookbook_loader'

class ChefServerWebui::Cookbooks < ChefServerWebui::Application
  
  provides :html, :json
  before :login_required 
  
  def index
    @cl = begin
            Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("cookbooks")
          rescue => e
            Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
            @_message = {:error => $!}
            {}
          end 
    render
  end

  def show
    begin
      @cookbook = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("cookbooks/#{params[:id]}")
      raise NotFound unless @cookbook
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
