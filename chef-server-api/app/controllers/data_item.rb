#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
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
require 'chef/data_bag_item'

class DataItem < Application

  provides :json

  before :populate_data_bag
  before :authenticate_every
  before :is_admin, :only => [ :create, :update, :destroy ]

  def populate_data_bag
    begin
      @data_bag = Chef::DataBag.cdb_load(params[:data_bag_id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load data bag #{params[:data_bag_id]}"
    end
  end

  def show
    begin
      @data_bag_item = Chef::DataBagItem.cdb_load(params[:data_bag_id], params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load data bag #{params[:data_bag_id]} item #{params[:id]}"
    end
    display @data_bag_item.raw_data
  end

  def create
    raw_data = nil
    if params.has_key?("inflated_object")
      raw_data = params["inflated_object"].raw_data
    else
      raw_data = params
      raw_data.delete(:action)
      raw_data.delete(:controller)
      raw_data.delete(:data_bag_id)
    end
    @data_bag_item = nil
    begin
      @data_bag_item = Chef::DataBagItem.cdb_load(@data_bag.name, params[:id])
    rescue Chef::Exceptions::CouchDBNotFound
      @data_bag_item = Chef::DataBagItem.new
      @data_bag_item.data_bag(@data_bag.name)
    else
      raise Conflict, "Databag Item #{params[:id]} already exists" if @data_bag_item
    end
    @data_bag_item.raw_data = raw_data
    @data_bag_item.cdb_save
    display @data_bag_item.raw_data
  end

  def update
    raw_data = nil
    if params.has_key?("inflated_object")
      raw_data = params["inflated_object"].raw_data
    else
      raw_data = params
      raw_data.delete(:action)
      raw_data.delete(:controller)
      raw_data.delete(:data_bag_id)
    end

    begin
      @data_bag_item = Chef::DataBagItem.cdb_load(@data_bag.name, params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load Databag Item #{params[:id]}"
    end

    @data_bag_item.raw_data = raw_data
    @data_bag_item.cdb_save
    display @data_bag_item.raw_data

  end


  def destroy
    begin
      @data_bag_item = Chef::DataBagItem.cdb_load(params[:data_bag_id], params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load data bag #{params[:data_bag_id]} item #{params[:id]}"
    end
    @data_bag_item.cdb_destroy
    @data_bag_item.couchdb_rev = nil
    display @data_bag_item
  end

end
