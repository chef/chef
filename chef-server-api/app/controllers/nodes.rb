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

class Nodes < Application

  provides :json

  before :authenticate_every
  before :admin_or_requesting_node, :only => [ :update, :destroy, :cookbooks ]

  def index
    @node_list = Chef::Node.cdb_list
    display(@node_list.inject({}) do |r,n|
      r[n] = absolute_url(:node, n); r
    end)
  end

  def show
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    @node.couchdb_rev = nil
    display @node
  end

  def create
    @node = params["inflated_object"]
    begin
      Chef::Node.cdb_load(@node.name)
      raise Conflict, "Node already exists"
    rescue Chef::Exceptions::CouchDBNotFound
    end
    self.status = 201
    @node.cdb_save
    display({ :uri => absolute_url(:node, @node.name) })
  end

  def update
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end

    @node.update_from!(params['inflated_object'])
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

    display(load_all_files)
  end

  private

  def load_all_files
    all_cookbooks = Chef::Environment.cdb_load_filtered_cookbook_versions(@node.chef_environment)

    included_cookbooks = cookbooks_for_node(all_cookbooks)
    nodes_cookbooks = Hash.new
    included_cookbooks.each do |cookbook_name, cookbook|
      nodes_cookbooks[cookbook_name.to_s] = cookbook.generate_manifest_with_urls{|opts| absolute_url(:cookbook_file, opts) }
    end

    nodes_cookbooks
  end

  # returns name -> CookbookVersion for all cookbooks included on the given node.
  def cookbooks_for_node(all_cookbooks)
    begin
      @node.constrain_cookbooks(all_cookbooks, 'couchdb')
    rescue Chef::Exceptions::CookbookVersionConflict, Chef::Exceptions::CookbookVersionUnavailable => e
      raise PreconditionFailed, e.message
    end
  end

end
