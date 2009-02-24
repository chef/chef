if defined?(Merb::Plugins)
  $:.unshift File.dirname(__FILE__)
  
  dependency 'merb-slices', :immediate => true
  dependency 'chef', :immediate=>true
  
  require 'syntax/convertors/html'
  
  Merb::Plugins.add_rakefiles "chefserverslice/merbtasks", "chefserverslice/slicetasks", "chefserverslice/spectasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)

  Merb.disable :json
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :chefserverslice
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:chefserverslice][:layout] ||= :chefserverslice
  
  # All Slice code is expected to be namespaced inside a module
  module Chefserverslice
    # Slice metadata
    self.description = "Chefserverslice.. serving up some piping hot infrastructure!"
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
      
      #  r.scope.match("/cookbooks/:cookbook_id/templates").to(:controller => "cookbook_templates", :action => "index")
      
      scope.resources :cookbooks do
        scope.resources :templates, :controller => "cookbook_templates"
        scope.resources :files, :controller => "cookbook_files"
        scope.resources :recipes, :controller => "cookbook_recipes"
        scope.resources :attributes, :controller => "cookbook_attributes"
        scope.resources :definitions, :controller => "cookbook_definitions"
        scope.resources :libraries, :controller => "cookbook_libraries"
      end
      
      #r.scope.resources :openid do |res|
      #  res.scope.resources :register, :controller => "openid_register"
      #  res.scope.resources :server, :controller => "openid_server"
      #end
      
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

      # the slice is mounted at /chefserverslice - note that it comes before default_routes
      scope.match('/').to(:controller => 'nodes', :action =>'index').name(:top)      
      # enable slice-level default routes by default
      # [cb] disable default routing in favor of explicit (see scope.resources above)
      #scope.default_routes
    end
    
  end
  
  # Setup the slice layout for Chefserverslice
  #
  # Use Chefserverslice.push_path and Chefserverslice.push_app_path
  # to set paths to chefserver-level and app-level paths. Example:
  #
  # Chefserverslice.push_path(:application, Chefserverslice.root)
  # Chefserverslice.push_app_path(:application, Merb.root / 'slices' / 'chefserverslice')
  # ...
  #
  # Any component path that hasn't been set will default to Chefserverslice.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  Chefserverslice.setup_default_structure!
  
  # freaky path fix for javascript and stylesheets
  unless Chefserverslice.standalone?
    Chefserverslice.public_components.each do |component|
      Chefserverslice.push_app_path(component, Merb.dir_for(:public) / "#{component}s", nil)    
    end
  end
end

