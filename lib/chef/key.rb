#
# Author:: Tyler Cloke (tyler@chef.io)
# Copyright:: Copyright (c) 2015 Chef Software, Inc
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

require 'chef/json_compat'
require 'chef/mixin/params_validate'
require 'chef/exceptions'

class Chef
  # Class for interacting with a chef key object. Can be used to create new keys,
  # save to server, load keys from server, list keys, delete keys, etc.
  #
  # @author Tyler Cloke
  #
  # @attr [String] actor           the name of the client or user that this key is for
  # @attr [String] name            the name of the key
  # @attr [String] public_key      the RSA string of this key
  # @attr [String] private_key     the RSA string of the private key if returned via a POST or PUT
  # @attr [String] expiration_date the ISO formatted string YYYY-MM-DDTHH:MM:SSZ, i.e. 2020-12-24T21:00:00Z
  # @attr [String] rest            Chef::REST object, initialized and cached via chef_rest method
  # @attr [string] api_base        either "users" or "clients", initialized and cached via api_base method
  #
  # @attr_reader [String] actor_field_name must be either 'client' or 'user'
  class Key

    include Chef::Mixin::ParamsValidate

    attr_reader :actor_field_name

    def initialize(actor, actor_field_name)
      # Actor that the key is for, either a client or a user.
      @actor = actor

      unless actor_field_name == "user" || actor_field_name == "client"
        raise Chef::Exceptions::InvalidKeyArgument, "the second argument to initialize must be either 'user' or 'client'"
      end

      @actor_field_name = actor_field_name

      @name = nil
      @public_key = nil
      @private_key = nil
      @expiration_date = nil
      @create_key = nil
    end

    def chef_rest
      @rest ||= if @actor_field_name == "user"
                  Chef::REST.new(Chef::Config[:chef_server_root])
                else
                  Chef::REST.new(Chef::Config[:chef_server_url])
                end
    end

    def api_base
      @api_base ||= if @actor_field_name == "user"
                      "users"
                    else
                      "clients"
                    end
    end

    def actor(arg=nil)
      set_or_return(:actor, arg,
                    :regex => /^[a-z0-9\-_]+$/)
    end

    def name(arg=nil)
      set_or_return(:name, arg,
                    :kind_of => String)
    end

    def public_key(arg=nil)
      raise Chef::Exceptions::InvalidKeyAttribute, "you cannot set the public_key if create_key is true" if !arg.nil? && @create_key
      set_or_return(:public_key, arg,
                    :kind_of => String)
    end

    def private_key(arg=nil)
      set_or_return(:private_key, arg,
                    :kind_of => String)
    end

    def delete_public_key
      @public_key = nil
    end

    def delete_create_key
      @create_key = nil
    end

    def create_key(arg=nil)
      raise Chef::Exceptions::InvalidKeyAttribute, "you cannot set create_key to true if the public_key field exists" if arg == true && !@public_key.nil?
      set_or_return(:create_key, arg,
                    :kind_of => [TrueClass, FalseClass])
    end

    def expiration_date(arg=nil)
      set_or_return(:expiration_date, arg,
                    :regex => /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z|infinity)$/)
    end

    def to_hash
      result = {
        @actor_field_name => @actor
      }
      result["name"] = @name if @name
      result["public_key"] = @public_key if @public_key
      result["private_key"] = @private_key if @private_key
      result["expiration_date"] = @expiration_date if @expiration_date
      result["create_key"] = @create_key if @create_key
      result
    end

    def to_json(*a)
      Chef::JSONCompat.to_json(to_hash, *a)
    end

    def create
      # if public_key is undefined and create_key is false, we cannot create
      if @public_key.nil? && !@create_key
        raise Chef::Exceptions::MissingKeyAttribute, "either public_key must be defined or create_key must be true"
      end

      # defaults the key name to the fingerprint of the key
      if @name.nil?
        # if they didn't pass a public_key,
        #then they must supply a name because we can't generate a fingerprint
        unless @public_key.nil?
          @name = fingerprint
        else
          raise Chef::Exceptions::MissingKeyAttribute, "a name cannot be auto-generated if no public key passed, either pass a public key or supply a name"
        end
      end

      payload = {"name" => @name}
      payload['public_key'] = @public_key unless @public_key.nil?
      payload['create_key'] = @create_key if @create_key
      payload['expiration_date'] = @expiration_date unless @expiration_date.nil?
      result = chef_rest.post_rest("#{api_base}/#{@actor}/keys", payload)
      # append the private key to the current key if the server returned one,
      # since the POST endpoint just returns uri and private_key if needed.
      new_key = self.to_hash
      new_key["private_key"] = result["private_key"] if result["private_key"]
      Chef::Key.from_hash(new_key)
    end

    def fingerprint
      self.class.generate_fingerprint(@public_key)
    end

    # set @name and pass put_name if you wish to update the name of an existing key put_name to @name
    def update(put_name=nil)
      if @name.nil? && put_name.nil?
        raise Chef::Exceptions::MissingKeyAttribute, "the name field must be populated or you must pass a name to update when update is called"
      end

      # If no name was passed, fall back to using @name in the PUT URL, otherwise
      # use the put_name passed. This will update the a key by the name put_name
      # to @name.
      put_name = @name if put_name.nil?

      new_key = chef_rest.put_rest("#{api_base}/#{@actor}/keys/#{put_name}", to_hash)
      # if the server returned a public_key, remove the create_key field, as we now have a key
      if new_key["public_key"]
        self.delete_create_key
      end
      Chef::Key.from_hash(self.to_hash.merge(new_key))
    end

    def save
      create
    rescue Net::HTTPServerException => e
      if e.response.code == "409"
        update
      else
        raise e
      end
    end

    def destroy
      if @name.nil?
        raise Chef::Exceptions::MissingKeyAttribute, "the name field must be populated when delete is called"
      end

      chef_rest.delete_rest("#{api_base}/#{@actor}/keys/#{@name}")
    end

    # Class methods
    def self.from_hash(key_hash)
      if key_hash.has_key?("user")
        key = Chef::Key.new(key_hash["user"], "user")
      elsif key_hash.has_key?("client")
        key = Chef::Key.new(key_hash["client"], "client")
      else
        raise Chef::Exceptions::MissingKeyAttribute, "The hash passed to from_hash does not contain the key 'user' or 'client'. Please pass a hash that defines one of those keys."
      end
      key.name key_hash['name'] if key_hash.key?('name')
      key.public_key key_hash['public_key'] if key_hash.key?('public_key')
      key.private_key key_hash['private_key'] if key_hash.key?('private_key')
      key.create_key key_hash['create_key'] if key_hash.key?('create_key')
      key.expiration_date key_hash['expiration_date'] if key_hash.key?('expiration_date')
      key
    end

    def self.from_json(json)
      Chef::Key.from_hash(Chef::JSONCompat.from_json(json))
    end

    class << self
      alias_method :json_create, :from_json
    end

    def self.list_by_user(actor, inflate=false)
      keys = Chef::REST.new(Chef::Config[:chef_server_root]).get_rest("users/#{actor}/keys")
      self.list(keys, actor, :load_by_user, inflate)
    end

    def self.list_by_client(actor, inflate=false)
      keys = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("clients/#{actor}/keys")
      self.list(keys, actor, :load_by_client, inflate)
    end

    def self.load_by_user(actor, key_name)
      response = Chef::REST.new(Chef::Config[:chef_server_root]).get_rest("users/#{actor}/keys/#{key_name}")
      Chef::Key.from_hash(response.merge({"user" => actor}))
    end

    def self.load_by_client(actor, key_name)
      response = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("clients/#{actor}/keys/#{key_name}")
      Chef::Key.from_hash(response.merge({"client" => actor}))
    end

    def self.generate_fingerprint(public_key)
        openssl_key_object = OpenSSL::PKey::RSA.new(public_key)
        data_string = OpenSSL::ASN1::Sequence([
                                                OpenSSL::ASN1::Integer.new(openssl_key_object.public_key.n),
                                                OpenSSL::ASN1::Integer.new(openssl_key_object.public_key.e)
                                              ])
        OpenSSL::Digest::SHA1.hexdigest(data_string.to_der).scan(/../).join(':')
    end

    private

    def self.list(keys, actor, load_method_symbol, inflate)
      if inflate
        keys.inject({}) do |key_map, result|
          name = result["name"]
          key_map[name] = Chef::Key.send(load_method_symbol, actor, name)
          key_map
        end
      else
        keys
      end
    end
  end
end
