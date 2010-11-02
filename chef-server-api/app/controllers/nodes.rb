#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/cookbook/metadata/version'
require 'chef' / 'node'
require 'chef/version_class'

class Nodes < Application

  provides :json

  before :authenticate_every
  before :admin_or_requesting_node, :only => [ :update, :destroy, :cookbooks ]

  def index
    @node_list = Chef::Node.cdb_list
    display(@node_list.inject({}) do |r,n|
      r[n] = absolute_url(:node, n); r
    end)
  end

  def show
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    @node.couchdb_rev = nil
    display @node
  end

  def create
    @node = params["inflated_object"]
    begin
      Chef::Node.cdb_load(@node.name)
      raise Conflict, "Node already exists"
    rescue Chef::Exceptions::CouchDBNotFound
    end
    self.status = 201
    @node.cdb_save
    display({ :uri => absolute_url(:node, @node.name) })
  end

  def update
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end

    @node.update_from!(params['inflated_object'])
    @node.cdb_save
    @node.couchdb_rev = nil
    display(@node)
  end

  def destroy
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    @node.cdb_destroy
    @node.couchdb_rev = nil
    display @node
  end

  def cookbooks
    begin
      @node = Chef::Node.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end

    display(load_all_files)
  end

  private

  def load_all_files
    all_cookbooks = Chef::Environment.cdb_load_filtered_cookbook_versions(@node.chef_environment)

    included_cookbooks = cookbooks_for_node(all_cookbooks)
    nodes_cookbooks = Hash.new
    included_cookbooks.each do |cookbook_name, cookbook|
      nodes_cookbooks[cookbook_name.to_s] = cookbook.generate_manifest_with_urls{|opts| absolute_url(:cookbook_file, opts) }
    end

    nodes_cookbooks
  end

  # returns name -> CookbookVersion for all cookbooks included on the given node.
  def cookbooks_for_node(all_cookbooks)
    # expand returns a RunListExpansion which contains recipes, default and override attrs [cb]
    # TODO: check for this on the client side before we make the http request [stephen 9/1/10]
    begin
      recipes = @node.run_list.expand('couchdb').recipes.with_versions
    rescue Chef::Exceptions::RecipeVersionConflict => e
      raise PreconditionFailed, "#Conflict: #{e.message}"
    end

    # TODO: make cookbook loading respect environment's versions [stephen 8/25/10]
    # walk run list and accumulate included dependencies
    recipes.inject({}) do |included_cookbooks, recipe|
      expand_cookbook_deps(included_cookbooks, all_cookbooks, recipe, "Run list")
      included_cookbooks
    end
  end

  # Accumulates transitive cookbook dependencies no more than once in included_cookbooks
  #   included_cookbooks == hash of name -> CookbookVersion, which is used for returning
  #                         result as well as for tracking which cookbooks we've already
  #                         recursed into
  #   all_cookbooks      == hash of name -> [ CookbookVersion ... ] , all cookbooks available, sorted by version number
  #   recipe             == hash of :name => recipe_name, :version => recipe_version to include
  #   parent_name        == the name of the parent cookbook (or run_list), for reporting broken dependencies
  def expand_cookbook_deps(included_cookbooks, all_cookbooks, recipe, parent_name)
    # determine the recipe's parent cookbook, which might be the
    # recipe name in the default case
    cookbook_name = (recipe[:name][/^(.+)::/, 1] || recipe[:name])
    if recipe[:version]
      version = Chef::Version.new(recipe[:version])
      Chef::Log.debug "Node requires #{cookbook_name} at version #{version.to_s}"
      # detect the correct cookbook version from the list of available cookbook versions
      cookbook = all_cookbooks[cookbook_name].detect { |cb| Chef::Version.new(cb.version) == version }
    else
      Chef::Log.debug "Node requires #{cookbook_name} at latest version"
      cookbook_versions = all_cookbooks[cookbook_name]
      cookbook = cookbook_versions ? all_cookbooks[cookbook_name].last : nil
    end
    unless cookbook
      msg = "#{parent_name} depends on cookbook #{cookbook_name} #{version.to_s}, which is not available to this node"
      raise PreconditionFailed, msg
    end

    # we can't load more than one version of the same cookbook
    if included_cookbooks[cookbook_name]
      a = Chef::Version.new(included_cookbooks[cookbook_name].version)
      b = Chef::Version.new(cookbook.version)
      raise PreconditionFailed, "Conflict: Node requires cookbook #{cookbook_name} at versions #{a.to_s} and #{b.to_s}" if a != b
    else
      included_cookbooks[cookbook_name] = cookbook
    end

    # TODO:
    # In the past, we have ignored the version constraints from dependency metadata.
    # We will continue to do so for the time being, until the Gem::Version
    # sytax for the environments feature is replaced with something more permanent
    # [stephen 9/1/10]
    cookbook.metadata.dependencies.each do |dependency_name, dependency_version_constraints|
      Chef::Log.debug [included_cookbooks, all_cookbooks, dependency_name, "Cookbook #{cookbook_name}"].join(", ")
      recipe = {:name => dependency_name, :version => nil}
      expand_cookbook_deps(included_cookbooks, all_cookbooks, recipe, "Cookbook #{cookbook_name}")
    end
  end
end
