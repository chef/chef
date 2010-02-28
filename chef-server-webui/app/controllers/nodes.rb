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

require 'chef' / 'node'

class ChefServerWebui::Nodes < ChefServerWebui::Application
  
  provides :html
  
  before :login_required
  before :authorized_node, :only => [ :update, :destroy ]
  
  def index
    @node_list =  begin
                    Chef::Node.list 
                  rescue => e
                    Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                    @_message = {:error => "Could not list nodes"}
                    {}
                  end 
    render
  end

  def show
    @node = begin      
              Chef::Node.load(params[:id])
            rescue => e
              Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
              @_message = {:error => "Could not load node #{params[:id]}"}
              Chef::Node.new
            end 
    render
  end

  def new
    begin
      @node = Chef::Node.new
      @available_recipes = get_available_recipes 
      @available_roles = Chef::Role.list.keys.sort
      @run_list = @node.run_list
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
      @available_recipes = get_available_recipes 
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
      @node.attribute = JSON.parse(params[:attributes])
      @node.run_list.reset!(params[:for_node] ? params[:for_node] : [])
      raise ArgumentError, "Node name cannot be blank" if (params[:name].nil? || params[:name].length==0)
      @node.create
      redirect(slice_url(:nodes), :message => { :notice => "Created Node #{@node.name}" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @node.attribute = JSON.parse(params[:attributes])
      @available_recipes = get_available_recipes 
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
      @node.run_list.reset!(params[:for_node] ? params[:for_node] : [])
      @node.attribute = JSON.parse(params[:attributes])
      @node.save
      @_message = { :notice => "Updated Node" }
      render :show
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @available_recipes = get_available_recipes 
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
      redirect(absolute_slice_url(:nodes), {:message => { :notice => "Node #{params[:id]} deleted successfully" }, :permanent => true})
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @node_list = Chef::Node.list()
      @_message = {:error => "Could not delete the node"}
      render :index
    end 
  end
  
end
