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

Merb::Router.prepare do
  resources :nodes, :id => /[^\/]+/
  match("/nodes/_environments/:environment_id").to(:controller => "nodes", :action => "index").name(:nodes_by_environment)

  resources :clients, :id => /[^\/]+/
  resources :roles

  resources :environments do |e|
    e.match("/recipes", :method => "get").to(:controller=>"environments", :action=>"list_recipes")
    e.match("/cookbooks").to(:contoller => "environments", :action => "list_cookbooks").name(:cookbooks)
    e.match("/nodes").to(:controller => "environments", :action => "list_nodes").name(:nodes)
    e.match("/select").to(:controller => "environments", :action => "select_environment").name(:select)
  end

  #match('/environments/create').to(:controller => "environments", :action => "create").name(:environments_create)

  match("/status").to(:controller => "status", :action => "index").name(:status)

  resources :searches, :path => "search", :controller => "search"
  match("/search/:search_id/entries", :method => 'get').to(:controller => "search_entries", :action => "index")
  match("/search/:search_id/entries", :method => 'post').to(:controller => "search_entries", :action => "create")
  match("/search/:search_id/entries/:id", :method => 'get').to(:controller => "search_entries", :action => "show")
  match("/search/:search_id/entries/:id", :method => 'put').to(:controller => "search_entries", :action => "create")
  match("/search/:search_id/entries/:id", :method => 'post').to(:controller => "search_entries", :action => "update")
  match("/search/:search_id/entries/:id", :method => 'delete').to(:controller => "search_entries", :action => "destroy")

  match("/cookbooks/_attribute_files").to(:controller => "cookbooks", :action => "attribute_files")
  match("/cookbooks/_recipe_files").to(:controller => "cookbooks", :action => "recipe_files")
  match("/cookbooks/_definition_files").to(:controller => "cookbooks", :action => "definition_files")
  match("/cookbooks/_library_files").to(:controller => "cookbooks", :action => "library_files")
  match("/cookbooks/_environments/:environment_id").to(:controller => "cookbooks", :action => "index").name(:cookbooks_by_environment)

  match("/cookbooks/:cookbook_id", :cookbook_id => /[\w\.]+/, :method => 'get').to(:controller => "cookbooks", :action => "cb_versions")
  match("/cookbooks/:cookbook_id/:cb_version", :cb_version => /[\w\.]+/, :method => 'get').to(:controller => "cookbooks", :action => "show").name(:show_specific_version_cookbook)
  resources :cookbooks

  resources :clients

  match("/databags/:databag_id/databag_items", :method => 'get').to(:controller => "databags", :action => "show", :id=>":databag_id")

  resources :databags do |s|
    s.resources :databag_items
  end

  match('/openid/consumer').to(:controller => 'openid_consumer', :action => 'index').name(:openid_consumer)
  match('/openid/consumer/start').to(:controller => 'openid_consumer', :action => 'start').name(:openid_consumer_start)
  match('/openid/consumer/login').to(:controller => 'openid_consumer', :action => 'login').name(:openid_consumer_login)
  match('/openid/consumer/complete').to(:controller => 'openid_consumer', :action => 'complete').name(:openid_consumer_complete)
  match('/openid/consumer/logout').to(:controller => 'openid_consumer', :action => 'logout').name(:openid_consumer_logout)

  match('/login').to(:controller=>'users', :action=>'login').name(:users_login)
  match('/logout').to(:controller => 'users', :action => 'logout').name(:users_logout)

  match('/users').to(:controller => 'users', :action => 'index').name(:users)
  match('/users/create').to(:controller => 'users', :action => 'create').name(:users_create)
  match('/users/start').to(:controller => 'users', :action => 'start').name(:users_start)

  match('/users/login').to(:controller => 'users', :action => 'login').name(:users_login)
  match('/users/login_exec').to(:controller => 'users', :action => 'login_exec').name(:users_login_exec)
  match('/users/complete').to(:controller => 'users', :action => 'complete').name(:users_complete)
  match('/users/logout').to(:controller => 'users', :action => 'logout').name(:users_logout)
  match('/users/new').to(:controller => 'users', :action => 'new').name(:users_new)
  match('/users/:user_id/edit').to(:controller => 'users', :action => 'edit').name(:users_edit)
  match('/users/:user_id').to(:controller => 'users', :action => 'show').name(:users_show)
  match('/users/:user_id/delete', :method => 'delete').to(:controller => 'users', :action => 'destroy').name(:users_delete)
  match('/users/:user_id/update', :method => 'put').to(:controller => 'users', :action => 'update').name(:users_update)

  match('/').to(:controller => 'nodes', :action =>'index').name(:top)
end
