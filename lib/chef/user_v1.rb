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

class Chef
  class UserV1

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate

    def initialize
      @name = ''
      @password = nil
      @private_key = nil
      @create_key = nil
      @admin = false
    end

    def chef_rest
      @chef_rest ||= Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def name(arg=nil)
      set_or_return(:name, arg,
                    :regex => /^[a-z0-9\-_]+$/)
    end

    def admin(arg=nil)
      set_or_return(:admin,
                    arg, :kind_of => [TrueClass, FalseClass])
    end

    # Gets or sets the private key.
    #
    # @params [Optional String] The string representation of the private key.
    # @return [String] The current value.
    def private_key(arg=nil)
      set_or_return(
        :private_key,
        arg,
        :kind_of => [String, FalseClass]
      )
    end

    def create_key(arg=nil)
      set_or_return(:create_key, arg,
                    :kind_of => [TrueClass, FalseClass])
    end

    def password(arg=nil)
      set_or_return(:password,
                    arg, :kind_of => String)
    end

    def to_hash
      result = {
        "name" => @name,
        "admin" => @admin
      }
      result["password"] = @password if @password
      result["private_key"] = @private_key if @private_key
      result
    end

    def to_json(*a)
      Chef::JSONCompat.to_json(to_hash, *a)
    end

    def destroy
      chef_rest.delete("users/#{@name}")
    end

    def create(initial_public_key = nil)
      payload = {:name => self.name, :admin => self.admin, :password => self.password }
      raise Chef::Exceptions::InvalidUserAttribute, "you cannot pass an initial_public_key to create if create_key is true" if @create_key && initial_public_key
      payload[:public_key] = initial_public_key if initial_public_key
      payload[:create_key] = @create_key if @create_key
      new_user = chef_rest.post("users", payload)

      # get the private_key out of the chef_key hash if it exists
      if new_user['chef_key']
        if new_user['chef_key']['private_key']
          new_user['private_key'] = new_user['chef_key']['private_key']
        end
        new_user.delete('chef_key')
      end
      Chef::UserV1.from_hash(self.to_hash.merge(new_user))
    end

    def update(new_key=false)
      payload = {:name => name, :admin => admin}
      payload[:password] = password if password
      updated_user = chef_rest.put("users/#{name}", payload)
      Chef::UserV1.from_hash(self.to_hash.merge(updated_user))
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

    def to_s
      "user[#{@name}]"
    end

    def inspect
      string = "Chef::UserV1 name:'#{@name}' admin:'#{@admin}' "
      string = string + "private_key:#{@private_key}" if @private_key
    end

    # Class Methods

    def self.from_hash(user_hash)
      user = Chef::UserV1.new
      user.name user_hash['name']
      user.password user_hash['password'] if user_hash.key?('password')
      user.admin user_hash['admin']
      user.private_key user_hash['private_key'] if user_hash['private_key']
      user
    end

    def self.from_json(json)
      Chef::UserV1.from_hash(Chef::JSONCompat.from_json(json))
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
          user_map[name] = Chef::UserV1.load(name)
          user_map
        end
      else
        users
      end
    end

    def self.load(name)
      response = Chef::REST.new(Chef::Config[:chef_server_url]).get("users/#{name}")
      Chef::UserV1.from_hash(response)
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
