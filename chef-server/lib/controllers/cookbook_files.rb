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

require 'chef' / 'mixin' / 'checksum'
require 'chef' / 'cookbook_loader'

class CookbookFiles < Application
  
  provides :html, :json
  
  include Chef::Mixin::Checksum

  layout nil

  def load_cookbook_files()
    @cl = Chef::CookbookLoader.new
    @cookbook = @cl[params[:cookbook_id]]
    raise NotFound unless @cookbook
    
    @remote_files = Hash.new
    @cookbook.remote_files.each do |rf|
      full = File.expand_path(rf)
      name = File.basename(full)
      rf =~ /^.+#{params[:cookbook_id]}[\\|\/]files[\\|\/](.+?)[\\|\/]#{name}/
      singlecopy = $1
      @remote_files[full] = {
        :name => name,
        :singlecopy => singlecopy,
        :file => full,
      }
    end
    Chef::Log.debug("Remote files found: #{@remote_files.inspect}")
    @remote_files
  end
  
  def index
    if params[:id]
      if params[:recursive] == "true"
        show_directory
      else
        show
      end
    else
      load_cookbook_files()
      display @remote_files
    end
  end

  def show
    only_provides :json
    to_send = find_preferred_file
    raise NotFound, "Cannot find a suitable file!" unless to_send
    current_checksum = checksum(to_send)
    Chef::Log.debug("old sum: #{params[:checksum]}, new sum: #{current_checksum}") 
    if current_checksum == params[:checksum]
      display "File #{to_send} has not changed", :status => 304
    else
      send_file(to_send)
    end
  end
  
  def show_directory
    dir_to_send = find_preferred_file
    unless (dir_to_send && File.directory?(dir_to_send))
      raise NotFound, "Cannot find a suitable directory"
    end
    
    @directory_listing = Array.new
    Dir[::File.join(dir_to_send, '**', '*')].sort { |a,b| b <=> a }.each do |file_to_send|
      next if File.directory?(file_to_send)
      file_to_send =~ /^#{dir_to_send}\/(.+)$/
      @directory_listing << $1
    end
    
    display @directory_listing
  end
  
  protected
  
    def find_preferred_file
      load_cookbook_files()
      preferences = [
        File.join("host-#{params[:fqdn]}", "#{params[:id]}"),
        File.join("#{params[:platform]}-#{params[:version]}", "#{params[:id]}"),
        File.join("#{params[:platform]}", "#{params[:id]}"),
        File.join("default", "#{params[:id]}")
      ]
      to_send = nil
      @remote_files.each_key do |file|
        Chef::Log.debug("Looking at #{file}")
        preferences.each do |pref|
          Chef::Log.debug("Compared to #{pref}")
          if file =~ /#{pref}$/
            Chef::Log.debug("Matched #{pref} for #{file}!")         
            to_send = file
            break
          end
        end
        break if to_send
      end
      to_send
    end
  
end
