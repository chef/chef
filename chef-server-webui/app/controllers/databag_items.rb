#
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

require 'chef' / 'data_bag_item'

class ChefServerWebui::DatabagItems < ChefServerWebui::Application
  
  provides :html, :json
  before :login_required 
  
  def edit
    begin
      @databag_item = Chef::DataBagItem.load(params[:databag_id], params[:id])
      @default_data = @databag_item
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = { :error => "Could not load the databag item" }   
    end 
    render
  end 
  
  def update
    begin
      @databag_item = Chef::DataBagItem.new
      @databag_item.data_bag params[:databag_id] 
      @databag_item.raw_data = JSON.parse(params[:json_data])
      raise ArgumentError, "Updating id is not allowed" unless @databag_item.raw_data['id'] == params[:id] #to be consistent with other objects, changing id is not allowed.
      @databag_item.save
      redirect(slice_url(:databag_databag_items, :databag_id => params[:databag_id], :id => @databag_item.name), :message => { :notice => "Updated Databag Item #{@databag_item.name}" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = { :error => "Could not update the databag item" }
      @databag_item = Chef::DataBagItem.load(params[:databag_id], params[:id])
      @default_data = @databag_item
      render :edit 
    end         
  end 
  
  def new
    @default_data = {'id'=>''}
    render
  end 
  
  def create
    begin   
      @databag_name = params[:databag_id] 
      @databag_item = Chef::DataBagItem.new
      @databag_item.data_bag @databag_name
      @databag_item.raw_data = JSON.parse(params[:json_data])
      @databag_item.create
      redirect(slice_url(:databag_databag_items, :databag_id => @databag_name), :message => { :notice => "Databag item created successfully" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = { :error => "Could not create databag item" } 
      render :new
    end
  end
  
  def index
    render
  end

  def show
    begin
      @databag_name = params[:databag_id]
      @databag_item_name = params[:id]
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      @databag_item = r.get_rest("data/#{params[:databag_id]}/#{params[:id]}")
      display @databag_item
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      redirect(slice_url(:databag_databag_items), {:message => { :error => "Could not show the databag item" }, :permanent => true})
    end 
  end
  
  def destroy(databag_id=params[:databag_id], item_id=params[:id])
    begin
      @databag_item = Chef::DataBagItem.new
      @databag_item.destroy(databag_id, item_id)
      redirect(slice_url(:databag_databag_items), {:message => { :notice => "Databag item deleted successfully" }, :permanent => true})
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      redirect(slice_url(:databag_databag_items), {:message => { :error => "Could not delete databag item" }, :permanent => true})
    end 
  end 
  
end
