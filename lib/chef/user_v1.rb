#
# Author:: Steven Danna (steve@chef.io)
# Copyright:: Copyright (c) Chef Software Inc.
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
require_relative "config"
require_relative "mixin/params_validate"
require_relative "mixin/from_file"
require_relative "mash"
require_relative "json_compat"
require_relative "search/query"
require_relative "mixin/api_version_request_handling"
require_relative "exceptions"
require_relative "server_api"

# OSC 11 BACKWARDS COMPATIBILITY NOTE (remove after OSC 11 support ends)
#
# In general, Chef::UserV1 is no longer expected to support Open Source Chef 11 Server requests.
# The object that handles those requests remain in the Chef::User namespace.
# This code will be moved to the Chef::User namespace as of Chef 13.
#
# Exception: self.list is backwards compatible with OSC 11
class Chef
  class UserV1

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::ApiVersionRequestHandling

    SUPPORTED_API_VERSIONS = [0, 1].freeze

    def initialize
      @username = nil
      @display_name = nil
      @first_name = nil
      @middle_name = nil
      @last_name = nil
      @email = nil
      @password = nil
      @public_key = nil
      @private_key = nil
      @create_key = nil
    end

    def chef_root_rest_v0
      @chef_root_rest_v0 ||= Chef::ServerAPI.new(Chef::Config[:chef_server_root], { api_version: "0" })
    end

    def chef_root_rest_v1
      @chef_root_rest_v1 ||= Chef::ServerAPI.new(Chef::Config[:chef_server_root], { api_version: "1" })
    end

    def username(arg = nil)
      set_or_return(:username, arg,
        regex: /^[a-z0-9\-_]+$/)
    end

    def display_name(arg = nil)
      set_or_return(:display_name,
        arg, kind_of: String)
    end

    def first_name(arg = nil)
      set_or_return(:first_name,
        arg, kind_of: String)
    end

    def middle_name(arg = nil)
      set_or_return(:middle_name,
        arg, kind_of: String)
    end

    def last_name(arg = nil)
      set_or_return(:last_name,
        arg, kind_of: String)
    end

    def email(arg = nil)
      set_or_return(:email,
        arg, kind_of: String)
    end

    def create_key(arg = nil)
      set_or_return(:create_key, arg,
        kind_of: [TrueClass, FalseClass])
    end

    def public_key(arg = nil)
      set_or_return(:public_key,
        arg, kind_of: String)
    end

    def private_key(arg = nil)
      set_or_return(:private_key,
        arg, kind_of: String)
    end

    def password(arg = nil)
      set_or_return(:password,
        arg, kind_of: String)
    end

    def to_h
      result = {
        "username" => @username,
      }
      result["display_name"] = @display_name unless @display_name.nil?
      result["first_name"] = @first_name unless @first_name.nil?
      result["middle_name"] = @middle_name unless @middle_name.nil?
      result["last_name"] = @last_name unless @last_name.nil?
      result["email"] = @email unless @email.nil?
      result["password"] = @password unless @password.nil?
      result["public_key"] = @public_key unless @public_key.nil?
      result["private_key"] = @private_key unless @private_key.nil?
      result["create_key"] = @create_key unless @create_key.nil?
      result
    end

    alias_method :to_hash, :to_h

    def to_json(*a)
      Chef::JSONCompat.to_json(to_h, *a)
    end

    def destroy
      # will default to the current API version (Chef::Authenticator::DEFAULT_SERVER_API_VERSION)
      Chef::ServerAPI.new(Chef::Config[:chef_server_url]).delete("users/#{@username}")
    end

    def create
      # try v1, fail back to v0 if v1 not supported
      begin
        payload = {
          username: @username,
          display_name: @display_name,
          email: @email,
        }
        payload[:first_name] = @first_name unless @first_name.nil?
        payload[:last_name] = @last_name unless @last_name.nil?
        payload[:password] = @password unless @password.nil?
        payload[:public_key] = @public_key unless @public_key.nil?
        payload[:create_key] = @create_key unless @create_key.nil?
        payload[:middle_name] = @middle_name unless @middle_name.nil?
        raise Chef::Exceptions::InvalidUserAttribute, "You cannot set both public_key and create_key for create." if !@create_key.nil? && !@public_key.nil?

        new_user = chef_root_rest_v1.post("users", payload)

        # get the private_key out of the chef_key hash if it exists
        if new_user["chef_key"]
          if new_user["chef_key"]["private_key"]
            new_user["private_key"] = new_user["chef_key"]["private_key"]
          end
          new_user["public_key"] = new_user["chef_key"]["public_key"]
          new_user.delete("chef_key")
        end
      rescue Net::HTTPClientException => e
        # rescue API V0 if 406 and the server supports V0
        supported_versions = server_client_api_version_intersection(e, SUPPORTED_API_VERSIONS)
        raise e unless supported_versions && supported_versions.include?(0)

        payload = {
          username: @username,
          display_name: @display_name,
          first_name: @first_name,
          last_name: @last_name,
          email: @email,
          password: @password,
        }
        payload[:middle_name] = @middle_name unless @middle_name.nil?
        payload[:public_key] = @public_key unless @public_key.nil?
        # under API V0, the server will create a key pair if public_key isn't passed
        new_user = chef_root_rest_v0.post("users", payload)
      end

      Chef::UserV1.from_hash(to_h.merge(new_user))
    end

    def update(new_key = false)
      begin
        payload = { username: username }
        payload[:display_name] = display_name unless display_name.nil?
        payload[:first_name] = first_name unless first_name.nil?
        payload[:middle_name] = middle_name unless middle_name.nil?
        payload[:last_name] = last_name unless last_name.nil?
        payload[:email] = email unless email.nil?
        payload[:password] = password unless password.nil?

        # API V1 will fail if these key fields are defined, and try V0 below if relevant 400 is returned
        payload[:public_key] = public_key unless public_key.nil?
        payload[:private_key] = new_key if new_key

        updated_user = chef_root_rest_v1.put("users/#{username}", payload)
      rescue Net::HTTPClientException => e
        if e.response.code == "400"
          # if a 400 is returned but the error message matches the error related to private / public key fields, try V0
          # else, raise the 400
          error = Chef::JSONCompat.from_json(e.response.body)["error"].first
          error_match = /Since Server API v1, all keys must be updated via the keys endpoint/.match(error)
          if error_match.nil?
            raise e
          end
        else # for other types of errors, test for API versioning errors right away
          supported_versions = server_client_api_version_intersection(e, SUPPORTED_API_VERSIONS)
          raise e unless supported_versions && supported_versions.include?(0)
        end
        updated_user = chef_root_rest_v0.put("users/#{username}", payload)
      end
      Chef::UserV1.from_hash(to_h.merge(updated_user))
    end

    def save(new_key = false)
      create
    rescue Net::HTTPClientException => e
      if e.response.code == "409"
        update(new_key)
      else
        raise e
      end
    end

    # Note: remove after API v0 no longer supported by client (and knife command).
    def reregister
      begin
        payload = to_h.merge({ "private_key" => true })
        reregistered_self = chef_root_rest_v0.put("users/#{username}", payload)
        private_key(reregistered_self["private_key"])
      # only V0 supported for reregister
      rescue Net::HTTPClientException => e
        # if there was a 406 related to versioning, give error explaining that
        # only API version 0 is supported for reregister command
        if e.response.code == "406" && e.response["x-ops-server-api-version"]
          version_header = Chef::JSONCompat.from_json(e.response["x-ops-server-api-version"])
          min_version = version_header["min_version"]
          max_version = version_header["max_version"]
          error_msg = reregister_only_v0_supported_error_msg(max_version, min_version)
          raise Chef::Exceptions::OnlyApiVersion0SupportedForAction.new(error_msg)
        else
          raise e
        end
      end
      self
    end

    def to_s
      "user[#{@username}]"
    end

    # Class Methods
    def self.from_hash(user_hash)
      user = Chef::UserV1.new
      user.username user_hash["username"]
      user.display_name user_hash["display_name"] if user_hash.key?("display_name")
      user.first_name user_hash["first_name"] if user_hash.key?("first_name")
      user.middle_name user_hash["middle_name"] if user_hash.key?("middle_name")
      user.last_name user_hash["last_name"] if user_hash.key?("last_name")
      user.email user_hash["email"] if user_hash.key?("email")
      user.password user_hash["password"] if user_hash.key?("password")
      user.public_key user_hash["public_key"] if user_hash.key?("public_key")
      user.private_key user_hash["private_key"] if user_hash.key?("private_key")
      user.create_key user_hash["create_key"] if user_hash.key?("create_key")
      user
    end

    def self.from_json(json)
      Chef::UserV1.from_hash(Chef::JSONCompat.from_json(json))
    end

    def self.list(inflate = false)
      response = Chef::ServerAPI.new(Chef::Config[:chef_server_url]).get("users")
      users = if response.is_a?(Array)
                # EC 11 / CS 12 V0, V1
                #   GET /organizations/<org>/users
                transform_list_response(response)
              else
                # OSC 11
                #  GET /users
                # EC 11 / CS 12 V0, V1
                #  GET /users
                response # OSC
              end

      if inflate
        users.inject({}) do |user_map, (name, _url)|
          user_map[name] = Chef::UserV1.load(name)
          user_map
        end
      else
        users
      end
    end

    def self.load(username)
      # will default to the current API version (Chef::Authenticator::DEFAULT_SERVER_API_VERSION)
      response = Chef::ServerAPI.new(Chef::Config[:chef_server_url]).get("users/#{username}")
      Chef::UserV1.from_hash(response)
    end

    # Gross.  Transforms an API response in the form of:
    # [ { "user" => { "username" => USERNAME }}, ...]
    # into the form
    # { "USERNAME" => "URI" }
    def self.transform_list_response(response)
      new_response = {}
      response.each do |u|
        name = u["user"]["username"]
        new_response[name] = Chef::Config[:chef_server_url] + "/users/#{name}"
      end
      new_response
    end

    private_class_method :transform_list_response

  end
end
