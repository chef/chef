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

require 'chef/data_bag'

class DatabagsController < ApplicationController

  respond_to :html, :json
  before_filter :login_required
  before_filter :require_admin

  def new
    @databag = Chef::DataBag.new
  end

  def create
    begin
      @databag = Chef::DataBag.new
      @databag.name params[:name]
      @databag.create
      redirect_to databags_url, :notice => "Created Databag #{@databag.name}"
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = { :error => "Could not create databag" }
      render :new
    end
  end

  def index
    @databags = begin
                  Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("data")
                rescue => e
                  Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
                  @_message = { :error => "Could not list databags" }
                  {}
                end
  end

  def show
    begin
      @databag_name = params[:id]
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      @databag = r.get_rest("data/#{params[:id]}")
      raise NotFound unless @databag
      display @databag
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @databags = Chef::DataBag.list
      @_message =  { :error => "Could not load databag"}
      render :index
    end
  end

  def destroy
    begin
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      r.delete_rest("data/#{params[:id]}")
      redirect_to databags_url, :notice => "Data bag #{params[:id]} deleted successfully"
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @databags = Chef::DataBag.list
      @_message =  { :error => "Could not delete databag"}
      render :index
    end
  end

end
