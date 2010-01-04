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
    @node_list = Chef::Node.list 
    render
  end

  def show
    begin
      @node = Chef::Node.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    render
  end

  def new
    @node = Chef::Node.new
    @available_recipes = get_available_recipes 
    @available_roles = Chef::Role.list.keys.sort
    @run_list = @node.run_list
    render
  end

  def edit
    begin
      @node = Chef::Node.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    @available_recipes = get_available_recipes 
    @available_roles = Chef::Role.list.keys.sort
    @run_list = @node.run_list
    render
  end

  def create
    begin      
      @node = Chef::Node.new
      @node.name params[:name]
      @node.attribute = JSON.parse(params[:attributes])
      @node.run_list.reset(params[:for_node] ? params[:for_node] : [])
      raise ArgumentError, "Node name cannot be blank" if (params[:name].nil? || params[:name].length==0)
      begin
        @node.create
      rescue Net::HTTPServerException => e
        if e.message =~ /403/ 
          raise ArgumentError, "Node already exists" 
        else 
          raise e
        end 
      end
      redirect(slice_url(:nodes), :message => { :notice => "Created Node #{@node.name}" })
    rescue StandardError => e
      Chef::Log.error("StandardError creating node: #{e.message}")
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
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end

    begin
      @node.run_list.reset(params[:for_node] ? params[:for_node] : [])
      @node.attribute = JSON.parse(params[:attributes])
      @node.save
      @_message = { :notice => "Updated Node" }
      render :show
    rescue Exception => e
      Chef::Log.error("Exception updating node: #{e.message}")
      @available_recipes = get_available_recipes 
      @available_roles = Chef::Role.list.keys.sort
      @run_list = Chef::RunList.new
      @run_list.reset(params[:for_node])
      @_message = { :error => "Exception raised updating node, #{e.message.length <= 150 ? e.message : "please check logs for details"}" }
      render :edit
    end
  end

  def destroy
    begin
      @node = Chef::Node.load(params[:id])
    rescue Net::HTTPServerException => e 
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    @node.destroy
    redirect(absolute_slice_url(:nodes), {:message => { :notice => "Node #{params[:id]} deleted successfully" }, :permanent => true})
  end
  
end
