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
    render :new
  end

  # POST /environments
  def create
    @environment = Chef::Environment.new
    if @environment.update_from_params(params)
      @environment.save
      render :show
    else
      raise "TODO"
      render :new
      # redirect to new, tell them what they did wrong
    end
  end

  # GET /environments/:id/edit
  def edit
    load_environment
    render
  end

  # PUT /environments/:id
  def update
    load_environment
    @environment.update_from_params(params)
    if @environment.invalid_fields.empty? #success
      @environment.save
      render :show
    else
      @environment.update_from_params(params)
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

end