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

  r.match("/openid_server").to(:controller => "openid_server", :action => "index")
  r.match("/openid_server/server/xrds").
    to(:controller => "openid_server", :action => 'idp_xrds')
  r.match("/openid_server/user/:username").
    to(:controller => "openid_server", :action => 'user_page')
  r.match('/openid_server/user/:username/xrds').
    to(:controller => 'openid_server', :action => 'user_xrds')
  r.match('/openid_login').to(:controller => 'openid_login', :action => 'index')
  r.match('/openid_login/submit').to(:controller => 'openid_login', :action => 'submit')
  r.match('/openid_login/logout').to(:controller => 'openid_login', :action => 'logout')
  
  #r.default_routes
  
  # Change this for your home page to be available at /
  # r.match('/').to(:controller => 'whatever', :action =>'index')
end