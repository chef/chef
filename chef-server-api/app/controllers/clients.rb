#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/api_client'

class Clients < Application
  provides :json

  before :authenticate_every
  before :is_admin, :only => [ :index, :update, :destroy ]
  before :is_admin_or_validator, :only => [ :create ]
  before :admin_or_requesting_node, :only => [ :show ]
  
  # GET /clients
  def index
    @list = Chef::ApiClient.cdb_list(true)
    display(@list.inject({}) { |result, element| result[element.name] = absolute_url(:client, :id => element.name); result })
  end

  # GET /clients/:id
  def show
    begin
      @client = Chef::ApiClient.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    #display({ :name => @client.name, :admin => @client.admin, :public_key => @client.public_key })
    display @client
  end

  # POST /clients
  def create
    exists = true 
    if params.has_key?(:inflated_object)
      params[:name] ||= params[:inflated_object].name
      params[:admin] ||= params[:inflated_object].admin
    end

    # We can only create clients if we're the admin or the validator.
    # But only allow creating admin clients if we're already an admin.
    if params[:admin] == true && @auth_user.admin != true
      raise Forbidden, "You are not allowed to take this action."
    end

    begin
      Chef::ApiClient.cdb_load(params[:name])
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false 
    end
    raise Conflict, "Client already exists" if exists

    @client = Chef::ApiClient.new
    @client.name(params[:name])
    @client.admin(params[:admin]) if params[:admin]
    @client.create_keys
    @client.cdb_save
    
    self.status = 201
    headers['Location'] = absolute_url(:client, @client.name)
    display({ :uri => absolute_url(:client, @client.name), :private_key => @client.private_key })
  end

  # PUT /clients/:id
  def update
    if params.has_key?(:inflated_object)
      params[:private_key] ||= params[:inflated_object].private_key
      params[:admin] ||= params[:inflated_object].admin
    end

    begin
      @client = Chef::ApiClient.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    
    @client.admin(params[:admin]) unless params[:admin].nil?

    results = { :name => @client.name, :admin => @client.admin }

    if params[:private_key] == true
      @client.create_keys
      results[:private_key] = @client.private_key
    end

    @client.cdb_save

    display(results)
  end

  # DELETE /clients/:id
  def destroy
    begin
      @client = Chef::ApiClient.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    @client.cdb_destroy
    display({ :name => @client.name })
  end

end

