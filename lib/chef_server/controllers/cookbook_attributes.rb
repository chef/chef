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

require File.join(File.dirname(__FILE__), "..", "..", "chef", "mixin", "checksum")

class CookbookAttributes < Application
  
  provides :html, :json
  
  include Chef::Mixin::Checksum
  
  def load_cookbook_attributes()
    @cl = Chef::CookbookLoader.new
    @cookbook = @cl[params[:cookbook_id]]
    raise NotFound unless @cookbook
    
    @attribute_files = Hash.new
    @cookbook.attribute_files.each do |f|
      full = File.expand_path(f)
      name = File.basename(full)
      @attribute_files[name] = {
        :name => name,
        :file => full,
      }
    end
    @attribute_files
  end
  
  def index
    if params[:id]
      show
    else
      load_cookbook_attributes()
      display @attribute_files
    end
  end

  def show
    only_provides :json
    load_cookbook_attributes
    raise NotFound, "Cannot find a suitable attribute file!" unless @attribute_files.has_key?(params[:id])
    to_send = @attribute_files[params[:id]][:file]
    current_checksum = checksum(to_send)
    Chef::Log.debug("old sum: #{params[:checksum]}, new sum: #{current_checksum}") 
    if current_checksum == params[:checksum]
      display "File #{to_send} has not changed", :status => 304
    else
      send_file(to_send)
    end
  end
  
end


