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
  resources :users

  # Nodes
  resources :nodes, :id => /[^\/]+/
  match('/nodes/:id/cookbooks',
        :id => /[^\/]+/,
        :method => 'get').
    to(:controller => "nodes", :action => "cookbooks")
  # Roles
  resources :roles do |r|
    r.match('/environments', :method => 'get').to(:controller => "roles", :action => "environments")
    r.match('/environments/:env_id', :method => 'get').to(:controller=>"roles", :action=>"environment")
  end

  # Environments
  resources :environments do |e|
    e.match("/cookbooks", :method => "get").to(:controller=>"environments", :action=>"list_cookbooks")
    e.match("/nodes", :method => "get").to(:controller=>"environments", :action=>"list_nodes")
    e.match("/roles/:role_id", :method => "get").to(:controller=>"environments", :action => "role")
  end

  # Status
  match("/status").to(:controller => "status", :action => "index").name(:status)

  # Clients
  match("/clients", :method=>"post").to(:controller=>'clients', :action=>'create')
  match("/clients", :method=>"get").to(:controller=>'clients', :action=>'index').name(:clients)
  match("/clients/:id", :id => /[\w\.-]+/, :method=>"get").to(:controller=>'clients', :action=>'show').name(:client)
  match("/clients/:id", :id => /[\w\.-]+/, :method=>"put").to(:controller=>'clients', :action=>'update')
  match("/clients/:id", :id => /[\w\.-]+/, :method=>"delete").to(:controller=>'clients', :action=>'destroy')

  # Search
  resources :search
  match('/search/reindex', :method => 'post').to(:controller => "search", :action => "reindex")

  # Cookbooks
  match('/nodes/:id/cookbooks', :method => 'get').to(:controller => "nodes", :action => "cookbooks")

  match("/cookbooks",
        :method => 'get'
        ).to(:controller => "cookbooks", :action => "index")

  match("/cookbooks/_latest", :method=>'get').to(:controller=>'cookbooks',:action=>'index_latest')

  match("/cookbooks/_recipes", :method=>'get').to(:controller=>'cookbooks',:action=>'index_recipes')

  match("/cookbooks/:cookbook_name/:cookbook_version",
        :method => 'put',
        :cookbook_name => /[\w\.]+/,
        :cookbook_version => /\d+\.\d+\.\d+/
        ).to(:controller => "cookbooks", :action => "update")

  match("/cookbooks/:cookbook_name/:cookbook_version",
        :method => 'get',
        :cookbook_name => /[\w\.]+/,
        :cookbook_version => /\d+\.\d+\.\d+|_latest/
        ).to(:controller => "cookbooks", :action => "show").name(:cookbook_version)

  match("/cookbooks/:cookbook_name/:cookbook_version",
        :method => 'delete',
        :cookbook_name => /[\w\.]+/,
        :cookbook_version => /\d+\.\d+\.\d+|_latest/
        ).to(:controller => "cookbooks", :action => "destroy")

  match("/cookbooks/:cookbook_name",
        :method => 'get',
        :cookbook_name => /[\w\.]+/
        ).to(:controller => "cookbooks", :action => "show_versions").name(:cookbook)

  match("/cookbooks/:cookbook_name/:cookbook_version/files/:checksum",
        :cookbook_name => /[\w\.]+/,
        :cookbook_version => /(\d+\.\d+\.\d+|_latest)/
        ).to(
             :controller => "cookbooks",
             :action => "show_file"
             ).name(:cookbook_file)

  # Sandbox
  match('/sandboxes', :method => 'get').to(:controller => "sandboxes", :action => "index").name(:sandboxes)
  match('/sandboxes', :method => 'post').to(:controller => "sandboxes", :action => "create")
  match('/sandboxes/:sandbox_id', :method => 'get', :sandbox_id => /[\w\.]+/).to(:controller => "sandboxes", :action => "show").name(:sandbox)
  match('/sandboxes/:sandbox_id', :method => 'put', :sandbox_id => /[\w\.]+/).to(:controller => "sandboxes", :action => "update")
  match('/sandboxes/:sandbox_id/:checksum', :method => 'put', :sandbox_id => /[\w\.]+/, :checksum => /[\w\.]+/).to(:controller => "sandboxes", :action => "upload_checksum").name(:sandbox_checksum)
  match('/sandboxes/:sandbox_id/:checksum', :method => 'get', :sandbox_id => /[\w\.]+/, :checksum => /[\w\.]+/).to(:controller => "sandboxes", :action => "download_checksum")

  # Data
  match("/data/:data_bag_id/:id", :method => 'get').to(:controller => "data_item", :action => "show").name("data_bag_item")
  match("/data/:data_bag_id", :method => 'post').to(:controller => "data_item", :action => "create").name("create_data_bag_item")
  match("/data/:data_bag_id/:id", :method => 'put').to(:controller => "data_item", :action => "update").name("update_data_bag_item")
  match("/data/:data_bag_id/:id", :method => 'delete').to(:controller => "data_item", :action => "destroy").name("destroy_data_bag_item")
  resources :data, :controller => "data_bags"

  match('/').to(:controller => 'main', :action =>'index').name(:top)

end
