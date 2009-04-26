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

require 'openid'
require 'chef' / 'openid_registration'

class ChefServerSlice::OpenidRegister < ChefServerSlice::Application

  provides :html, :json
  
  before :fix_up_node_id
  before :login_required,  :only => [ :update, :destroy, :validate, :admin ]
  before :authorized_node, :only => [ :update, :destroy, :validate, :admin ]

  def index
    @headers['X-XRDS-Location'] = Chef::Config[:openid_url] + "/openid/server/server/xrds"
    @registered_nodes = Chef::OpenIDRegistration.list(true)
    Chef::Log.debug(@registered_nodes.inspect)
    display @registered_nodes
  end
  
  def show
    begin
      @registered_node = Chef::OpenIDRegistration.load(params[:id])
    rescue Net::HTTPServerException => e
      if e.message =~ /^404/
        raise NotFound, "Cannot load node registration for #{params[:id]}"
      else
        raise e
      end
    end
     Chef::Log.debug(@registered_node.inspect)
     display @registered_node
  end
  
  def create
    params.has_key?(:id) or raise BadRequest, "You must provide an id to register"
    params.has_key?(:password) or raise BadRequest, "You must provide a password to register"
    if Chef::OpenIDRegistration.has_key?(params[:id])
      raise BadRequest, "You cannot re-register #{params[:id]}!"
    end
    @registered_node = Chef::OpenIDRegistration.new
    @registered_node.name = params[:id]
    @registered_node.set_password(params[:password])
    if Chef::Config[:validation_token]
      if params[:validation_token] == Chef::Config[:validation_token]
        @registered_node.validated = true
      else
        @registered_node.validated = false
      end
    else
      @registered_node.validated = false
    end
    @registered_node.save
    display @registered_node
  end
  
  def update
    raise BadRequest, "You cannot update your registration -- delete #{params[:id]} and re-register"
  end
  
  def destroy
    begin
      r = Chef::OpenIDRegistration.load(params[:id])
    rescue Exception => e
      raise BadRequest, "Cannot find the registration for #{params[:id]}"
    end
    r.destroy
    if content_type == :html
      redirect slice_url(:registrations)
    else
      display({ :message => "Deleted registration for #{params[:id]}"})
    end
  end
  
  def validate
    begin
      r = Chef::OpenIDRegistration.load(params[:id])
    rescue Exception => e
      raise BadRequest, "Cannot find the registration for #{params[:id]}"
    end
    r.validated = r.validated ? false : true
    r.save
    redirect slice_url(:registrations)
  end
  
  def admin
    begin
      r = Chef::OpenIDRegistration.load(params[:id])
    rescue Exception => e
      raise BadRequest, "Cannot find the registration for #{params[:id]}"
    end
    r.admin = r.admin ? false : true
    r.save
    redirect slice_url(:registrations)
  end
end
