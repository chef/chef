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

require 'chef'/'webui_user'
require 'uri'
require 'merb-param-protection'

class Users < Application

  provides :html
  before :login_required, :exclude => [:login, :login_exec, :complete]
  before :require_admin, :exclude => [:login, :login_exec, :complete, :show, :edit, :logout, :destroy]
  log_params_filtered :password, :password2, :new_password, :confirm_new_password

  # List users, only if the user is admin.
  def index
    begin
      @users = Chef::WebUIUser.list
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      set_user_and_redirect
    end
  end

  # Edit user. Admin can edit everyone, non-admin user can only edit itself.
  def edit
    begin
      @user = Chef::WebUIUser.load(params[:user_id])
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      set_user_and_redirect
    end
  end

  # Show the details of a user. If the user is not admin, only able to show itself; otherwise able to show everyone
  def show
    begin
      @user = Chef::WebUIUser.load(params[:user_id])
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      set_user_and_redirect
    end
  end

  # PUT to /users/:user_id/update
  def update
    begin
      @user = Chef::WebUIUser.load(params[:user_id])

      if session[:level] == :admin and !is_last_admin?
        @user.admin = params[:admin] =~ /1/ ? true : false
      end

      if params[:user_id] == session[:user] && params[:admin] == 'false'
        session[:level] = :user
      end

      if not params[:new_password].nil? and not params[:new_password].length == 0
        @user.set_password(params[:new_password], params[:confirm_new_password])
      end

      if params[:openid].length == 0 or params[:openid].nil?
        @user.set_openid(nil)
      else
        @user.set_openid(URI.parse(params[:openid]).normalize.to_s)
      end
      @user.save
      @_message = { :notice => "Updated user #{@user.name}." }
      render :show
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @u = Chef::WebUIUser.load(params[:user_id])
      @_message = { :error => "Could not update user #{@user.name}." }
      render :edit
    end
  end

  def new
    begin
      @user = Chef::WebUIUser.new
      render
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      set_user_and_redirect
    end
  end

  def create
    begin
      @user = Chef::WebUIUser.new
      @user.name = params[:name]
      @user.set_password(params[:password], params[:password2])
      @user.admin = true if params[:admin]
      (params[:openid].length == 0 || params[:openid].nil?) ? @user.set_openid(nil) : @user.set_openid(URI.parse(params[:openid]).normalize.to_s)
      @user.create
      redirect(url(:users), :message => { :notice => "Created User #{params[:name]}" })
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = { :error => "Could not create user" }
      session[:level] != :admin ? set_user_and_redirect : (render :new)
    end
  end

  def login
    @user = Chef::WebUIUser.new
    session[:user] ? redirect(url(:nodes), :message => { :warning => "You've already logged in with user #{session[:user]}"  }) : (render :layout => 'login')
  end

  def login_exec
    begin
      @user = Chef::WebUIUser.load(params[:name])
      raise(Unauthorized, "Wrong username or password.") unless @user.verify_password(params[:password])
      complete
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @user = Chef::WebUIUser.new
      @_message = { :error => "Could not complete logging in." }
      render :login
    end
  end

  def complete
    session[:user] = params[:name]
    session[:level] = (@user.admin == true ? :admin : :user)
    (@user.name == Chef::Config[:web_ui_admin_user_name] && @user.verify_password(Chef::Config[:web_ui_admin_default_password])) ? redirect(url(:users_edit, :user_id => @user.name), :message => { :warning => "Please change the default password" }) : redirect_back_or_default(absolute_url(:nodes))
  end

  def logout
    cleanup_session
    redirect url(:top)
  end

  def destroy
    begin
      raise Forbidden, "A non-admin user can only delete itself" if (params[:user_id] != session[:user] && session[:level] != :admin)
      raise Forbidden, "The last admin user cannot be deleted" if (is_admin? && is_last_admin? && session[:user] == params[:user_id])
      @user = Chef::WebUIUser.load(params[:user_id])
      @user.destroy
      logout if params[:user_id] == session[:user]
      redirect(absolute_url(:users), {:message => { :notice => "User #{params[:user_id]} deleted successfully." }, :permanent => true})
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      session[:level] != :admin ? set_user_and_redirect : redirect_to_list_users({ :error => $! })
    end
  end

  private

    def set_user_and_redirect
      begin
        @user = Chef::WebUIUser.load(session[:user]) rescue (raise NotFound, "Cannot find User #{session[:user]}, maybe it got deleted by an Administrator.")
      rescue
        logout_and_redirect_to_login
      else
        redirect(url(:users_show, :user_id => session[:user]), {:message => { :error => $! }, :permanent => true})
      end
    end

    def redirect_to_list_users(message)
      @_message = message
      @users = Chef::WebUIUser.list
      render :index
    end

end
