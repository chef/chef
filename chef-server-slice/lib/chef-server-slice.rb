if defined?(Merb::Plugins)
  $:.unshift File.dirname(__FILE__)
  
  dependency 'merb-slices', :immediate => true
  dependency 'chef', :immediate=>true
  
  require 'syntax/convertors/html'
  
  Merb::Plugins.add_rakefiles "chef-server-slice/merbtasks", "chef-server-slice/slicetasks", "chef-server-slice/spectasks"

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
  Merb::Slices::config[:chef_server_slice][:layout] ||= :chef_server_slice
  
  # All Slice code is expected to be namespaced inside a module
  module ChefServerSlice
    # Slice metadata
    self.description = "ChefServerSlice.. serving up some piping hot infrastructure!"
    self.version = Chef::VERSION
    self.author = "Opscode"
        
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
      Chef::Queue.connect
      
      # create the couch design docs for nodes and openid registrations
      Chef::Node.create_design_document
      Chef::OpenIDRegistration.create_design_document

      Chef::Log.logger = Merb.logger
      Chef::Log.info("Compiling routes... (totally normal to see 'Cannot find resource model')")      
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
      
      scope.resources :nodes

      scope.resources :searches, :path => "search", :controller => "search" do
        scope.resources :entries, :controller => "search_entries"
      end 
      
      scope.match("/cookbooks/_attribute_files").to(:controller => "cookbooks", :action => "attribute_files")
      scope.match("/cookbooks/_recipe_files").to(:controller => "cookbooks", :action => "recipe_files")
      scope.match("/cookbooks/_definition_files").to(:controller => "cookbooks", :action => "definition_files")
      scope.match("/cookbooks/_library_files").to(:controller => "cookbooks", :action => "library_files")
      
      scope.match("/cookbooks/:cookbook_id/templates").to(:controller => "cookbook_templates", :action => "index")
      scope.match("/cookbooks/:cookbook_id/libraries").to(:controller => "cookbook_libraries", :action => "index")
      scope.match("/cookbooks/:cookbook_id/definitions").to(:controller => "cookbook_definitions", :action => "index")
      scope.match("/cookbooks/:cookbook_id/recipes").to(:controller => "cookbook_recipes", :action => "index")
      scope.match("/cookbooks/:cookbook_id/attributes").to(:controller => "cookbook_attributes", :action => "index")      
      
      scope.resources :cookbooks
      scope.resources :registrations, :controller => "openid_register" 
      scope.resources :registrations, :controller => "openid_register", :member => { :validate => :post }
      scope.resources :registrations, :controller => "openid_register", :member => { :admin => :post }
      
      scope.match("/openid/server").to(:controller => "openid_server", :action => "index").name(:openid_server)
      scope.match("/openid/server/server/xrds").
        to(:controller => "openid_server", :action => 'idp_xrds').name(:openid_server_xrds)
      scope.match("/openid/server/node/:id").
        to(:controller => "openid_server", :action => 'node_page').name(:openid_node)
      scope.match('/openid/server/node/:id/xrds').
        to(:controller => 'openid_server', :action => 'node_xrds').name(:openid_node_xrds)
      scope.match('/openid/server/decision').to(:controller => "openid_server", :action => "decision").name(:openid_server_decision)
      scope.match('/login').to(:controller=>'openid_consumer', :action=>'index').name(:openid_consumer)
      scope.match('/logout').to(:controller => 'openid_consumer', :action => 'logout').name(:openid_consumer_logout)
      scope.match('/openid/consumer').to(:controller => 'openid_consumer', :action => 'index').name(:openid_consumer)
      scope.match('/openid/consumer/start').to(:controller => 'openid_consumer', :action => 'start').name(:openid_consumer_start)
      scope.match('/openid/consumer/complete').to(:controller => 'openid_consumer', :action => 'complete').name(:openid_consumer_complete)
      scope.match('/openid/consumer/logout').to(:controller => 'openid_consumer', :action => 'logout').name(:openid_consumer_logout)

      scope.match('/').to(:controller => 'nodes', :action =>'index').name(:top)      
      # enable slice-level default routes by default
      # scope.default_routes
    end
    
  end
  
  # Setup the slice layout for ChefServerSlice
  #
  # Use ChefServerSlice.push_path and ChefServerSlice.push_app_path
  # to set paths to chefserver-level and app-level paths. Example:
  #
  # ChefServerSlice.push_path(:application, ChefServerSlice.root)
  # ChefServerSlice.push_app_path(:application, Merb.root / 'slices' / 'chefserverslice')
  # ...
  #
  # Any component path that hasn't been set will default to ChefServerSlice.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  ChefServerSlice.setup_default_structure!
end

