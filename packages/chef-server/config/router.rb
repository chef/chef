# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   r.match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   r.match("/books/:book_id/:action").
#     to(:controller => "books")
#   
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   r.match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.

Merb.logger.info("Compiling routes...")
Merb::Router.prepare do |r|
  # RESTful routes
  # r.resources :posts

  # This is the default route for /:controller/:action/:id
  # This is fine for most cases.  If you're heavily using resource-based
  # routes, you may want to comment/remove this line to prevent
  # clients from calling your create or destroy actions with a GET
  
  r.resources :nodes
  r.resources :nodes, :member => { :compile => :get }
  
  #r.resources :openid do |res|
  #  res.resources :register, :controller => "openid_register"
  #  res.resources :server, :controller => "openid_server"
  #end
  
  r.resources :registrations, :controller => "openid_register" 
  r.resources :registrations, :controller => "openid_register", :member => { :validate => :post }
  r.match("/openid/server").to(:controller => "openid_server", :action => "index").name(:openid_server)
  r.match("/openid/server/server/xrds").
    to(:controller => "openid_server", :action => 'idp_xrds').name(:openid_server_xrds)
  r.match("/openid/server/node/:id").
    to(:controller => "openid_server", :action => 'node_page').name(:openid_node)
  r.match('/openid/server/node/:id/xrds').
    to(:controller => 'openid_server', :action => 'node_xrds').name(:openid_node_xrds)
  r.match('/openid/server/decision').to(:controller => "openid_server", :action => "decision").name(:openid_server_decision)
  r.match('/openid/consumer').to(:controller => 'openid_consumer', :action => 'index').name(:openid_consumer)
  r.match('/openid/consumer/start').to(:controller => 'openid_consumer', :action => 'start').name(:openid_consumer_start)
  r.match('/openid/consumer/complete').to(:controller => 'openid_consumer', :action => 'complete').name(:openid_consumer_complete)
  r.match('/openid/consumer/logout').to(:controller => 'openid_consumer', :action => 'logout').name(:openid_consumer_logout)
  
  #r.default_routes
  
  # Change this for your home page to be available at /
  r.match('/').to(:controller => 'nodes', :action =>'index').name(:top)
end

