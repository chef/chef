#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Nuo Yan (<nuo@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

require "chef/config"
require "chef/mixin/params_validate"
require "chef/mixin/from_file"
require "chef/mash"
require "chef/json_compat"
require "chef/search/query"
require "chef/exceptions"
require "chef/mixin/api_version_request_handling"
require "chef/server_api"
require "chef/api_client"

# COMPATIBILITY NOTE
#
# This ApiClientV1 code attempts to make API V1 requests and falls back to
# API V0 requests when it fails. New development should occur here instead
# of Chef::ApiClient as this will replace that namespace when Chef 13 is released.
#
# If you need to default to API V0 behavior (i.e. you need GET client to return
# a public key, etc), please use Chef::ApiClient and update your code to support
# API V1 before you pull in Chef 13.
class Chef
  class ApiClientV1

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::ApiVersionRequestHandling

    SUPPORTED_API_VERSIONS = [0, 1]

    # Create a new Chef::ApiClientV1 object.
    def initialize
      @name = ""
      @public_key = nil
      @private_key = nil
      @admin = false
      @validator = false
      @create_key = nil
    end

    def chef_rest_v0
      @chef_rest_v0 ||= Chef::ServerAPI.new(Chef::Config[:chef_server_url], { :api_version => "0", :inflate_json_class => false })
    end

    def chef_rest_v1
      @chef_rest_v1 ||= Chef::ServerAPI.new(Chef::Config[:chef_server_url], { :api_version => "1", :inflate_json_class => false })
    end

    def self.http_api
      Chef::ServerAPI.new(Chef::Config[:chef_server_url], { :api_version => "1", :inflate_json_class => false })
    end

    # Gets or sets the client name.
    #
    # @params [Optional String] The name must be alpha-numeric plus - and _.
    # @return [String] The current value of the name.
    def name(arg = nil)
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
    def admin(arg = nil)
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
    def public_key(arg = nil)
      set_or_return(
        :public_key,
        arg,
        :kind_of => String
      )
    end

    # Gets or sets whether this client is a validator.
    #
    # @params [Boolean] whether or not the client is a validator.  If
    #   `nil`, retrieves the already-set value.
    # @return [Boolean] The current value
    def validator(arg = nil)
      set_or_return(
        :validator,
        arg,
        :kind_of => [TrueClass, FalseClass]
      )
    end

    # Private key. The server will return it as a string.
    # Set to true under API V0 to have the server regenerate the default key.
    #
    # @params [Optional String] The string representation of the private key.
    # @return [String] The current value.
    def private_key(arg = nil)
      set_or_return(
        :private_key,
        arg,
        :kind_of => [String, TrueClass, FalseClass]
      )
    end

    # Used to ask server to generate key pair under api V1
    #
    # @params [Optional True/False] Should be true or false - default is false.
    # @return [True/False] The current value
    def create_key(arg = nil)
      set_or_return(
        :create_key,
        arg,
        :kind_of => [ TrueClass, FalseClass ]
      )
    end

    # The hash representation of the object. Includes the name and public_key.
    # Private key is included if available.
    #
    # @return [Hash]
    def to_hash
      result = {
        "name" => @name,
        "validator" => @validator,
        "admin" => @admin,
        "chef_type" => "client",
      }
      result["private_key"] = @private_key unless @private_key.nil?
      result["public_key"] = @public_key unless @public_key.nil?
      result["create_key"] = @create_key unless @create_key.nil?
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
      client.admin(o["admin"])
      client.validator(o["validator"])
      client.private_key(o["private_key"]) if o.key?("private_key")
      client.public_key(o["public_key"]) if o.key?("public_key")
      client.create_key(o["create_key"]) if o.key?("create_key")
      client
    end

    def self.from_json(j)
      Chef::ApiClientV1.from_hash(Chef::JSONCompat.from_json(j))
    end

    def self.reregister(name)
      api_client = Chef::ApiClientV1.load(name)
      api_client.reregister
    end

    def self.list(inflate = false)
      if inflate
        response = Hash.new
        Chef::Search::Query.new.search(:client) do |n|
          n = from_hash(n) if n.instance_of?(Hash)
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
      Chef::ApiClientV1.from_hash(response)
    end

    # Remove this client via the REST API
    def destroy
      chef_rest_v1.delete("clients/#{@name}")
    end

    # Save this client via the REST API, returns a hash including the private key
    def save
      update
    rescue Net::HTTPServerException => e
      # If that fails, go ahead and try and update it
      if e.response.code == "404"
        create
      else
        raise e
      end
    end

    def reregister
      # Try API V0 and if it fails due to V0 not being supported, raise the proper error message.
      # reregister only supported in API V0 or lesser.
      reregistered_self = chef_rest_v0.put("clients/#{name}", { :name => name, :admin => admin, :validator => validator, :private_key => true })
      if reregistered_self.respond_to?(:[])
        private_key(reregistered_self["private_key"])
      else
        private_key(reregistered_self.private_key)
      end
      self
    rescue Net::HTTPServerException => e
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

    # Updates the client via the REST API
    def update
      # NOTE: API V1 dropped support for updating client keys via update (aka PUT),
      # but this code never supported key updating in the first place. Since
      # it was never implemented, we will simply ignore that functionality
      # as it is being deprecated.
      # Delete this comment after V0 support is dropped.
      payload = { :name => name }
      payload[:validator] = validator unless validator.nil?

      # DEPRECATION
      # This field is ignored in API V1, but left for backwards-compat,
      # can remove after API V0 is no longer supported.
      payload[:admin] = admin unless admin.nil?

      begin
        new_client = chef_rest_v1.put("clients/#{name}", payload)
      rescue Net::HTTPServerException => e
        # rescue API V0 if 406 and the server supports V0
        supported_versions = server_client_api_version_intersection(e, SUPPORTED_API_VERSIONS)
        raise e unless supported_versions && supported_versions.include?(0)
        new_client = chef_rest_v0.put("clients/#{name}", payload)
      end

      Chef::ApiClientV1.from_hash(new_client)
    end

    # Create the client via the REST API
    def create
      payload = {
        :name => name,
        :validator => validator,
        # this field is ignored in API V1, but left for backwards-compat,
        # can remove after OSC 11 support is finished?
        :admin => admin,
      }
      begin
        # try API V1
        raise Chef::Exceptions::InvalidClientAttribute, "You cannot set both public_key and create_key for create." if !create_key.nil? && !public_key.nil?

        payload[:public_key] = public_key unless public_key.nil?
        payload[:create_key] = create_key unless create_key.nil?

        new_client = chef_rest_v1.post("clients", payload)

        # get the private_key out of the chef_key hash if it exists
        if new_client["chef_key"]
          if new_client["chef_key"]["private_key"]
            new_client["private_key"] = new_client["chef_key"]["private_key"]
          end
          new_client["public_key"] = new_client["chef_key"]["public_key"]
          new_client.delete("chef_key")
        end

      rescue Net::HTTPServerException => e
        # rescue API V0 if 406 and the server supports V0
        supported_versions = server_client_api_version_intersection(e, SUPPORTED_API_VERSIONS)
        raise e unless supported_versions && supported_versions.include?(0)

        # under API V0, a key pair will always be created unless public_key is
        # passed on initial POST
        payload[:public_key] = public_key unless public_key.nil?

        new_client = chef_rest_v0.post("clients", payload)
      end
      Chef::ApiClientV1.from_hash(to_hash.merge(new_client))
    end

    # As a string
    def to_s
      "client[#{@name}]"
    end

  end
end
