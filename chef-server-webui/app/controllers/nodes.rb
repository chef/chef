#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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

require 'chef/node'

class Nodes < Application

  provides :html

  before :login_required
  before :require_admin, :only => [:destroy]

  def index
    begin
      if session[:environment]
        node_hash = Chef::Node.list_by_environment(session[:environment])
      else
        node_hash = Chef::Node.list
      end
      @node_list = node_hash.keys.sort
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = {:error => "Could not list nodes"}
      @node_hash = {}
    end
    render
  end

  def show
    begin
      @node =Chef::Node.load(params[:id])
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = {:error => "Could not load node #{params[:id]}"}
      @node = Chef::Node.new
    end
    render
  end

  def new
    begin
      @node = Chef::Node.new
      @node.chef_environment(session[:environment] || "_default")
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = Chef::Role.list.keys.sort
      @run_list = @node.run_list
      @env = session[:environment]
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @node_list = Chef::Node.list()
      @_message = {:error => "Could not load available recipes, roles, or the run list"}
      render :index
    end
  end

  def edit
    begin
      @node = Chef::Node.load(params[:id])
      @env = @node.chef_environment
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = Chef::Role.list.keys.sort
      @run_list = @node.run_list
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @node = Chef::Node.new
      @available_recipes = []
      @available_roles = []
      @run_list = []
      @_message = {:error => "Could not load node #{params[:id]}"}
      render
    end
  end

  def create
    begin
      @node = Chef::Node.new
      @node.name params[:name]
      @node.chef_environment params[:chef_environment]
      @node.normal_attrs = Chef::JSONCompat.from_json(params[:attributes])
      @node.run_list.reset!(params[:for_node] ? params[:for_node] : [])
      raise ArgumentError, "Node name cannot be blank" if (params[:name].nil? || params[:name].length==0)
      @node.create
      redirect(url(:nodes), :message => { :notice => "Created Node #{@node.name}" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @node.normal_attrs = Chef::JSONCompat.from_json(params[:attributes])
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = Chef::Role.list.keys.sort
      @node.run_list params[:for_node]
      @run_list = @node.run_list
      @_message = { :error => "Exception raised creating node, #{e.message.length <= 150 ? e.message : "please check logs for details"}" }
      render :new
    end
  end

  def update
    begin
      @node = Chef::Node.load(params[:id])
      @node.chef_environment(params[:chef_environment])
      @node.run_list.reset!(params[:for_node] ? params[:for_node] : [])
      @node.normal_attrs = Chef::JSONCompat.from_json(params[:attributes])
      @node.save
      @_message = { :notice => "Updated Node" }
      render :show
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @available_recipes = list_available_recipes_for(@node.chef_environment)
      @available_roles = Chef::Role.list.keys.sort
      @run_list = Chef::RunList.new
      @run_list.reset!(params[:for_node])
      @_message = { :error => "Exception raised updating node, #{e.message.length <= 150 ? e.message : "please check logs for details"}" }
      render :edit
    end
  end

  def destroy
    begin
      @node = Chef::Node.load(params[:id])
      @node.destroy
      redirect(absolute_url(:nodes), {:message => { :notice => "Node #{params[:id]} deleted successfully" }, :permanent => true})
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @node_list = Chef::Node.list()
      @_message = {:error => "Could not delete the node"}
      render :index
    end
  end

end
