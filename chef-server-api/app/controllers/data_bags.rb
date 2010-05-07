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

require 'chef/data_bag'

class DataBags < Application
  
  provides :json
  
  before :authenticate_every
  before :is_admin, :only => [ :create, :destroy ]
  
  def index
    @bag_list = Chef::DataBag.cdb_list(false)
    display(@bag_list.inject({}) { |r,b| r[b] = absolute_url(:datum, :id => b); r })
    
  end

  def show
    begin
      @data_bag = Chef::DataBag.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load data bag #{params[:id]}"
    end
    display(@data_bag.list.inject({}) { |res, i| res[i] = absolute_url(:data_bag_item, :data_bag_id => @data_bag.name, :id => i); res })
  end

  def create
    @data_bag = nil
    if params.has_key?("inflated_object")
      @data_bag = params["inflated_object"]
    else
      @data_bag = Chef::DataBag.new
      @data_bag.name(params["name"])
    end
    exists = true 
    begin
      Chef::DataBag.cdb_load(@data_bag.name)
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false
    end
    raise Conflict, "Data bag already exists" if exists
    self.status = 201
    @data_bag.cdb_save
    display({ :uri => absolute_url(:datum, :id => @data_bag.name) })
  end

  def destroy
    begin
      @data_bag = Chef::DataBag.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e 
      raise NotFound, "Cannot load data bag #{params[:id]}"
    end
    @data_bag.cdb_destroy
    @data_bag.couchdb_rev = nil
    display @data_bag
  end
  
end
