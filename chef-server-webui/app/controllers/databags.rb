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

require 'chef' / 'data_bag'

class ChefServerWebui::Databags < ChefServerWebui::Application
  
  provides :html, :json
  before :login_required 
  
  def new
    @databag = Chef::DataBag.new
    render
  end 
  
  def create
    begin
      @databag = Chef::DataBag.new
      @databag.name params[:name]
      @databag.create
      redirect(slice_url(:databags), :message => { :notice => "Created Databag #{@databag.name}" })
    rescue StandardError => e
      @_message = { :error => $! } 
      render :new
    end 
  end
  
  def index
    begin
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      @databags = r.get_rest("data")
      render
    rescue
      @_message = { :error => $! } 
      @databags = {}
      render
    end
  end

  def show
    begin
      @databag_name = params[:id]
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      @databag = r.get_rest("data/#{params[:id]}")
      raise NotFound unless @databag
      display @databag
    rescue
      @databags = Chef::DataBag.list
      @_message =  { :error => $!}    
      render :index
    end 
  end
  
  def destroy
    begin
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      r.delete_rest("data/#{params[:id]}")
      redirect(absolute_slice_url(:databags), {:message => { :notice => "Data bag #{params[:id]} deleted successfully" }, :permanent => true})
    rescue
      @databags = Chef::DataBag.list
      @_message =  { :error => $!}
      render :index
    end 
  end
  
end
