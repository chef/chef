#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

class Cookbooks < Application
  
  provides :html, :json
  
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
    @recipe_files = load_all_files(:recipes)
    display @recipe_files
  end

  def attribute_files
    @attribute_files = load_all_files(:attributes)
    display @attribute_files
  end
  
  def definition_files
    @definition_files = load_all_files(:definitions)
    display @definition_files
  end
  
  def library_files
    @lib_files = load_all_files(:libraries)
    display @lib_files
  end
  
end
