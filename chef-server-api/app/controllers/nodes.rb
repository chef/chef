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

require 'chef/node'
require 'chef/version_class'
require 'chef/version_constraint'
require 'chef/cookbook_version_selector'

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

  # Return a hash, cookbook_name => cookbook manifest, of the cookbooks
  # appropriate for this node, using its run_list and environment.
  def cookbooks
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end

    # Get the mapping of cookbook_name => CookbookVersion applicable to
    # this node's run_list and its environment.
    begin
      included_cookbooks = Chef::CookbookVersionSelector.expand_to_cookbook_versions(@node.run_list, @node.chef_environment)
    rescue Chef::Exceptions::CookbookVersionSelection::InvalidRunListItems => e
      raise PreconditionFailed, e.to_json
    rescue Chef::Exceptions::CookbookVersionSelection::UnsatisfiableRunListItem => e
      raise PreconditionFailed, e.to_json
    rescue Chef::Exceptions::CookbookVersionSelection::TimeBoundExceeded => e
      raise PreconditionFailed, e.to_json
    end

    # Convert from
    #  name => CookbookVersion
    # to
    #  name => cookbook manifest
    # and display.
    display(included_cookbooks.inject({}) do |acc, (cookbook_name, cookbook_version)|
              acc[cookbook_name.to_s] = cookbook_version.generate_manifest_with_urls{|opts| absolute_url(:cookbook_file, opts) }
              acc
            end)
  end

end
