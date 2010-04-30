#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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
require 'chef' / 'cookbook' / 'metadata'

class Cookbooks < Application
  
  provides :json

  before :authenticate_every

  include Chef::Mixin::Checksum
  include Merb::TarballHelper
  
  def index
    cookbook_list = Chef::Cookbook.cdb_list
    response = Hash.new
    cookbook_list.each do |cookbook_name|
      cookbook_name =~ /^(.+)-(\d+\.\d+\.\d+)$/
      response[$1] = absolute_slice_url(:cookbook, :id => $1)
    end
    display response 
  end

  def show
    begin
      cookbook = Chef::Cookbook.cdb_load(params[:id], params[:version])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot find a cookbook named #{params[:id]} with version #{params[:version]}"
    end
    cookbook.display_manifest { |opts| absolute_slice_url(:cookbook_segment, opts) }
    display cookbook
  end

  def show_versions
    begin
      cookbook_versions = Chef::Cookbook.cdb_by_version(params[:id])
    rescue ArgumentError => e
      raise NotFound, "Cannot find a cookbook named #{params[:id]}"
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot find a cookbook named #{params[:id]}"
    end
    display cookbook_versions
  end
 
  def show_segment
    cl = Chef::CookbookLoader.new
    begin
      cookbook = cl[params[:cookbook_id]]
    rescue ArgumentError => e
      raise NotFound, "Cannot find a cookbook named #{params[:cookbook_id]}" 
    end
    cookbook_files = load_cookbook_files(cookbook)
    raise NotFound unless cookbook_files.has_key?(params[:segment].to_sym)

    if params[:id]
      case params[:segment]
      when "templates","files"
        if params[:recursive]
          serve_directory_preferred(cookbook, params[:segment], cookbook_files[params[:segment].to_sym])
        else
          serve_segment_preferred(cookbook, params[:segment], cookbook_files[params[:segment].to_sym])
        end
      else
        serve_segment_file(cookbook, params[:segment], cookbook_files[params[:segment].to_sym])
      end
    else
      display cookbook_files[params[:segment].to_sym]
    end
  end

  def serve_segment_preferred(cookbook, segment, files)

    to_send = nil
    
    preferences.each do |pref|
      unless to_send
        Chef::Log.debug("Looking for a file with name `#{params[:id]}' and specificity #{pref}")
        to_send = files.detect do |file| 
          Chef::Log.debug("#{pref.inspect} #{file.inspect}")
          file[:name] == params[:id] && file[:specificity] == pref
          
        end
      end
    end

    raise NotFound, "Cannot find a suitable #{segment} file for #{params[:id]}!" unless to_send 
    current_checksum = to_send[:checksum] 
    Chef::Log.debug("#{to_send[:name]} Client Checksum: #{params[:checksum]}, Server Checksum: #{current_checksum}") 
    if current_checksum == params[:checksum]
      raise NotModified, "File #{to_send[:name]} has not changed"
    else
      file_name = nil
      segment_files(segment.to_sym, cookbook).each do |f|
        if f =~ /#{to_send[:specificity]}\/#{to_send[:name]}$/
          file_name = File.expand_path(f)
          break 
        end
      end
      raise NotFound, "Cannot find the real file for #{to_send[:specificity]} #{to_send[:name]} - this is a 42 error (shouldn't ever happen)" unless file_name
      send_file(file_name)
    end
  end
  
  def serve_directory_preferred(cookbook, segment, files)
    preferred_dir_contents = []
    preferences.each do |preference|
      preferred_dir_contents = files.select { |file| file[:name] =~ /^#{params[:id]}/ && file[:specificity] == preference  }
      break unless preferred_dir_contents.empty?
    end
    
    raise NotFound, "Cannot find a suitable directory for #{params[:id]}" if preferred_dir_contents.empty?
    
    display preferred_dir_contents.map { |file| file[:name].sub(/^#{params[:id]}/, '') }
  end
  
  def preferences
    ["host-#{params[:fqdn]}",
    "#{params[:platform]}-#{params[:version]}",
    "#{params[:platform]}",
    "default"]
  end

  def serve_segment_file(cookbook, segment, files)
    to_send = files.detect { |f| f[:name] == params[:id] } 
    raise NotFound, "Cannot find a suitable #{segment} file!" unless to_send 
    current_checksum = to_send[:checksum] 
    Chef::Log.debug("#{to_send[:name]} Client Checksum: #{params[:checksum]}, Server Checksum: #{current_checksum}") 
    if current_checksum == params[:checksum]
      raise NotModified, "File #{to_send[:name]} has not changed"
    else
      file_name = nil
      segment_files(segment.to_sym, cookbook).each do |f|
        next unless File.basename(f) == to_send[:name]
        file_name = File.expand_path(f)
      end
      raise NotFound, "Cannot find the real file for #{to_send[:name]} - this is a 42 error (shouldn't ever happen)" unless file_name
      send_file(file_name)
    end
  end
  
  def update
    cookbook_name = params[:id]
    cookbook_version = params[:version]
    raise(BadRequest, "You didn't pass me a valid object!") unless params.has_key?('inflated_object')
    raise(BadRequest, "You didn't pass me a Chef::Cookbook object!") unless params['inflated_object'].kind_of?(Chef::Cookbook)
    unless params["inflated_object"].name == cookbook_name
      raise(BadRequest, "You said the cookbook was named #{params['inflated_object'].name}, but the URL says it should be #{cookbook_name}.") 
    end

    unless params["inflated_object"].version == cookbook_version
      raise(BadRequest, "You said the cookbook was version #{params['inflated_object'].version}, but the URL says it should be #{cookbook_version}.") 
    end

    @cookbook = nil
    begin
      @cookbook = Chef::Cookbook.cdb_load(cookbook_name, cookbook_version)
    rescue Chef::Exceptions::CouchDBNotFound => e
      Chef::Log.debug("Cookbook #{cookbook_name} version #{cookbook_version} does not exist")
    end

    if @cookbook
      @cookbook.manifest = params['inflated_object'].manifest
    else
      params['inflated_object'].cdb_save
    end

    display @cookbook ? @cookbook : params['inflated_object']
  end
  
  def destroy
    begin
      cookbook = Chef::Cookbook.cdb_load(params[:id], params[:version])
    rescue ArgumentError => e
      raise NotFound, "Cannot find a cookbook named #{params[:id]} with version #{params[:version]}"
    end

    display cookbook.cdb_destroy
  end
  
end

