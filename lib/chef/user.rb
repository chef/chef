#
# Author:: Steven Danna (steve@opscode.com)
# Copyright:: Copyright 2012 Opscode, Inc.
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
require 'chef/config'
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/search/query'
require 'chef/versioned_rest'
require 'chef/mixin/api_version_request_handling'
require 'chef/exceptions'

class Chef
  class User

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    include Chef::VersionedRest
    include Chef::ApiVersionRequestHandling

    SUPPORTED_API_VERSIONS = [0,1]

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
      @password = nil
      @admin = false
    end

    def chef_rest_v0
      @chef_rest_v0 ||= get_versioned_rest_object(Chef::Config[:chef_server_url], "0")
    end

    def chef_rest_v1
      @chef_rest_v1 ||= get_versioned_rest_object(Chef::Config[:chef_server_url], "1")
    end

    def chef_root_rest_v0
      @chef_root_rest_v0 ||= get_versioned_rest_object(Chef::Config[:chef_server_root], "0")
    end

    def chef_root_rest_v1
      @chef_root_rest_v1 ||= get_versioned_rest_object(Chef::Config[:chef_server_root], "1")
    end

    def username(arg=nil)
      set_or_return(:username, arg,
                    :regex => /^[a-z0-9\-_]+$/)
    end

    def display_name(arg=nil)
      set_or_return(:display_name,
                    arg, :kind_of => String)
    end

    def first_name(arg=nil)
      set_or_return(:first_name,
                    arg, :kind_of => String)
    end

    def middle_name(arg=nil)
      set_or_return(:middle_name,
                    arg, :kind_of => String)
    end

    def last_name(arg=nil)
      set_or_return(:last_name,
                    arg, :kind_of => String)
    end

    def email(arg=nil)
      set_or_return(:email,
                    arg, :kind_of => String)
    end

    def password(arg=nil)
      set_or_return(:password,
                    arg, :kind_of => String)
    end

    def admin(arg=nil)
      set_or_return(:admin,
                    arg, :kind_of => [TrueClass, FalseClass])
    end

    def create_key(arg=nil)
      set_or_return(:create_key, arg,
                    :kind_of => [TrueClass, FalseClass])
    end

    def public_key(arg=nil)
      set_or_return(:public_key,
                    arg, :kind_of => String)
    end

    def private_key(arg=nil)
      set_or_return(:private_key,
                    arg, :kind_of => String)
    end

    def password(arg=nil)
      set_or_return(:password,
                    arg, :kind_of => String)
    end

    def to_hash
      result = {
        "username" => @username,
        "admin" => @admin
      }
      result["display_name"] = @display_name if @display_name
      result["first_name"] = @first_name if @first_name
      result["middle_name"] = @middle_name if @middle_name
      result["last_name"] = @last_name if @last_name
      result["email"] = @email if @email
      result["password"] = @password if @password
      result["public_key"] = @public_key if @public_key
      result["private_key"] = @private_key if @private_key
      result
    end

    def to_json(*a)
      Chef::JSONCompat.to_json(to_hash, *a)
    end

    def destroy
      Chef::REST.new(Chef::Config[:chef_server_url]).delete("users/#{@username}")
    end

    def create
      # try v1, fail back to v0 if v1 not supported
      begin
        payload = {
          :username => @username,
          :display_name => @display_name,
          :first_name => @first_name,
          :last_name => @last_name,
          :email => @email,
          :password => @password,
          :admin => @admin
        }
        payload[:public_key] = @public_key if @public_key
        payload[:create_key] = @create_key if @create_key
        payload[:middle_name] = @middle_name if @middle_name
        raise Chef::Exceptions::InvalidUserAttribute, "You cannot set both public_key and create_key for create." if @create_key && @public_key
        new_user = chef_root_rest_v1.post("users", payload)

        # get the private_key out of the chef_key hash if it exists
        if new_user['chef_key']
          if new_user['chef_key']['private_key']
            new_user['private_key'] = new_user['chef_key']['private_key']
          end
          new_user['public_key'] = new_user['chef_key']['public_key']
          new_user.delete('chef_key')
        end
      rescue Net::HTTPServerException => e
        raise e unless handle_version_http_exception(e, SUPPORTED_API_VERSIONS[0], SUPPORTED_API_VERSIONS[-1])
        payload = {
          :username => @username,
          :display_name => @display_name,
          :first_name => @first_name,
          :last_name => @last_name,
          :email => @email,
          :password => @password,
          :admin => @admin
        }
        payload[:middle_name] = @middle_name if @middle_name
        payload[:public_key] = @public_key if @public_key
        new_user = chef_root_rest_v0.post("users", payload)
      end

      Chef::User.from_hash(self.to_hash.merge(new_user))
    end

    def update(new_key=false)
      payload = {:username => username, :admin => admin}
      payload[:private_key] = new_key if new_key
      payload[:password] = password if password
      updated_user = Chef::REST.new(Chef::Config[:chef_server_url]).put("users/#{username}", payload)
      Chef::User.from_hash(self.to_hash.merge(updated_user))
    end

    def save(new_key=false)
      begin
        create
      rescue Net::HTTPServerException => e
        if e.response.code == "409"
          update(new_key)
        else
          raise e
        end
      end
    end

    def reregister
      r = Chef::REST.new(Chef::Config[:chef_server_url])
      reregistered_self = r.put("users/#{username}", { :username => username, :admin => admin, :private_key => true })
      private_key(reregistered_self["private_key"])
      self
    end

    def to_s
      "user[#{@username}]"
    end

    def inspect
      "Chef::User username:'#{username}' admin:'#{admin.inspect}'" +
      "public_key:'#{public_key}' private_key:#{private_key}"
    end

    # Class Methods

    def self.from_hash(user_hash)
      user = Chef::User.new
      user.username user_hash['username']
      user.admin user_hash['admin']
      user.display_name user_hash['display_name'] if user_hash.key?('display_name')
      user.first_name user_hash['first_name'] if user_hash.key?('first_name')
      user.middle_name user_hash['middle_name'] if user_hash.key?('middle_name')
      user.last_name user_hash['last_name'] if user_hash.key?('last_name')
      user.email user_hash['email'] if user_hash.key?('email')
      user.password user_hash['password'] if user_hash.key?('password')
      user.public_key user_hash['public_key'] if user_hash.key?('public_key')
      user.private_key user_hash['private_key'] if user_hash.key?('private_key')
      user.create_key user_hash['create_key'] if user_hash.key?('create_key')
      user
    end

    def self.from_json(json)
      Chef::User.from_hash(Chef::JSONCompat.from_json(json))
    end

    class << self
      alias_method :json_create, :from_json
    end

    def self.list(inflate=false)
      response = Chef::REST.new(Chef::Config[:chef_server_url]).get('users')
      users = if response.is_a?(Array)
        transform_ohc_list_response(response) # OHC/OPC
      else
        response # OSC
      end
      if inflate
        users.inject({}) do |user_map, (name, _url)|
          user_map[name] = Chef::User.load(name)
          user_map
        end
      else
        users
      end
    end

    def self.load(username)
      response = Chef::REST.new(Chef::Config[:chef_server_url]).get("users/#{username}")
      Chef::User.from_hash(response)
    end

    # Gross.  Transforms an API response in the form of:
    # [ { "user" => { "username" => USERNAME }}, ...]
    # into the form
    # { "USERNAME" => "URI" }
    def self.transform_ohc_list_response(response)
      new_response = Hash.new
      response.each do |u|
        name = u['user']['username']
        new_response[name] = Chef::Config[:chef_server_url] + "/users/#{name}"
      end
      new_response
    end

    private_class_method :transform_ohc_list_response
  end
end
