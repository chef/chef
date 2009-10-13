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
    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Net::HTTPServerException => e      
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    render
  end

  # GET /clients/:id/edit
  def edit
    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
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
      raise ArgumentError, "Client validation key location is required" if params[:private_key_location].empty?
      begin
        response = @client.create
      rescue Net::HTTPServerException => e
        if e.message =~ /403/ 
          raise ArgumentError, "Client already exists" 
        else 
          raise e
        end 
      end 
      client_key_path = params[:private_key_location]
      FileUtils.mkdir_p(File.dirname(client_key_path))
      private_key = OpenSSL::PKey::RSA.new(response["private_key"])
      File.open("#{client_key_path}", "w") {|f| f.print(private_key)}
  
      redirect(slice_url(:clients), :message => { :notice => "Created Client #{@client.name}" })
    
    rescue StandardError => e
      @_message = { :error => $! }
      render :new
    end 
  end

  # PUT /clients/:id
  def update
    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    begin
      @client.admin(str_to_bool(params[:admin])) unless params[:admin].nil?
      @client.save
      @_message = { :notice => "Updated Client" }
      render :show
    rescue
      @_message = { :error => $! }
      render :edit
    end
  end

  # DELETE /clients/:id
  def destroy
    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    @client.destroy
    redirect(absolute_slice_url(:clients), {:message => { :notice => "Client #{params[:id]} deleted successfully" }, :permanent => true})
  end

end

