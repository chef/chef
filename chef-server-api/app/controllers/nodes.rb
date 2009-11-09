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

require 'chef' / 'node'

class ChefServerApi::Nodes < ChefServerApi::Application
  
  provides :json
  
  before :authenticate_every 
  before :fix_up_node_id
  before :is_correct_node, :only => [ :update, :destroy, :cookbooks ]
  
  def index
    @node_list = Chef::Node.cdb_list 
    display(@node_list.inject({}) { |r,n| r[n] = absolute_slice_url(:node, escape_node_id(n)); r })
  end

  def show
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    @node.couchdb_rev = nil
    recipes, default, override = @node.run_list.expand("couchdb")
    @node.default_attrs = default
    @node.override_attrs = override
    display @node
  end

  def create
    @node = params["inflated_object"]
    exists = true 
    begin
      Chef::Node.cdb_load(@node.name)
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false
    end
    raise Forbidden, "Node already exists" if exists
    self.status = 201
    @node.cdb_save
    display({ :uri => absolute_slice_url(:node, escape_node_id(@node.name)) })
  end

  def update
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end

    updated = params['inflated_object']
    @node.run_list.reset(updated.run_list)
    @node.attribute = updated.attribute
    @node.override_attrs = updated.override_attrs
    @node.default_attrs = updated.default_attrs
    @node.cdb_save
    @node.couchdb_rev = nil
    display(@node)
  end

  def destroy
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e 
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    @node.cdb_destroy
    @node.couchdb_rev = nil
    display @node
  end

  def cookbooks
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e 
      raise NotFound, "Cannot load node #{params[:id]}"
    end
   
    display(load_all_files(params[:id]))
  end
  
end

