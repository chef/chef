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
    cl = Chef::CookbookLoader.new
    @recipe_files = Array.new
    cl.each do |cookbook|
      cookbook.recipe_files.each do |rf|
        @recipe_files << { 
          :cookbook => cookbook.name, 
          :name => File.basename(rf)
        }
      end
    end
    display @recipe_files
  end

  def attribute_files
    cl = Chef::CookbookLoader.new
    @attribute_files = Array.new
    cl.each do |cookbook|
      cookbook.attribute_files.each do |af|
        @attribute_files << { 
          :cookbook => cookbook.name, 
          :name => File.basename(af) 
        }
      end
    end
    display @attribute_files
  end
  
end
