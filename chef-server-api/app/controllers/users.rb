#
# Author:: Nuo Yan (<nuo@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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


require File.join("chef", "webui_user")

class Users < Application
  provides :json

  before :authenticate_every
  before :is_admin, :only => [ :create, :destroy, :update ]

  # GET to /users
  def index
    @user_list = Chef::WebUIUser.cdb_list
    display(@user_list.inject({}) { |r,n| r[n] = absolute_url(:user, n); r })
  end

  # GET to /users/:id
  def show
    begin
      @user = Chef::WebUIUser.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load user #{params[:id]}"
    end
    display @user
  end

  # PUT to /users/:id
  def update
    begin
      Chef::WebUIUser.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load user #{params[:id]}"
    end
    @user = params['inflated_object']
    @user.cdb_save
    display(@user)
  end

  # POST to /users
  def create
    @user = params["inflated_object"]
    begin
      Chef::WebUIUser.cdb_load(@user.name)
    rescue Chef::Exceptions::CouchDBNotFound
      @user.cdb_save
      self.status = 201
    else
      raise Conflict, "User already exists"
    end
    display({ :uri => absolute_url(:user, @user.name) })
  end

  def destroy
    begin
      @user = Chef::WebUIUser.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load user #{params[:id]}"
    end
    @user.cdb_destroy
    display @user
  end
end
