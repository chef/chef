#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009, 2010 Opscode, Inc.
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

require 'chef/cookbook_loader'
require 'chef/cookbook/metadata'

class Cookbooks < Application
  
  provides :json

  before :authenticate_every
  before :params_helper
  before :is_admin, :only => [ :update, :destroy ]

  attr_accessor :cookbook_name, :cookbook_version
  
  def params_helper
    self.cookbook_name = params[:cookbook_name]
    self.cookbook_version = params[:cookbook_version]
  end

  include Chef::Mixin::Checksum
  include Merb::TarballHelper
  
  def index
    cookbook_list = Chef::CookbookVersion.cdb_list_latest.keys.sort
    response = Hash.new
    cookbook_list.map! do |cookbook_name|
      response[cookbook_name] = absolute_url(:cookbook, :cookbook_name => cookbook_name)
    end
    display response
  end

  def index_latest
    cookbook_list = Chef::CookbookVersion.cdb_list_latest(true)
    response = cookbook_list.inject({}) do |res, cv|
      res[cv.name] = absolute_url(:cookbook_version, :cookbook_name => cv.name, :cookbook_version => cv.version)
      res
    end
    display response
  end

  def index_recipes
    all_cookbooks = Array(Chef::CookbookVersion.cdb_list_latest(true))
    all_cookbooks.map! do |cookbook|
      cookbook.manifest["recipes"].map { |r| "#{cookbook.name}::#{File.basename(r['name'], ".rb")}" }
    end
    all_cookbooks.flatten!
    all_cookbooks.sort!
    display all_cookbooks
  end

  def show_versions
    versions = Chef::CookbookVersion.cdb_by_name(cookbook_name)
    raise NotFound, "Cannot find a cookbook named #{cookbook_name}" unless versions && versions.size > 0
    display versions
  end

  def show
    cookbook = get_cookbook_version(cookbook_name, cookbook_version)
    display cookbook.generate_manifest_with_urls { |opts| absolute_url(:cookbook_file, opts) }
  end

  def show_file
    cookbook = get_cookbook_version(cookbook_name, cookbook_version)
    
    checksum = params[:checksum]
    raise NotFound, "Cookbook #{cookbook_name} version #{cookbook_version} does not contain a file with checksum #{checksum}" unless cookbook.checksums.keys.include?(checksum)

    filename = Chef::Checksum.new(checksum).file_location
    raise InternalServerError, "File with checksum #{checksum} not found in the repository (this should not happen)" unless File.exists?(filename)

    send_file(filename)
  end

  def update
    raise(BadRequest, "You didn't pass me a valid object!") unless params.has_key?('inflated_object')
    raise(BadRequest, "You didn't pass me a Chef::CookbookVersion object!") unless params['inflated_object'].kind_of?(Chef::CookbookVersion)
    unless params["inflated_object"].name == cookbook_name
      raise(BadRequest, "You said the cookbook was named #{params['inflated_object'].name}, but the URL says it should be #{cookbook_name}.")
    end

    unless params["inflated_object"].version == cookbook_version
      raise(BadRequest, "You said the cookbook was version #{params['inflated_object'].version}, but the URL says it should be #{cookbook_version}.") 
    end
    
    begin
      cookbook = Chef::CookbookVersion.cdb_load(cookbook_name, cookbook_version)
      cookbook.manifest = params['inflated_object'].manifest
    rescue Chef::Exceptions::CouchDBNotFound => e
      Chef::Log.debug("Cookbook #{cookbook_name} version #{cookbook_version} does not exist")
      cookbook = params['inflated_object']
    end
    
    # ensure that all checksums referred to by the manifest have been uploaded.
    Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
      next unless cookbook.manifest[segment]
      cookbook.manifest[segment].each do |manifest_record|
        checksum = manifest_record[:checksum]
        path = manifest_record[:path]
        
        begin
          checksum_obj = Chef::Checksum.cdb_load(checksum)
        rescue Chef::Exceptions::CouchDBNotFound => cdbx
          checksum_obj = nil
        end
        
        raise BadRequest, "Manifest has checksum #{checksum} (path #{path}) but it hasn't yet been uploaded" unless checksum_obj
      end
    end
    
    raise InternalServerError, "Error saving cookbook" unless cookbook.cdb_save

    display cookbook
  end
  
  def destroy
    begin
      cookbook = get_cookbook_version(cookbook_name, cookbook_version)
    rescue ArgumentError => e
      raise NotFound, "Cannot find a cookbook named #{cookbook_name} with version #{cookbook_version}"
    end

    if params["purge"] == "true"
      display cookbook.purge
    else
      display cookbook.cdb_destroy
    end
  end

  private

  def get_cookbook_version(name, version)
    Chef::CookbookVersion.cdb_load(name, version)
  rescue Chef::Exceptions::CouchDBNotFound => e
    raise NotFound, "Cannot find a cookbook named #{name} with version #{version}"
  rescue Net::HTTPServerException => e
    if e.to_s =~ /^404/
      raise NotFound, "Cannot find a cookbook named #{name} with version #{version}"
    else
      raise
    end
  end
  
end

