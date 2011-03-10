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
require 'chef/json_compat'

class Application < Merb::Controller

  include Chef::Mixin::Checksum

  def authenticate_every
    begin
      # Raises an error if required auth headers are missing
      authenticator = Mixlib::Authentication::SignatureVerification.new(request)

      username = authenticator.user_id
      Chef::Log.info("Authenticating client #{username}")

      user = Chef::ApiClient.cdb_load(username)
      user_key = OpenSSL::PKey::RSA.new(user.public_key)
      Chef::Log.debug "Authenticating Client:\n #{user.inspect}\n"

      # Store this for later..
      @auth_user = user
      authenticator.authenticate_request(user_key)
    rescue Mixlib::Authentication::MissingAuthenticationHeader => e
      Chef::Log.debug "Authentication failed: #{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}"
      raise BadRequest, "#{e.class.name}: #{e.message}"
    rescue StandardError => se
      Chef::Log.debug "Authentication failed: #{se}, #{se.backtrace.join("\n")}"
      raise Unauthorized, "Failed to authenticate. Ensure that your client key is valid."
    end

    unless authenticator.valid_request?
      if authenticator.valid_timestamp?
        raise Unauthorized, "Failed to authenticate. Ensure that your client key is valid."
      else
        raise Unauthorized, "Failed to authenticate. Please synchronize the clock on your client"
      end
    end
    true
  end

  def is_admin
    if @auth_user.admin
      true
    else
      raise Forbidden, "You are not allowed to take this action."
    end
  end

  def is_admin_or_validator
    if @auth_user.admin || @auth_user.name == Chef::Config[:validation_client_name]
      true
    else
      raise Forbidden, "You are not allowed to take this action."
    end
  end

  def admin_or_requesting_node
    if @auth_user.admin || @auth_user.name == params[:id]
      true
    else
      raise Forbidden, "You are not the correct node (auth_user name: #{@auth_user.name}, params[:id]: #{params[:id]}), or are not an API administrator (admin: #{@auth_user.admin})."
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

  # Fix CHEF-1292/PL-538; cause Merb to pass the max nesting constant into
  # obj.to_json, which it calls by default based on the original request's 
  # accept headers and the type passed into Merb::Controller.display
  #--
  # TODO: tim, 2010-11-24: would be nice to instead have Merb call 
  # Chef::JSONCompat.to_json, instead of obj.to_json, but changing that
  # behavior is convoluted in Merb. This override is assuming that
  # Merb is eventually calling obj.to_json, which takes the :max_nesting
  # option.
  override! :display
  def display(obj)
    super(obj, nil, {:max_nesting => Chef::JSONCompat::JSON_MAX_NESTING})
  end

end

