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

class ChefServerWebui::Clients < ChefServerWebui::Application
  provides :json
  provides :html
  before :login_required
  
  # GET /clients
  def index
    @clients_list = Chef::ApiClient.list()
    render
  end

  # GET /clients/:id
  def show
    load_client
    render
  end

  # GET /clients/:id/edit
  def edit
    load_client
    render 
  end

  # GET /clients/new
  def new
    @client = Chef::ApiClient.new
    render
  end
  
  # POST /clients
  def create
    begin  
      @client = Chef::ApiClient.new
      @client.name(params[:name])
      @client.admin(str_to_bool(params[:admin])) if params[:admin]
      begin
        response = @client.create
      rescue Net::HTTPServerException => e
        if e.message =~ /403/ 
          raise ArgumentError, "Client already exists" 
        else 
          raise e
        end 
      end 
      @private_key = OpenSSL::PKey::RSA.new(response["private_key"])
      @_message = { :notice => "Created Client #{@client.name}. Please copy the following private key as the client's validation key." }
      load_client(params[:name])
      render :show    
    rescue StandardError => e
      @_message = { :error => $! }
      render :new
    end 
  end

  # PUT /clients/:id
  def update
    begin
      load_client
      if params[:regen_private_key]
        @client.create_keys
        @private_key = @client.private_key
      end 
      params[:admin] ? @client.admin(true) : @client.admin(false)
      @client.save
      @_message = @private_key.nil? ? { :notice => "Updated Client" } : { :notice => "Created Client #{@client.name}. Please copy the following private key as the client's validation key." }
      render :show
    rescue
      @_message = { :error => $! }
      render :edit
    end
  end

  # DELETE /clients/:id
  def destroy
    load_client
    @client.destroy
    redirect(absolute_slice_url(:clients), {:message => { :notice => "Client #{params[:id]} deleted successfully" }, :permanent => true})
  end
  
  private
  
  def load_client(name=params[:id])
    begin
      @client = Chef::ApiClient.load(name)
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load client #{name}"
    end
  end 

end

