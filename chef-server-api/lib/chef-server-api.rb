if defined?(Merb::Plugins)
  $:.unshift File.dirname(__FILE__)
  $:.unshift File.join(File.dirname(__FILE__), "..", "..", "chef-solr", "lib")
  $:.unshift File.join(File.dirname(__FILE__), "..", "..", "chef", "lib")

  dependency 'merb-slices', :immediate => true
  dependency 'chef', :immediate=>true unless defined?(Chef)
  dependency 'bunny', :immediate=>true 
  dependency 'uuidtools', :immediate=>true 

  require 'chef/role'
  require 'chef/data_bag'
  require 'chef/data_bag_item'
  require 'chef/api_client'
  require 'chef/webui_user'
  require 'chef/certificate'

  require 'mixlib/authentication'

  require 'chef/data_bag'
  require 'chef/data_bag_item'
  require 'ohai'
  require 'openssl'

  Merb::Plugins.add_rakefiles "chef-server-api/merbtasks", "chef-server-api/slicetasks", "chef-server-api/spectasks"

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
  Merb::Slices::config[:chef_server_api][:layout] ||= :chef_server_api
  
  # All Slice code is expected to be namespaced inside a module
  module ChefServerApi
    # Slice metadata
    self.description = "ChefServerApi.. serving up some piping hot infrastructure!"
    self.version = Chef::VERSION
    self.author = "Opscode"

    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
      Chef::Log.info("Compiling routes... (totally normal to see 'Cannot find resource model')")
    end

    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end

    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
      Mixlib::Authentication::Log.logger = Ohai::Log.logger = Chef::Log.logger 

      unless Merb::Config.environment == "test"
        # create the couch design docs for nodes, roles, and databags
        Chef::CouchDB.new.create_id_map
        Chef::Node.create_design_document
        Chef::Role.create_design_document
        Chef::DataBag.create_design_document
        Chef::ApiClient.create_design_document
        Chef::WebUIUser.create_design_document
        
        # Create the signing key and certificate 
        Chef::Certificate.generate_signing_ca

        # Generate the validation key
        Chef::Certificate.gen_validation_key

        # Generate the Web UI Key 
        Chef::Certificate.gen_validation_key(Chef::Config[:web_ui_client_name], Chef::Config[:web_ui_key], true)
        
        Chef::Log.info('Loading roles')
        Chef::Role.sync_from_disk_to_couchdb
      end
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
      # Users
      scope.resources :users
      
      # Nodes
      scope.resources :nodes, :id => /[^\/]+/
      scope.match('/nodes/:id/cookbooks',
                  :id => /[^\/]+/,
                  :method => 'get').
                  to(:controller => "nodes", :action => "cookbooks")
      # Roles
      scope.resources :roles

      # Status
      scope.match("/status").to(:controller => "status", :action => "index").name(:status)

      # Clients
      scope.match("/clients", :method=>"post").to(:controller=>'clients', :action=>'create')
      scope.match("/clients", :method=>"get").to(:controller=>'clients', :action=>'index').name(:clients)
      scope.match("/clients/:id", :id => /[\w\.-]+/, :method=>"get").to(:controller=>'clients', :action=>'show').name(:client)
      scope.match("/clients/:id", :id => /[\w\.-]+/, :method=>"put").to(:controller=>'clients', :action=>'update')
      scope.match("/clients/:id", :id => /[\w\.-]+/, :method=>"delete").to(:controller=>'clients', :action=>'destroy')

      # Search
      scope.resources :search
      scope.match('/search/reindex', :method => 'post').to(:controller => "search", :action => "reindex")

      # Cookbooks        
      scope.match('/nodes/:id/cookbooks', :method => 'get').to(:controller => "nodes", :action => "cookbooks")

      scope.resources :cookbooks
      scope.match("/cookbooks/:cookbook_id/_content", :method => 'get', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "get_tarball")
      scope.match("/cookbooks/:cookbook_id/_content", :method => 'put', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "update")
      scope.match("/cookbooks/:cookbook_id/:segment", :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "show_segment").name(:cookbook_segment)

      # Data
      scope.match("/data/:data_bag_id/:id", :method => 'get').to(:controller => "data_item", :action => "show").name("data_bag_item")
      scope.match("/data/:data_bag_id", :method => 'post').to(:controller => "data_item", :action => "create").name("create_data_bag_item")
      scope.match("/data/:data_bag_id/:id", :method => 'put').to(:controller => "data_item", :action => "update").name("update_data_bag_item")
      scope.match("/data/:data_bag_id/:id", :method => 'delete').to(:controller => "data_item", :action => "destroy").name("destroy_data_bag_item")
      scope.resources :data

      scope.match('/').to(:controller => 'main', :action =>'index').name(:top)
    end
  end
  

  # Setup the slice layout for ChefServerApi
  #
  # Use ChefServerApi.push_path and ChefServerApi.push_app_path
  # to set paths to chefserver-level and app-level paths. Example:
  #
  # ChefServerApi.push_path(:application, ChefServerApi.root)
  # ChefServerApi.push_app_path(:application, Merb.root / 'slices' / 'chefserverslice')
  # ...
  #
  # Any component path that hasn't been set will default to ChefServerApi.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  ChefServerApi.setup_default_structure!
end
