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

require 'chef' / 'mixin' / 'checksum'
require 'chef' / 'cookbook_loader'
require 'chef' / 'mixin' / 'find_preferred_file'

class ChefServerSlice::CookbookFiles < ChefServerSlice::Application
  
  provides :html, :json
  before :login_required 
  
  include Chef::Mixin::Checksum
  include Chef::Mixin::FindPreferredFile

  layout nil
  
  def index
    if params[:id]
      if params[:recursive] == "true"
        show_directory
      else
        show
      end
    else
      @remote_files = load_cookbook_files(params[:cookbook_id], :remote_file)
      display @remote_files
    end
  end

  def show
    only_provides :json
    begin
      to_send = find_preferred_file(
        params[:cookbook_id], 
        :remote_file, 
        params[:id], 
        params[:fqdn], 
        params[:platform], 
        params[:version]
      )
    rescue Chef::Exceptions::FileNotFound
      raise NotFound, "Cannot find a suitable file!"
    end

    current_checksum = checksum(to_send)
    Chef::Log.debug("old sum: #{params[:checksum]}, new sum: #{current_checksum}") 
    if current_checksum == params[:checksum]
      render "File #{to_send} has not changed", :status => 304
    else
      send_file(to_send)
    end
  end
  
  def show_directory
    dir_to_send = find_preferred_file(
      params[:cookbook_id], 
      :remote_file, 
      params[:id], 
      params[:fqdn], 
      params[:platform], 
      params[:version]
    )
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
  
end
