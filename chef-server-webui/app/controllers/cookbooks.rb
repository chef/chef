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

require 'chef' / 'cookbook_loader'

class ChefServerWebui::Cookbooks < ChefServerWebui::Application
  
  provides :html, :json
  before :login_required 
  
  def index
    @cl = Chef::CookbookLoader.new
    display @cl
  end

  def show
    @cl = Chef::CookbookLoader.new
    @cookbook = @cl[params[:id]]
    raise NotFound unless @cookbook
    display @cookbook
  end
  
  def recipe_files
    node = params.has_key?('node') ? params[:node] : nil 
    @recipe_files = load_all_files(:recipes, node)
    display @recipe_files
  end

  def attribute_files
    node = params.has_key?('node') ? params[:node] : nil 
    @attribute_files = load_all_files(:attributes, node)
    display @attribute_files
  end
  
  def definition_files
    node = params.has_key?('node') ? params[:node] : nil 
    @definition_files = load_all_files(:definitions, node)
    display @definition_files
  end
  
  def library_files
    node = params.has_key?('node') ? params[:node] : nil 
    @lib_files = load_all_files(:libraries, node)
    display @lib_files
  end
  
end
