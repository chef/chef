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
  class ApiClientV1

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate

    # Create a new Chef::ApiClientV1 object.
    def initialize
      @name = ''
      @private_key = nil
      @create_key = nil
      @validator = false
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

    # Gets or sets whether this client is a validator.
    #
    # @params [Boolean] whether or not the client is a validator.  If
    #   `nil`, retrieves the already-set value.
    # @return [Boolean] The current value
    def validator(arg=nil)
      set_or_return(
        :validator,
        arg,
        :kind_of => [TrueClass, FalseClass]
      )
    end

    # Field to ask server to create a "default" public / private key pair
    # on initial client POST. Only valid / relevant on initial POST.
    def create_key(arg=nil)
      set_or_return(:create_key, arg,
                    :kind_of => [TrueClass, FalseClass])
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

    # The hash representation of the object. Includes the name.
    # Private key is included if available.
    #
    # @return [Hash]
    def to_hash
      result = {
        "name" => @name,
        "validator" => @validator
      }
      result["private_key"] = @private_key if @private_key
      result
    end

    # The JSON representation of the object.
    #
    # @return [String] the JSON string.
    def to_json(*a)
      Chef::JSONCompat.to_json(to_hash, *a)
    end

    def self.from_hash(o)
      client = Chef::ApiClientV1.new
      client.name(o["name"] || o["clientname"])
      client.private_key(o["private_key"]) if o.key?("private_key")
      client.validator(o["validator"])
      client
    end

    def self.json_create(data)
      from_hash(data)
    end

    def self.from_json(j)
      from_hash(Chef::JSONCompat.parse(j))
    end

    def self.http_api
      Chef::REST.new(Chef::Config[:chef_server_url])
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
        http_api.get("clients")
      end
    end

    # Load a client by name via the API
    def self.load(name)
      response = http_api.get("clients/#{name}")
      if response.kind_of?(Chef::ApiClientV1)
        response
      else
        json_create(response)
      end
    end

    # Remove this client via the REST API
    def destroy
      http_api.delete("clients/#{@name}")
    end

    # Save this client via the REST API, returns a hash including the private key
    def save
      begin
        http_api.put("clients/#{name}", {:name => self.name, :validator => self.validator})
      rescue Net::HTTPServerException => e
        # If that fails, go ahead and try and update it
        if e.response.code == "404"
          http_api.post("clients", {:name => self.name, :validator => self.validator })
        else
          raise e
        end
      end
    end

    # Create the client via the REST API
    def create(initial_public_key = nil)
      payload = {:name => @name, :validator => @validator}
      raise Chef::Exceptions::InvalidClientAttribute, "you cannot pass an initial_public_key to create if create_key is true" if @create_key && initial_public_key
      payload[:public_key] = initial_public_key if initial_public_key
      payload[:create_key] = @create_key if @create_key
      new_client = Chef::REST.new(Chef::Config[:chef_server_url]).post_rest("clients", payload)

      # get the private_key out of the chef_key hash if it exists
      if new_client['chef_key']
        if new_client['chef_key']['private_key']
          new_client['private_key'] = new_client['chef_key']['private_key']
        end
        delete new_client['chef_key']
      end
      Chef::User.from_hash(self.to_hash.merge(new_client))
    end

    # As a string
    def to_s
      "client[#{@name}]"
    end

    def inspect
      string = "Chef::ApiClientV1 name:'#{@name}' validator:'#{@validator}' "
      string = "private_key:'#{@private_key}'" if @private_key
    end

    def http_api
      @http_api ||= Chef::REST.new(Chef::Config[:chef_server_url])
    end

  end
end
