#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
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

require "chef/mixin/checksum"
require "chef/cookbook_loader"
require "mixlib/authentication/signatureverification"

class Application < Merb::Controller

  include Chef::Mixin::Checksum

  def authenticate_every
    authenticator = Mixlib::Authentication::SignatureVerification.new

    auth = begin
             headers = request.env.inject({ }) { |memo, kv| memo[$2.downcase.gsub(/\-/,"_").to_sym] = kv[1] if kv[0] =~ /^(HTTP_)(.*)/; memo }
             Chef::Log.debug("Headers in authenticate_every: #{headers.inspect}")
             username = headers[:x_ops_userid].chomp
             Chef::Log.info("Authenticating client #{username}")
             user = Chef::ApiClient.cdb_load(username)
             Chef::Log.debug("Found API Client: #{user.inspect}")
             user_key = OpenSSL::PKey::RSA.new(user.public_key)
             Chef::Log.debug "Authenticating:\n #{user.inspect}\n"
             # Store this for later..
             @auth_user = user
             authenticator.authenticate_user_request(request, user_key)
           rescue StandardError => se
             Chef::Log.debug "Authentication failed: #{se}, #{se.backtrace.join("\n")}"
             nil
           end

    raise Unauthorized, "Failed to authenticate!" unless auth

    auth
  end

  def is_admin
    if @auth_user.admin
      true
    else
      raise Unauthorized, "You are not allowed to take this action."
    end
  end

  def is_admin_or_validator
    if @auth_user.admin || @auth_user.name == Chef::Config[:validation_client_name]
      true
    else
      raise Unauthorized, "You are not allowed to take this action."
    end
  end

  def admin_or_requesting_node
    if @auth_user.admin || @auth_user.name == params[:id]
      true
    else
      raise Unauthorized, "You are not the correct node (auth_user name: #{@auth_user.name}, params[:id]: #{params[:id]}), or are not an API administrator (admin: #{@auth_user.admin})."
    end
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.uri
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    loc = session[:return_to] || default
    session[:return_to] = nil
    redirect loc
  end

  def access_denied
    raise Unauthorized, "You must authenticate first!"
  end
  
  # returns name -> CookbookVersion for all cookbooks included on the given node.
  def cookbooks_for_node(node_name, all_cookbooks)
    # get node's explicit dependencies
    node = Chef::Node.cdb_load(node_name)
    run_list_items, default_attrs, override_attrs = node.run_list.expand('couchdb')
    
    # walk run list and accumulate included dependencies
    run_list_items.inject({}) do |included_cookbooks, run_list_item|
      expand_cookbook_deps(included_cookbooks, all_cookbooks, run_list_item)
      included_cookbooks
    end
  end

  # Accumulates transitive cookbook dependencies no more than once in included_cookbooks
  #   included_cookbooks == hash of name -> CookbookVersion, which is used for returning 
  #                         result as well as for tracking which cookbooks we've already 
  #                         recursed into
  #   all_cookbooks    == hash of name -> CookbookVersion, all cookbooks available
  #   run_list_items   == name of cookbook to include
  def expand_cookbook_deps(included_cookbooks, all_cookbooks, run_list_item)
    # determine the run list item's parent cookbook, which might be run_list_item in the default case
    cookbook_name = (run_list_item[/^(.+)::/, 1] || run_list_item.to_s)
    Chef::Log.debug("Node requires #{cookbook_name}")

    # include its dependencies
    included_cookbooks[cookbook_name] = all_cookbooks[cookbook_name]
    if !all_cookbooks[cookbook_name]
      Chef::Log.warn "#{__FILE__}:#{__LINE__}: in expand_cookbook_deps, cookbook/role #{cookbook_name} could not be found, ignoring it in cookbook expansion"
      return included_cookbooks
    end
    
    # TODO: 5/27/2010 cw: implement dep_version_constraints according to
    # http://wiki.opscode.com/display/chef/Metadata#Metadata-depends,
    all_cookbooks[cookbook_name].metadata.dependencies.each do |depname, dep_version_constraints|
      # recursively expand dependencies into included_cookbooks unless
      # we've already done it
      expand_cookbook_deps(included_cookbooks, all_cookbooks, depname) unless included_cookbooks[depname]
    end
  end
  
  def load_all_files(node_name)
    all_cookbooks = Chef::CookbookVersion.cdb_list(true).inject({}) {|hsh,record| hsh[record.name] = record ; hsh}
    
    included_cookbooks = cookbooks_for_node(node_name, all_cookbooks)
    nodes_cookbooks = Hash.new
    included_cookbooks.each do |cookbook_name, cookbook|
      next unless cookbook

      nodes_cookbooks[cookbook_name.to_s] = cookbook.generate_manifest_with_urls{|opts| absolute_url(:cookbook_file, opts) }
    end

    nodes_cookbooks
  end

  def get_available_recipes
    all_cookbooks_list = Chef::CookbookVersion.cdb_list(true)
    available_recipes = all_cookbooks_list.sort{ |a,b| a.name.to_s <=> b.name.to_s }.inject([]) do |result, element|
      element.recipes.sort.each do |r| 
        if r =~ /^(.+)::default$/
          result << $1
        else
          result << r
        end
      end
      result
    end
    available_recipes
  end

end

