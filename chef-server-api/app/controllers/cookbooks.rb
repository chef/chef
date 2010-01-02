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

class ChefServerApi::Cookbooks < ChefServerApi::Application
  
  provides :json

  before :authenticate_every

  include Chef::Mixin::Checksum
  include Merb::ChefServerApi::TarballHelper
  
  def index
    cl = Chef::CookbookLoader.new
    cookbook_list = Hash.new
    cl.each do |cookbook|
      cookbook_list[cookbook.name] = absolute_slice_url(:cookbook, :id => cookbook.name.to_s) 
    end
    display cookbook_list 
  end

  def show
    cl = Chef::CookbookLoader.new
    begin
      cookbook = cl[params[:id]]
    rescue ArgumentError => e
      raise NotFound, "Cannot find a cookbook named #{params[:id]}"
    end
    results = load_cookbook_files(cookbook)
    results[:name] = cookbook.name.to_s
    results[:metadata] = cl.metadata[cookbook.name.to_sym]
    display results 
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
  
  def create
    # validate name and file parameters and throw an error if a cookbook with the same name already exists
    raise BadRequest, "missing required parameter: name" unless params[:name]
    desired_name = params[:name]
    raise BadRequest, "invalid parameter: name must be at least one character long and contain only letters, numbers, periods (.), underscores (_), and hyphens (-)" unless desired_name =~ /\A[\w.-]+\Z/
    begin
      validate_file_parameter(desired_name, params[:file])
    rescue FileParameterException => te
      raise BadRequest, te.message
    end
    
    begin
      Chef::CookbookLoader.new[desired_name]
      raise BadRequest, "Cookbook with the name #{desired_name} already exists"
    rescue ArgumentError
    end
    
    expand_tarball_and_put_in_repository(desired_name, params[:file][:tempfile])
    
    # construct successful response
    self.status = 201
    location = absolute_slice_url(:cookbook, :id => desired_name)
    headers['Location'] = location
    result = { 'uri' => location }
    display result
  end
  
  def get_tarball
    cookbook_name = params[:cookbook_id]
    expected_location = cookbook_location(cookbook_name)
    raise NotFound, "Cannot find cookbook named #{cookbook_name} at #{expected_location}. Note: Tarball generation only applies to cookbooks under the first directory in the server's Chef::Config.cookbook_path variable and does to apply overrides." unless File.directory? expected_location
    
    send_file(get_or_create_cookbook_tarball_location(cookbook_name))
  end
  
  def update
    cookbook_name = params[:cookbook_id]
    cookbook_path = cookbook_location(cookbook_name)
    raise NotFound, "Cannot find cookbook named #{cookbook_name}" unless File.directory? cookbook_path
    begin
      validate_file_parameter(cookbook_name, params[:file])
    rescue FileParameterException => te
      raise BadRequest, te.message
    end
    
    expand_tarball_and_put_in_repository(cookbook_name, params[:file][:tempfile])
    
    display Hash.new
  end
  
  def destroy
    cookbook_name = params[:id]
    cookbook_path = cookbook_location(cookbook_name)
    raise NotFound, "Cannot find cookbook named #{cookbook_name}" unless File.directory? cookbook_path

    FileUtils.rm_rf(cookbook_path)
    FileUtils.rm_f(cookbook_tarball_location(cookbook_name))

    display Hash.new
  end
  
end

