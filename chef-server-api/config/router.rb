Merb::Router.prepare do
  resources :users

  # Nodes
  resources :nodes, :id => /[^\/]+/
  match('/nodes/:id/cookbooks',
              :id => /[^\/]+/,
              :method => 'get').
              to(:controller => "nodes", :action => "cookbooks")
  # Roles
  resources :roles

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

  resources :cookbooks
  match("/cookbooks/:cookbook_id/_content", :method => 'get', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "get_tarball")
  match("/cookbooks/:cookbook_id/_content", :method => 'put', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "update")
  match("/cookbooks/:cookbook_id/:segment", :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "show_segment").name(:cookbook_segment)

  # Data
  match("/data/:data_bag_id/:id", :method => 'get').to(:controller => "data_item", :action => "show").name("data_bag_item")
  match("/data/:data_bag_id", :method => 'post').to(:controller => "data_item", :action => "create").name("create_data_bag_item")
  match("/data/:data_bag_id/:id", :method => 'put').to(:controller => "data_item", :action => "update").name("update_data_bag_item")
  match("/data/:data_bag_id/:id", :method => 'delete').to(:controller => "data_item", :action => "destroy").name("destroy_data_bag_item")
  resources :data, :controller => "data_bags"

  match('/').to(:controller => 'main', :action =>'index').name(:top)

end
