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
require 'chef' / 'cookbook' / 'metadata'

class ChefServerApi::Cookbooks < ChefServerApi::Application
  
  provides :json

  before :authenticate_every

  include Chef::Mixin::Checksum
  
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
      raise NotFound, "Cannot find a cookbook named #{cookbook.to_s}"
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
        serve_segment_preferred(cookbook, params[:segment], cookbook_files[params[:segment].to_sym])
      else
        serve_segment_file(cookbook, params[:segment], cookbook_files[params[:segment].to_sym])
      end
    else
      display cookbook_files[params[:segment].to_sym]
    end
  end

  def serve_segment_preferred(cookbook, segment, files)

    to_send = nil

    preferences = [
      "host-#{params[:fqdn]}",
      "#{params[:platform]}-#{params[:version]}",
      "#{params[:platform]}",
      "default"
    ]

    preferences.each do |pref|
      unless to_send
        to_send = files.detect { |file| Chef::Log.debug("#{pref.inspect} #{file.inspect}"); file[:name] == params[:id] && file[:specificity] == pref }
      end
    end

    raise NotFound, "Cannot find a suitable #{segment} file!" unless to_send 
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
  
end

