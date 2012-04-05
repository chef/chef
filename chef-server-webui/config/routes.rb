#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008-2010 Opscode, Inc.
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

ChefServerWebui::Application.routes.draw do
  resources :nodes, :id => /[^\/]+/
  match "/nodes/_environments/:environment_id", :to => "nodes#index", :as => :nodes_by_environment

  resources :clients, :id => /[^\/]+/
  resources :roles

  resources :environments do
    match "/recipes", :only => :get, :to => "environments#list_recipes"
    match "/cookbooks", :to => "environments#list_cookbooks", :as => :cookbooks, :only => :get
    match "/nodes", :to => "environments#list_nodes", :as => :nodes, :only => :get
    match "/select", :to => "environments#select_environment", :as => :select, :only => :get
  end

  # match '/environments/create' :to => "environments#create", :as => :environments_create

  match "/status", :to => "status#index", :as => :status, :only => :get

  resources :searches, :path => "search", :controller => "search"
  match "/search/:search_id/entries", :only => 'get', :to => "search_entries", :action => "index"
  match "/search/:search_id/entries", :only => 'post', :to => "search_entries", :action => "create"
  match "/search/:search_id/entries/:id", :only => 'get', :to => "search_entries", :action => "show"
  match "/search/:search_id/entries/:id", :only => 'put', :to => "search_entries", :action => "create"
  match "/search/:search_id/entries/:id", :only => 'post', :to => "search_entries", :action => "update"
  match "/search/:search_id/entries/:id", :only => 'delete', :to => "search_entries", :action => "destroy"

  match "/cookbooks/_attribute_files", :to => "cookbooks#attribute_files"
  match "/cookbooks/_recipe_files", :to => "cookbooks#recipe_files"
  match "/cookbooks/_definition_files", :to => "cookbooks#definition_files"
  match "/cookbooks/_library_files", :to => "cookbooks#library_files"
  match "/cookbooks/_environments/:environment_id", :to => "cookbooks#index", :as => :cookbooks_by_environment

  match "/cookbooks/:cookbook_id", :cookbook_id => /[\w\.]+/, :only => :get, :to => "cookbooks#cb_versions"
  match "/cookbooks/:cookbook_id/:cb_version", :cb_version => /[\w\.]+/, :only => :get, :to => "cookbooks#show", :as => :show_specific_version_cookbook
  resources :cookbooks

  resources :clients

  match "/databags/:databag_id/databag_items", :only => :get, :to => "databags#show", :id=>":databag_id"

  resources :databags do
    resources :databag_items
  end

  match '/openid/consumer', :to => 'openid_consumer#index', :as => :openid_consumer
  match '/openid/consumer/start', :to => 'openid_consumer#start', :as => :openid_consumer_start
  match '/openid/consumer/login', :to => 'openid_consumer#login', :as => :openid_consumer_login
  match '/openid/consumer/complete', :to => 'openid_consumer#complete', :as => :openid_consumer_complete
  match '/openid/consumer/logout', :to => 'openid_consumer#logout', :as => :openid_consumer_logout

  match '/login', :to => 'users#login', :as => :users_login
  match '/logout', :to => 'users#logout', :as => :users_logout

  match '/users', :to => 'users#index', :as => :users
  match '/users/create', :to => 'users#create', :as => :users_create
  match '/users/start', :to => 'users#start', :as => :users_start

  match '/users/login', :to => 'users#login', :as => :users_login
  match '/users/login_exec', :to => 'users#login_exec', :as => :users_login_exec
  match '/users/complete', :to => 'users#complete', :as => :users_complete
  match '/users/logout', :to => 'users#logout', :as => :users_logout
  match '/users/new', :to => 'users#new', :as => :users_new
  match '/users/:user_id/edit', :to => 'users#edit', :as => :users_edit
  match '/users/:user_id', :to => 'users#show', :as => :users_show
  match '/users/:user_id/delete', :only => :delete, :to => 'users#destroy', :as => :users_delete
  match '/users/:user_id/update', :only => :put, :to => 'users#update', :as => :users_update

  match '/', :to => 'nodes#index', :as => :top
end
