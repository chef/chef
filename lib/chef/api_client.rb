#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
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

require 'chef/config'
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/search/query'

class Chef
  class ApiClient

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate

    # Create a new Chef::ApiClient object.
    def initialize
      @name = ''
      @public_key = nil
      @private_key = nil
      @admin = false
    end

    # Gets or sets the client name.
    #
    # @params [Optional String] The name must be alpha-numeric plus - and _.
    # @return [String] The current value of the name.
    def name(arg=nil)
      set_or_return(
        :name,
        arg,
        :regex => /^[\-[:alnum:]_\.]+$/
      )
    end

    # Gets or sets whether this client is an admin.
    #
    # @params [Optional True/False] Should be true or false - default is false.
    # @return [True/False] The current value
    def admin(arg=nil)
      set_or_return(
        :admin,
        arg,
        :kind_of => [ TrueClass, FalseClass ]
      )
    end

    # Gets or sets the public key.
    #
    # @params [Optional String] The string representation of the public key.
    # @return [String] The current value.
    def public_key(arg=nil)
      set_or_return(
        :public_key,
        arg,
        :kind_of => String
      )
    end

    # Gets or sets the private key.
    #
    # @params [Optional String] The string representation of the private key.
    # @return [String] The current value.
    def private_key(arg=nil)
      set_or_return(
        :private_key,
        arg,
        :kind_of => String
      )
    end

    # The hash representation of the object.  Includes the name and public_key,
    # but never the private key.
    #
    # @return [Hash]
    def to_hash
      result = {
        "name" => @name,
        "public_key" => @public_key,
        "admin" => @admin,
        'json_class' => self.class.name,
        "chef_type" => "client"
      }
      result
    end

    # The JSON representation of the object.
    #
    # @return [String] the JSON string.
    def to_json(*a)
      to_hash.to_json(*a)
    end

    def self.json_create(o)
      client = Chef::ApiClient.new
      client.name(o["name"] || o["clientname"])
      client.public_key(o["public_key"])
      client.admin(o["admin"])
      client
    end

    def self.list(inflate=false)
      if inflate
        response = Hash.new
        Chef::Search::Query.new.search(:client) do |n|
          n = self.json_create(n) if n.instance_of?(Hash)
          response[n.name] = n
        end
        response
      else
        Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("clients")
      end
    end

    # Load a client by name via the API
    def self.load(name)
      response = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("clients/#{name}")
      if response.kind_of?(Chef::ApiClient)
        response
      else
        client = Chef::ApiClient.new
        client.name(response['clientname'])
        client
      end
    end

    # Remove this client via the REST API
    def destroy
      Chef::REST.new(Chef::Config[:chef_server_url]).delete_rest("clients/#{@name}")
    end

    # Save this client via the REST API, returns a hash including the private key
    def save(new_key=false, validation=false)
      if validation
        r = Chef::REST.new(Chef::Config[:chef_server_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key])
      else
        r = Chef::REST.new(Chef::Config[:chef_server_url])
      end
      # First, try and create a new registration
      begin
        r.post_rest("clients", {:name => self.name, :admin => self.admin })
      rescue Net::HTTPServerException => e
        # If that fails, go ahead and try and update it
        if e.response.code == "409"
          r.put_rest("clients/#{name}", { :name => self.name, :admin => self.admin, :private_key => new_key })
        else
          raise e
        end
      end
    end

    # Create the client via the REST API
    def create
      Chef::REST.new(Chef::Config[:chef_server_url]).post_rest("clients", self)
    end

    # As a string
    def to_s
      "client[#{@name}]"
    end

  end
end

