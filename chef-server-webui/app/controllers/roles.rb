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
    @role_list =  begin
                   Chef::Role.list()
                  rescue => e
                    Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                    @_message = {:error => "Could not list roles"}
                    {}
                  end 
    render
  end

  # GET /roles/:id
  def show
    @role = begin
              Chef::Role.load(params[:id])
            rescue => e
              Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
              @_message = {:error => "Could not load role #{params[:id]}"}
              Chef::Role.new
            end 
    render
  end

  # GET /roles/new
  def new
    begin
      @available_recipes = get_available_recipes 
      @role = Chef::Role.new
      @available_roles = Chef::Role.list.keys.sort
      @run_list = @role.run_list
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @role_list = Chef::Role.list()
      @_message = {:error => "Could not load available recipes, roles, or the run list."}
      render :index
    end 
  end

  # GET /roles/:id/edit
  def edit
    begin
      @role = Chef::Role.load(params[:id])
      @available_recipes = get_available_recipes 
      @available_roles = Chef::Role.list.keys.sort
      @run_list = @role.run_list
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @role = Chef::Role.new
      @available_recipes = []
      @available_roles = []
      @run_list = []
      @_message = {:error => "Could not load role #{params[:id]}, the available recipes, roles, or the run list"}
    end 
    render
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
      @role.create
      redirect(slice_url(:roles), :message => { :notice => "Created Role #{@role.name}" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @available_recipes = get_available_recipes 
      @role = Chef::Role.new
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @run_list = params[:for_role] ? params[:for_role] : []
      @_message = { :error => "Could not create role" }
      render :new
    end
  end

  # PUT /roles/:id
  def update
    begin
      @role = Chef::Role.load(params[:id])
      @role.run_list(params[:for_role] ? params[:for_role] : [])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @role.save
      @_message = { :notice => "Updated Role" }
      render :show
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @available_recipes = get_available_recipes 
      @run_list = params[:for_role] ? params[:for_role] : []
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @_message = {:error => "Could not update role #{params[:id]}"}
      render :edit
    end
  end

  # DELETE /roles/:id
  def destroy
    begin
      @role = Chef::Role.load(params[:id])
      @role.destroy
      redirect(absolute_slice_url(:roles), :message => { :notice => "Role #{@role.name} deleted successfully." }, :permanent => true)
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @role_list = Chef::Role.list()
      @_message = {:error => "Could not delete role #{params[:id]}"}
      render :index
    end 
  end

end
