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
    begin
      env = Chef::Environment.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound
      raise NotFound, "Cannot load environment #{params[:id]}"
    end

    env.description(params["inflated_object"].description)
    env.cdb_save
    env.couchdb_rev = nil
    self.status = 200
    display(env)
  end

  # DELETE /environments/:id
  def destroy
    begin
      env = Chef::Environment.cdb_load(params[:id])
    rescue
      raise NotFound, "Cannot load environment #{params[:id]}"
    end
    env.cdb_destroy
    display(env)
  end

  private

end