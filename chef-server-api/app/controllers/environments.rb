#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/environment'

class Environments < Application

  provides :json

  before :authenticate_every
  before :is_admin, :only => [ :create, :update, :destroy ]

  # GET /environments
  def index
    environment_list = Chef::Environment.cdb_list(true)
    display(environment_list.inject({}) { |res, env| res[env.name] = absolute_url(:environment, env.name); res })
  end

  # GET /environments/:id
  def show
    begin
      environment = Chef::Environment.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load environment #{params[:id]}"
    end
    environment.couchdb_rev = nil
    display environment
  end

  # POST /environments
  def create
    env = params["inflated_object"]
    exists = true
    begin
      Chef::Environment.cdb_load(env.name)
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false
    end
    raise Conflict, "Environment already exists" if exists

    env.cdb_save
    self.status = 201
    display({:uri => absolute_url(:environment, env.name)})
  end

  # PUT /environments/:id
  def update
    raise Forbidden if params[:id] == "_default"
    begin
      env = Chef::Environment.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound
      raise NotFound, "Cannot load environment #{params[:id]}"
    end

    env.update_from!(params["inflated_object"])
    env.cdb_save
    env.couchdb_rev = nil
    self.status = 200
    display(env)
  end

  # DELETE /environments/:id
  def destroy
    raise Forbidden if params[:id] == "_default"
    begin
      env = Chef::Environment.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound
      raise NotFound, "Cannot load environment #{params[:id]}"
    end
    env.cdb_destroy
    display(env)
  end

  # GET /environments/:environment_id/cookbooks
  def list_cookbooks
    begin
      filtered_cookbooks = Chef::Environment.cdb_load_filtered_cookbook_versions(params[:environment_id])
    rescue Chef::Exceptions::CouchDBNotFound
      raise NotFound, "Cannot load environment #{params[:environment_id]}"
    end
    display(filtered_cookbooks.inject({}) {|res, (k,v)| res[v.name] = absolute_url(:cookbook_version, :cookbook_name=>v.name, :cookbook_version=>v.version); res})
  end

  # GET /environments/:environment_id/nodes
  def list_nodes
    node_list = Chef::Node.cdb_list_by_environment(params[:environment_id])
    display(node_list.inject({}) {|r,n| r[n] = absolute_url(:node, n); r})
  end
  
  # GET /environments/:environment_id/roles/:role_id
  def role
    begin
      role = Chef::Role.cdb_load(params[:role_id])
    rescue Chef::Exceptions::CouchDBNotFound
      raise NotFound, "Cannot load role #{params[:role_id]}"
    end
    display(role.env_run_lists[params[:environment_id]])
  end

  private

end