#
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

class ClientsController < ApplicationController
  respond_to :html, :json
  before_filter :login_required
  before_filter :require_admin, :exclude => [:index, :show]

  # GET /clients
  def index
    begin
      @clients_list = Chef::ApiClient.list().keys.sort
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      flash[:error] = "Could not list clients"
      @clients_list = []
    end
    respond_with @clients_list
  end

  # GET /clients/:id
  def show
    @client = begin
                @client = Chef::ApiClient.load(params[:id])
              rescue => e
                Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                flash[:error] = "Could not load client #{params[:id]}"
                Chef::ApiClient.new
              end
    respond_with @client
  end

  # GET /clients/:id/edit
  def edit
    @client = begin
                Chef::ApiClient.load(params[:id])
              rescue => e
                Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                flash[:error] = "Could not load client #{params[:id]}"
                Chef::ApiClient.new
              end
    respond_with @client
  end

  # GET /clients/new
  def new
    raise AdminAccessRequired unless params[:user_id] == session[:user] unless session[:level] == :admin
    @client = Chef::ApiClient.new
    respond_with @client
  end

  # POST /clients
  def create
    begin
      @client = Chef::ApiClient.new
      @client.name(params[:name])
      @client.admin(str_to_bool(params[:admin])) if params[:admin]
      response = @client.create
      @private_key = OpenSSL::PKey::RSA.new(response["private_key"])
      flash[:notice] = "Created Client #{@client.name}. Please copy the following private key as the client's validation key."
      @client = Chef::ApiClient.load(params[:name])
      render :show
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      flash[:error] = "Could not create client"
      render :new
    end
  end

  # PUT /clients/:id
  def update
    begin
      @client = Chef::ApiClient.load(params[:id])
      if params[:regen_private_key]
        @client.create_keys
        @private_key = @client.private_key
      end
      params[:admin] ? @client.admin(true) : @client.admin(false)
      @client.save
      flash[:notice] = @private_key.nil? ? "Updated Client" : "Created Client #{@client.name}. Please copy the following private key as the client's validation key."
      render :show
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      flash[:error] = "Could not update client"
      render :edit
    end
  end

  # DELETE /clients/:id
  def destroy
    begin
      @client = Chef::ApiClient.load(params[:id])
      @client.destroy
      redirect_to clients_url, :notice => "Client #{params[:id]} deleted successfully"
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      flash[:error] = "Could not delete client #{params[:id]}"
      @clients_list = Chef::ApiClient.list()
      render :index
    end
  end

end

