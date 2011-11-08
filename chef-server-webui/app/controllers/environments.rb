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

  provides :html
  before :login_required
  before :require_admin, :only => [:create, :update, :destroy]

  # GET /environments
  def index
    @environment_list = begin
                          Chef::Environment.list
                        rescue => e
                          Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                          @_message = "Could not list environments"
                          {}
                        end
    render
  end

  # GET /environments/:id
  def show
    load_environment
    render
  end

  # GET /environemnts/new
  def new
    @environment = Chef::Environment.new
    load_cookbooks
    render :new
  end

  # POST /environments
  def create
    @environment = Chef::Environment.new
    if @environment.update_from_params(processed_params=process_params)
      begin
        @environment.create
        redirect(url(:environments), :message => { :notice => "Created Environment #{@environment.name}" })
      rescue Net::HTTPServerException => e
        if conflict?(e)
          Chef::Log.debug("Got 409 conflict creating environment #{params[:name]}\n#{format_exception(e)}")
          redirect(url(:new_environment), :message => { :error => "An environment with that name already exists"})
        elsif forbidden?(e)
          # Currently it's not possible to get 403 here. I leave the code here for completeness and may be useful in the future.[nuo]
          Chef::Log.debug("Got 403 forbidden creating environment #{params[:name]}\n#{format_exception(e)}")
          redirect(url(:new_environment), :message => { :error => "Permission Denied. You do not have permission to create an environment."})
        else
          Chef::Log.error("Error communicating with the API server\n#{format_exception(e)}")
          raise
        end
      end
    else
      load_cookbooks
      # By rendering :new, the view shows errors from @environment.invalid_fields
      render :new
    end
  end

  # GET /environments/:id/edit
  def edit
    load_environment
    if @environment.name == "_default"
      msg = { :warning => "The '_default' environment cannot be edited." }
      redirect(url(:environments), :message => msg)
      return
    end
    load_cookbooks
    render
  end

  # PUT /environments/:id
  def update
    load_environment
    if @environment.update_from_params(process_params(params[:id]))
      begin
        @environment.save
        redirect(url(:environment, @environment.name), :message => { :notice => "Updated Environment #{@environment.name}" })
      rescue Net::HTTPServerException => e
        if forbidden?(e)
          # Currently it's not possible to get 403 here. I leave the code here for completeness and may be useful in the future.[nuo]
          Chef::Log.debug("Got 403 forbidden updating environment #{params[:name]}\n#{format_exception(e)}")
          redirect(url(:edit_environment), :message => { :error => "Permission Denied. You do not have permission to update an environment."})
        else
          Chef::Log.error("Error communicating with the API server\n#{format_exception(e)}")
          raise
        end
      end
    else
      load_cookbooks
      # By rendering :new, the view shows errors from @environment.invalid_fields
      render :edit
    end
  end

  # DELETE /environments/:id
  def destroy
    begin
      @environment = Chef::Environment.load(params[:id])
      @environment.destroy
      redirect(absolute_url(:environments), :message => { :notice => "Environment #{@environment.name} deleted successfully." }, :permanent => true)
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @environment_list = Chef::Environment.list()
      @_message = {:error => "Could not delete environment #{params[:id]}: #{e.message}"}
      render :index
    end
  end

  # GET /environments/:environment_id/cookbooks
  def list_cookbooks
    # TODO: rescue loading the environment
    @environment = Chef::Environment.load(params[:environment_id])
    @cookbooks = begin
                   r = Chef::REST.new(Chef::Config[:chef_server_url])
                   r.get_rest("/environments/#{params[:environment_id]}/cookbooks").inject({}) do |res, (cookbook, url)|
                     # we just want the cookbook name and the version
                     res[cookbook] = url.split('/').last
                     res
                   end
                 rescue => e
                   Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                   @_message = "Could not load cookbooks for environment #{params[:environment_id]}"
                   {}
                 end
    render
  end

  # GET /environments/:environment_id/nodes
  def list_nodes
    # TODO: rescue loading the environment
    @environment = Chef::Environment.load(params[:environment_id])
    @nodes = begin
               r = Chef::REST.new(Chef::Config[:chef_server_url])
               r.get_rest("/environments/#{params[:environment_id]}/nodes").keys.sort
             rescue => e
               Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
               @_message = "Could not load nodes for environment #{params[:environment_id]}"
               []
             end
    render
  end

  # GET /environments/:environment/recipes
  def list_recipes
    provides :json
    display(:recipes => list_available_recipes_for(params[:environment_id]))
  end

  # GET /environments/:environment_id/set
  def select_environment
    name = params[:environment_id]
    referer = request.referer || "/nodes"
    if name == '_none'
      session[:environment] = nil
    else
      # TODO: check if environment exists
      session[:environment] = name
    end
    redirect referer
  end

  private

  def load_environment
    @environment = begin
      Chef::Environment.load(params[:id])
    rescue Net::HTTPServerException => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = "Could not load environment #{params[:id]}"
      @environment = Chef::Environment.new
      false
    end
  end

  def load_cookbooks
    begin
      # @cookbooks is a hash, keys are cookbook names, values are their URIs.
      @cookbooks = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("cookbooks").keys.sort
    rescue Net::HTTPServerException => e
      Chef::Log.error(format_exception(e))
      redirect(url(:new_environment), :message => { :error => "Could not load the list of available cookbooks."})
    end
  end

  def process_params(name=params[:name])
    {:name => name, :description => params[:description], :default_attributes => params[:default_attributes], :override_attributes => params[:override_attributes], :cookbook_version => search_params_for_cookbook_version_constraints}
  end

  def search_params_for_cookbook_version_constraints
    cookbook_version_constraints = {}
    index = 0
    params.each do |k,v|
      cookbook_name_box_id = k[/cookbook_name_(\d+)/, 1]
      unless cookbook_name_box_id.nil? || v.nil? || v.empty?
        cookbook_version_constraints[index] = v + " " + params["operator_#{cookbook_name_box_id}"] + " " + params["cookbook_version_#{cookbook_name_box_id}"].strip # e.g. {"0" => "foo > 0.3.0"}
        index = index + 1
      end
    end
    Chef::Log.debug("cookbook version constraints are: #{cookbook_version_constraints.inspect}")
    cookbook_version_constraints
  end

  def cookbook_version_constraints
    @environment.cookbook_versions.inject({}) do |ans, (cb, vc)|
      op, version = vc.split(" ")
      ans[cb] = { "version" => version, "op" => op }
      ans
    end
  end

  def constraint_operators
    %w(~> >= > = < <=)
  end

end
