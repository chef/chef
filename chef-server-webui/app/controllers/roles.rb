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

require 'chef/role'

class ChefServerWebui::Roles < ChefServerWebui::Application

  provides :html
  before :login_required 
  
  # GET /roles
  def index
    begin
      @role_list = Chef::Role.list()
      render
    rescue
      @role_list = {}
      @_message = {:error => $!}
      render
    end 
  end

  # GET /roles/:id
  def show
    begin
      begin
        @role = Chef::Role.load(params[:id])
      rescue Net::HTTPServerException => e
        raise NotFound, "Cannot load role #{params[:id]}"
      end
      render
    rescue
      @role = Chef::Role.new
      @_message = {:error => $!}
      render
    end 
  end

  # GET /roles/new
  def new
    begin
      @available_recipes = get_available_recipes 
      @role = Chef::Role.new
      @available_roles = Chef::Role.list.keys.sort
      @run_list = @role.run_list
      render
    rescue
      @role_list = Chef::Role.list()
      @_message = {:error => $!}
      render :index
    end 
  end

  # GET /roles/:id/edit
  def edit
    begin
      begin
        @role = Chef::Role.load(params[:id])
      rescue Net::HTTPServerException => e
        raise NotFound, "Cannot load role #{params[:id]}"
      end
      @available_recipes = get_available_recipes 
      @available_roles = Chef::Role.list.keys.sort
      @run_list = @role.run_list
      render 
    rescue
      @role = Chef::Role.new
      @available_recipes = []
      @available_roles = []
      @run_list = []
      @_message = {:error => $!}
      render
    end 
  end

  # POST /roles
  def create
    begin
      @role = Chef::Role.new
      @role.name(params[:name])
      @role.run_list(params[:for_role] ? params[:for_role] : [])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      begin
        @role.create
      rescue Net::HTTPServerException => e
        if e.message =~ /403/ 
          raise ArgumentError, "Role already exists" 
        else 
          raise e
        end 
      end
      redirect(slice_url(:roles), :message => { :notice => "Created Role #{@role.name}" })
    rescue ArgumentError 
      @available_recipes = get_available_recipes 
      @role = Chef::Role.new
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @run_list = params[:for_role] ? params[:for_role] : []
      @_message = { :error => $! }
      render :new
    end
  end

  # PUT /roles/:id
  def update
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end

    begin
      @role.run_list(params[:for_role] ? params[:for_role] : [])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @role.save
      @_message = { :notice => "Updated Role" }
      render :show
    rescue ArgumentError
      @available_recipes = get_available_recipes 
      @run_list = params[:for_role] ? params[:for_role] : []
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      render :edit
    end
  end

  # DELETE /roles/:id
  def destroy
    begin
      begin
        @role = Chef::Role.load(params[:id])
      rescue Net::HTTPServerException => e
        raise NotFound, "Cannot load role #{params[:id]}"
      end
      @role.destroy
      redirect(absolute_slice_url(:roles), :message => { :notice => "Role #{@role.name} deleted successfully." }, :permanent => true)
    rescue
      @role_list = Chef::Role.list()
      @_message = {:error => $!}
      render :index
    end 
  end

end
