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

class Roles < Application

  provides :html
  before :login_required
  before :require_admin, :only => [:destroy]

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
              @_message = {:error => "Could not load role #{params[:id]}."}
              Chef::Role.new
            end

    @current_env = session[:environment] || "_default"
    @env_run_list_exists = @role.env_run_lists.has_key?(@current_env)
    @run_list = @role.run_list_for(@current_env)
    @recipes = @run_list.expand(@current_env, 'server').recipes
    render
  end

  # GET /roles/new
  def new
    begin
      @role = Chef::Role.new
      @available_roles = Chef::Role.list.keys.sort
      @environments = Chef::Environment.list.keys.sort
      @run_lists = @environments.inject({}) { |run_lists, env| run_lists[env] = @role.env_run_lists[env]; run_lists}
      @current_env = "_default"
      @available_recipes = list_available_recipes_for(@current_env)
      @existing_run_list_environments = @role.env_run_lists.keys
      # merb select helper has no :include_blank => true, so fix the view in the controller.
      @existing_run_list_environments.unshift('')
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      redirect url(:roles), :message => {:error => "Could not load available recipes, roles, or the run list."}
    end
  end

  # GET /roles/:id/edit
  def edit
    begin
      @role = Chef::Role.load(params[:id])
      @available_roles = Chef::Role.list.keys.sort
      @environments = Chef::Environment.list.keys.sort
      @current_env = session[:environment] || "_default"
      @run_list = @role.run_list
      @run_lists = @environments.inject({}) { |run_lists, env| run_lists[env] = @role.env_run_lists[env]; run_lists}
      @existing_run_list_environments = @role.env_run_lists.keys
      # merb select helper has no :include_blank => true, so fix the view in the controller.
      @existing_run_list_environments.unshift('')
      @available_recipes = list_available_recipes_for(@current_env)
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      redirect url(:roles), :message => {:error => "Could not load role #{params[:id]}. #{e.message}"}
    end
  end

  # POST /roles
  def create
    begin
      @role = Chef::Role.new
      @role.name(params[:name])
      @role.env_run_lists(params[:env_run_lists])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(Chef::JSONCompat.from_json(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(Chef::JSONCompat.from_json(params[:override_attributes])) if params[:override_attributes] != ''
      @role.create
      redirect(url(:roles), :message => { :notice => "Created Role #{@role.name}" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      redirect(url(:new_role), :message => { :error => "Could not create role. #{e.message}" })
    end
  end

  # PUT /roles/:id
  def update
    begin
      @role = Chef::Role.load(params[:id])
      @role.env_run_lists(params[:env_run_lists])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(Chef::JSONCompat.from_json(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(Chef::JSONCompat.from_json(params[:override_attributes])) if params[:override_attributes] != ''
      @role.save
      redirect(url(:role, params[:id]), :message => { :notice => "Updated Role" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      redirect url(:edit_role, params[:id]), :message => {:error => "Could not update role #{params[:id]}. #{e.message}"}
    end
  end

  # DELETE /roles/:id
  def destroy
    begin
      @role = Chef::Role.load(params[:id])
      @role.destroy
      redirect(absolute_url(:roles), :message => { :notice => "Role #{@role.name} deleted successfully." }, :permanent => true)
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      redirect url(:roles), :message => {:error => "Could not delete role #{params[:id]}"}
    end
  end

end
