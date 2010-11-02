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
    @environment = begin
                     Chef::Environment.load(params[:id])
                   rescue => e
                     Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                     @_message = "Could not load environment #{params[:id]}"
                     Chef::Environment.new
                   end
    render
  end

  # GET /environemnts/new
  def new
    # TODO: implement this
    render
  end

  # POST /environments
  def create
    # TODO: implement this
  end

  # GET /environments/:id/edit
  def edit
    # TODO: implement this
    render
  end

  # PUT /environments/:id
  def update
    # TODO: implement this
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
end