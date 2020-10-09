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
require_relative "server_api"

# TODO
# DEPRECATION NOTE
# This class will be replaced by Chef::UserV1 in Chef 13. It is the code to support the User object
# corresponding to the Open Source Chef Server 11 and only still exists to support
# users still on OSC 11.
#
# Chef::UserV1 now supports Chef Server 12 and will be moved to this namespace in Chef 13.
#
# New development should occur in Chef::UserV1.
# This file and corresponding osc_user knife files
# should be removed once client support for Open Source Chef Server 11 expires.
class Chef
  class User
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate

    def initialize
      @name = ""
      @public_key = nil
      @private_key = nil
      @password = nil
      @admin = false
    end

    def chef_rest_v0
      @chef_rest_v0 ||= Chef::ServerAPI.new(Chef::Config[:chef_server_url], { api_version: "0" })
    end

    def name(arg = nil)
      set_or_return(:name, arg,
        regex: /^[a-z0-9\-_]+$/)
    end

    def admin(arg = nil)
      set_or_return(:admin,
        arg, kind_of: [TrueClass, FalseClass])
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
        "name" => @name,
        "public_key" => @public_key,
        "admin" => @admin,
      }
      result["private_key"] = @private_key if @private_key
      result["password"] = @password if @password
      result
    end

    alias_method :to_hash, :to_h

    def to_json(*a)
      Chef::JSONCompat.to_json(to_h, *a)
    end

    def destroy
      chef_rest_v0.delete("users/#{@name}")
    end

    def create
      payload = { name: name, admin: admin, password: password }
      payload[:public_key] = public_key if public_key
      new_user = chef_rest_v0.post("users", payload)
      Chef::User.from_hash(to_h.merge(new_user))
    end

    def update(new_key = false)
      payload = { name: name, admin: admin }
      payload[:private_key] = new_key if new_key
      payload[:password] = password if password
      updated_user = chef_rest_v0.put("users/#{name}", payload)
      Chef::User.from_hash(to_h.merge(updated_user))
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

    def reregister
      reregistered_self = chef_rest_v0.put("users/#{name}", { name: name, admin: admin, private_key: true })
      private_key(reregistered_self["private_key"])
      self
    end

    def to_s
      "user[#{@name}]"
    end

    def inspect
      "Chef::User name:'#{name}' admin:'#{admin.inspect}'" +
        "public_key:'#{public_key}' private_key:#{private_key}"
    end

    # Class Methods

    def self.from_hash(user_hash)
      user = Chef::User.new
      user.name user_hash["name"]
      user.private_key user_hash["private_key"] if user_hash.key?("private_key")
      user.password user_hash["password"] if user_hash.key?("password")
      user.public_key user_hash["public_key"]
      user.admin user_hash["admin"]
      user
    end

    def self.from_json(json)
      Chef::User.from_hash(Chef::JSONCompat.from_json(json))
    end

    def self.list(inflate = false)
      response = Chef::ServerAPI.new(Chef::Config[:chef_server_url], { api_version: "0" }).get("users")
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

    def self.load(name)
      response = Chef::ServerAPI.new(Chef::Config[:chef_server_url], { api_version: "0" }).get("users/#{name}")
      Chef::User.from_hash(response)
    end

    # Gross.  Transforms an API response in the form of:
    # [ { "user" => { "username" => USERNAME }}, ...]
    # into the form
    # { "USERNAME" => "URI" }
    def self.transform_ohc_list_response(response)
      new_response = {}
      response.each do |u|
        name = u["user"]["username"]
        new_response[name] = Chef::Config[:chef_server_url] + "/users/#{name}"
      end
      new_response
    end

    private_class_method :transform_ohc_list_response
  end
end
