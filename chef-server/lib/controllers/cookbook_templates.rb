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

class CookbookTemplates < Application
  
  provides :html, :json
  
  include Chef::Mixin::Checksum
  
  def load_cookbook_templates()
    @cl = Chef::CookbookLoader.new
    @cookbook = @cl[params[:cookbook_id]]
    raise NotFound unless @cookbook
    
    @templates = Hash.new
    @cookbook.template_files.each do |tf|
      full = File.expand_path(tf)
      name = File.basename(full)
      tf =~ /^.+#{params[:cookbook_id]}[\\|\/]templates[\\|\/](.+?)[\\|\/]#{name}/
      singlecopy = $1
      @templates[full] = {
        :name => name,
        :singlecopy => singlecopy,
        :file => full,
      }
    end
    @templates
  end
  
  def index
    if params[:id]
      show
    else
      load_cookbook_templates()
      display @templates
    end
  end

  def show
    load_cookbook_templates()
    preferences = [
      File.join("host-#{params[:fqdn]}", "#{params[:id]}"),
      File.join("#{params[:platform]}-#{params[:version]}", "#{params[:id]}"),
      File.join("#{params[:platform]}", "#{params[:id]}"),
      File.join("default", "#{params[:id]}")
    ]
    to_send = nil
    @templates.each_key do |file|
      Chef::Log.debug("Looking at #{file}")
      preferences.each do |pref|
        Chef::Log.debug("Compared to #{pref}")
        if file =~ /#{pref}/
          Chef::Log.debug("Matched #{pref} for #{file}!")
          to_send = file
          break
        end
      end
      break if to_send
    end
    raise NotFound, "Cannot find a suitable template!" unless to_send
    current_checksum = checksum(to_send)
    Chef::Log.debug("old sum: #{params[:checksum]}, new sum: #{current_checksum}") 
    if current_checksum == params[:checksum]
      display "Template #{to_send} has not changed", :status => 304
    else
      send_file(to_send)
    end
  end
  
end
