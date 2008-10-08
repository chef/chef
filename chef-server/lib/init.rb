#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

Merb.root = File.join(File.dirname(__FILE__))

#
# ==== Structure of Merb initializer
#
# 1. Load paths.
# 2. Dependencies configuration.
# 3. Libraries (ORM, testing tool, etc) you use.
# 4. Application-specific configuration.

#
# ==== Set up load paths
#

# Make the app's "gems" directory a place where gems are loaded from.
# Note that gems directory must have a structure RubyGems uses for
# directories under which gems are kept.
#
# To conveniently set it up use gem install -i <merb_app_root/gems>
# when installing gems. This will set up the structure under /gems
# automagically.
#
# An example:
#
# You want to bundle ActiveRecord and ActiveSupport with your Merb
# application to be deployment environment independent. To do so,
# install gems into merb_app_root/gems directory like this:
#
# gem install -i ~/dev/merbapp/gems activesupport-post-2.0.2gem activerecord-post-2.0.2.gem
#
# Since RubyGems will search merb_app_root/gems for dependencies, order
# in statement above is important: we need to install ActiveSupport which
# ActiveRecord depends on first.
#
# Remember that bundling of dependencies as gems with your application
# makes it independent of the environment it runs in and is a very
# good, encouraged practice to follow.
Gem.clear_paths
Gem.path.unshift(Merb.root / "gems")

# If you want modules and classes from libraries organized like
# merbapp/lib/magicwand/lib/magicwand.rb to autoload,
# uncomment this.


# Merb.push_path(:lib, Merb.root / "lib") # uses **/*.rb as path glob.


# disable the ActiveSupport json annoying stuff, as it breaks our to_json
Merb.disable :json

# ==== Dependencies

# These are some examples of how you might specify dependencies.
# Dependencies load is delayed to one of later Merb app
# boot stages. It may be important when
# later part of your configuration relies on libraries specified
# here.
#
# dependencies "RedCloth", "merb_helpers"
# OR
# dependency "RedCloth", "> 3.0"
# OR
# dependencies "RedCloth" => "> 3.0", "ruby-aes-cext" => "= 1.0"
Merb::BootLoader.after_app_loads do
  Chef::Queue.connect

  # create the couch design docs for nodes and openid registrations
  Chef::Node.create_design_document
  Chef::OpenIDRegistration.create_design_document

  # dependency "magic_admin" # this gem uses the app's model classes
end

#
# ==== Set up your ORM of choice
#

# Merb doesn't come with database support by default.  You need
# an ORM plugin.  Install one, and uncomment one of the following lines,
# if you need a database.

# Uncomment for DataMapper ORM
# use_orm :datamapper

# Uncomment for ActiveRecord ORM
# use_orm :activerecord

# Uncomment for Sequel ORM
# use_orm :sequel

Merb.push_path(:lib, File.join(File.dirname(__FILE__), "..", "chef"))
Merb.push_path(:controller, File.join(File.dirname(__FILE__), "controllers"))
Merb.push_path(:model, File.join(File.dirname(__FILE__), "models"))
Merb.push_path(:view, File.join(File.dirname(__FILE__), "views"))
Merb.push_path(:helper, File.join(File.dirname(__FILE__), "helpers"))
Merb.push_path(:public, File.join(File.dirname(__FILE__), "public"))

require 'merb-haml'
#require 'uv'


#
# ==== Pick what you test with
#

# This defines which test framework the generators will use
# rspec is turned on by default
#
# Note that you need to install the merb_rspec if you want to ue
# rspec and merb_test_unit if you want to use test_unit.
# merb_rspec is installed by default if you did gem install
# merb.
#
# use_test :test_unit
use_test :rspec


#
# ==== Set up your basic configuration
#
Merb::Config.use do |c|
  # Sets up a custom session id key, if you want to piggyback sessions of other applications
  # with the cookie session store. If not specified, defaults to '_session_id'.
  c[:session_id_key] = '_chef_server_session_id'
  c[:session_secret_key]  = '0992ea491c30ec76c98367c1ca53b18c1e7c5b30'
  c[:session_store] = 'cookie'
  c[:exception_details] = true
  c[:reload_classes] = true
  c[:log_level] = :debug
  c[:log_file] = "/var/log/chef-server.log"
end

Merb.logger.info("Compiling routes...")
Merb::Router.prepare do |r|
  # RESTful routes
  # r.resources :posts

  # This is the default route for /:controller/:action/:id
  # This is fine for most cases.  If you're heavily using resource-based
  # routes, you may want to comment/remove this line to prevent
  # clients from calling your create or destroy actions with a GET
  
  resources :nodes
  resources :searches, :path => "search", :controller => "search" do
    resources :entries, :controller => "search_entries"
  end 
  
  match("/cookbooks/_attribute_files").to(:controller => "cookbooks", :action => "attribute_files")
  match("/cookbooks/_recipe_files").to(:controller => "cookbooks", :action => "recipe_files")
  match("/cookbooks/_definition_files").to(:controller => "cookbooks", :action => "definition_files")
  
#  r.match("/cookbooks/:cookbook_id/templates").to(:controller => "cookbook_templates", :action => "index")
 
  resources :cookbooks do
    resources :templates, :controller => "cookbook_templates"
    resources :files, :controller => "cookbook_files"
    resources :recipes, :controller => "cookbook_recipes"
    resources :attributes, :controller => "cookbook_attributes"
    resources :definitions, :controller => "cookbook_definitions"
  end
    
  #r.resources :openid do |res|
  #  res.resources :register, :controller => "openid_register"
  #  res.resources :server, :controller => "openid_server"
  #end
  
  resources :registrations, :controller => "openid_register" 
  resources :registrations, :controller => "openid_register", :member => { :validate => :post }
  match("/openid/server").to(:controller => "openid_server", :action => "index").name(:openid_server)
  match("/openid/server/server/xrds").
    to(:controller => "openid_server", :action => 'idp_xrds').name(:openid_server_xrds)
  match("/openid/server/node/:id").
    to(:controller => "openid_server", :action => 'node_page').name(:openid_node)
  match('/openid/server/node/:id/xrds').
    to(:controller => 'openid_server', :action => 'node_xrds').name(:openid_node_xrds)
  match('/openid/server/decision').to(:controller => "openid_server", :action => "decision").name(:openid_server_decision)
  match('/openid/consumer').to(:controller => 'openid_consumer', :action => 'index').name(:openid_consumer)
  match('/openid/consumer/start').to(:controller => 'openid_consumer', :action => 'start').name(:openid_consumer_start)
  match('/openid/consumer/complete').to(:controller => 'openid_consumer', :action => 'complete').name(:openid_consumer_complete)
  match('/openid/consumer/logout').to(:controller => 'openid_consumer', :action => 'logout').name(:openid_consumer_logout)
  
  #r.default_routes
  
  # Change this for your home page to be available at /
  match('/').to(:controller => 'nodes', :action =>'index').name(:top)
end

