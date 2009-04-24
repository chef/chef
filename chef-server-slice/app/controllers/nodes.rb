#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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

class ChefServerSlice::Nodes < ChefServerSlice::Application
  
  provides :html, :json
  
  before :fix_up_node_id
  before :login_required,  :only => [ :create, :update, :destroy ]
  before :authorized_node, :only => [ :update, :destroy ]
  
  def index
    @node_list = Chef::Node.list 
    display @node_list
  end

  def show
    begin
      @node = Chef::Node.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    if request.xhr?
      render JSON.pretty_generate(@node), :layout => false
    else
      display @node
    end
  end

  def create
    @node = params.has_key?("inflated_object") ? params["inflated_object"] : nil    
    if @node
      @status = 202
      @node.save
      display @node
    else
      raise BadRequest, "You must provide a Node to create"
    end
  end

  def update
    if request.xhr?
      @node = JSON.parse(params[:value])
    else      
      @node = params.has_key?("inflated_object") ? params["inflated_object"] : nil
    end
    
    if @node
      @status = 202
      @node.save
      if request.xhr?
        partial :node, :node => @node
      else
        display @node
      end
    else
      raise NotFound, "You must provide a Node to update"
    end
  end

  def destroy
    begin
      @node = Chef::Node.load(params[:id])
    rescue RuntimeError => e
      raise BadRequest, "Node #{params[:id]} does not exist to destroy!"
    end
    @node.destroy
    if request.xhr?
      @status = 202
      display @node
    else
      redirect(absolute_slice_url(:nodes), {:message => { :notice => "Node #{params[:id]} deleted successfully" }, :permanent => true})
    end
  end
  
end
