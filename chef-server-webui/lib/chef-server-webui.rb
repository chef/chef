if defined?(Merb::Plugins)
  $:.unshift File.dirname(__FILE__)
  $:.unshift File.join(File.dirname(__FILE__), "..", "..", "chef", "lib")
  $:.unshift File.join(File.dirname(__FILE__), "..", "..", "chef-solr", "lib")

  dependency 'merb-slices', :immediate => true
  dependency 'chef', :immediate=>true unless defined?(Chef)
  require 'chef/role'
  require 'chef/webui_user'

  require 'coderay'

  Merb::Plugins.add_rakefiles "chef-server-webui/merbtasks", "chef-server-webui/slicetasks", "chef-server-webui/spectasks"

  
  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)

  Merb.disable :json
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can switch to
  # the main application layout or no layout at all if needed.
  #
  # Configuration options:
  # :layout - the layout to use; defaults to :chefserverslice
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:chef_server_webui][:layout] ||= :chef_server_webui
  

  # All Slice code is expected to be namespaced inside a module
  module ChefServerWebui
    # Slice metadata
    self.description = "ChefServerWebui.. serving up some piping hot infrastructure!"
    self.version = Chef::VERSION
    self.author = "Opscode"

    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
      Chef::Config[:node_name] = Chef::Config[:web_ui_client_name]
      Chef::Config[:client_key] = Chef::Config[:web_ui_key]
      # Create the default admin user "admin" if no admin user exists  
      unless Chef::WebUIUser.admin_exist
        user = Chef::WebUIUser.new
        user.name = Chef::Config[:web_ui_admin_user_name]
        user.set_password(Chef::Config[:web_ui_admin_default_password])
        user.admin = true
        user.save
      end
    end

    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end

    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end

    # Deactivation hook - triggered by Merb::Slices.deactivate(Chefserver)
    def self.deactivate
    end

    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :chefserverslice_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
          
      scope.resources :nodes, :id => /[^\/]+/
      scope.resources :clients, :id => /[^\/]+/
      scope.resources :roles  
      
      scope.match("/status").to(:controller => "status", :action => "index").name(:status)

      scope.resources :searches, :path => "search", :controller => "search"
      scope.match("/search/:search_id/entries", :method => 'get').to(:controller => "search_entries", :action => "index")
      scope.match("/search/:search_id/entries", :method => 'post').to(:controller => "search_entries", :action => "create")
      scope.match("/search/:search_id/entries/:id", :method => 'get').to(:controller => "search_entries", :action => "show")
      scope.match("/search/:search_id/entries/:id", :method => 'put').to(:controller => "search_entries", :action => "create")
      scope.match("/search/:search_id/entries/:id", :method => 'post').to(:controller => "search_entries", :action => "update")
      scope.match("/search/:search_id/entries/:id", :method => 'delete').to(:controller => "search_entries", :action => "destroy")

      scope.match("/cookbooks/_attribute_files").to(:controller => "cookbooks", :action => "attribute_files")
      scope.match("/cookbooks/_recipe_files").to(:controller => "cookbooks", :action => "recipe_files")
      scope.match("/cookbooks/_definition_files").to(:controller => "cookbooks", :action => "definition_files")
      scope.match("/cookbooks/_library_files").to(:controller => "cookbooks", :action => "library_files")

      scope.match("/cookbooks/:cookbook_id/templates", :cookbook_id => /[\w\.]+/).to(:controller => "cookbook_templates", :action => "index")
      scope.match("/cookbooks/:cookbook_id/libraries", :cookbook_id => /[\w\.]+/).to(:controller => "cookbook_libraries", :action => "index")
      scope.match("/cookbooks/:cookbook_id/definitions", :cookbook_id => /[\w\.]+/).to(:controller => "cookbook_definitions", :action => "index")
      scope.match("/cookbooks/:cookbook_id/recipes", :cookbook_id => /[\w\.]+/).to(:controller => "cookbook_recipes", :action => "index")
      scope.match("/cookbooks/:cookbook_id/attributes", :cookbook_id => /[\w\.]+/).to(:controller => "cookbook_attributes", :action => "index")
      scope.match("/cookbooks/:cookbook_id/files", :cookbook_id => /[\w\.]+/).to(:controller => "cookbook_files", :action => "index")

      scope.resources :cookbooks
      scope.resources :clients
    
      scope.match("/databags/:databag_id/databag_items", :method => 'get').to(:controller => "databags", :action => "show", :id=>":databag_id")
    
      scope.resources :databags do |s|
        s.resources :databag_items
      end 

      scope.match('/openid/consumer').to(:controller => 'openid_consumer', :action => 'index').name(:openid_consumer)
      scope.match('/openid/consumer/start').to(:controller => 'openid_consumer', :action => 'start').name(:openid_consumer_start)
      scope.match('/openid/consumer/login').to(:controller => 'openid_consumer', :action => 'login').name(:openid_consumer_login)
      scope.match('/openid/consumer/complete').to(:controller => 'openid_consumer', :action => 'complete').name(:openid_consumer_complete)
      scope.match('/openid/consumer/logout').to(:controller => 'openid_consumer', :action => 'logout').name(:openid_consumer_logout)
      
      scope.match('/login').to(:controller=>'users', :action=>'login').name(:users_login)
      scope.match('/logout').to(:controller => 'users', :action => 'logout').name(:users_logout)

      scope.match('/users').to(:controller => 'users', :action => 'index').name(:users)
      scope.match('/users/create').to(:controller => 'users', :action => 'create').name(:users_create)
      scope.match('/users/start').to(:controller => 'users', :action => 'start').name(:users_start)
      
      scope.match('/users/login').to(:controller => 'users', :action => 'login').name(:users_login)
      scope.match('/users/login_exec').to(:controller => 'users', :action => 'login_exec').name(:users_login_exec)
      scope.match('/users/complete').to(:controller => 'users', :action => 'complete').name(:users_complete)
      scope.match('/users/logout').to(:controller => 'users', :action => 'logout').name(:users_logout)
      scope.match('/users/new').to(:controller => 'users', :action => 'new').name(:users_new)
      scope.match('/users/:user_id/edit').to(:controller => 'users', :action => 'edit').name(:users_edit)
      scope.match('/users/:user_id').to(:controller => 'users', :action => 'show').name(:users_show)
      scope.match('/users/:user_id/delete', :method => 'delete').to(:controller => 'users', :action => 'destroy').name(:users_delete)
      scope.match('/users/:user_id/update', :method => 'put').to(:controller => 'users', :action => 'update').name(:users_update)      
      
      scope.match('/').to(:controller => 'nodes', :action =>'index').name(:top)

      # enable slice-level default routes by default
      # scope.default_routes
    end
      
  end

  # Setup the slice layout for ChefServerWebui
  #
  # Use ChefServerWebui.push_path and ChefServerWebui.push_app_path
  # to set paths to chefserver-level and app-level paths. Example:
  #
  # ChefServerWebui.push_path(:application, ChefServerWebui.root)
  # ChefServerWebui.push_app_path(:application, Merb.root / 'slices' / 'chefserverslice')
  # ...
  #
  # Any component path that hasn't been set will default to ChefServerWebui.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  ChefServerWebui.setup_default_structure!
end
