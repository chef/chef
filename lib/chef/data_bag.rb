#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
require 'chef/data_bag_item'
require 'chef/mash'
require 'chef/json_compat'

class Chef
  class DataBag

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate

    VALID_NAME = /^[\-[:alnum:]_]+$/

    def self.validate_name!(name)
      unless name =~ VALID_NAME
        raise Exceptions::InvalidDataBagName, "DataBags must have a name matching #{VALID_NAME.inspect}, you gave #{name.inspect}"
      end
    end

    # Create a new Chef::DataBag
    def initialize
      @name = ''
    end

    def name(arg=nil)
      set_or_return(
        :name,
        arg,
        :regex => VALID_NAME
      )
    end

    def to_hash
      result = {
        "name" => @name,
        'json_class' => self.class.name,
        "chef_type" => "data_bag",
      }
      result
    end

    # Serialize this object as a hash
    def to_json(*a)
      to_hash.to_json(*a)
    end

    def chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def self.chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    # Create a Chef::Role from JSON
    def self.json_create(o)
      bag = new
      bag.name(o["name"])
      bag
    end

    def self.list(inflate=false)
      if Chef::Config[:solo]
        unless File.directory?(Chef::Config[:data_bag_path])
          raise Chef::Exceptions::InvalidDataBagPath, "Data bag path '#{Chef::Config[:data_bag_path]}' is invalid"
        end

        names = Dir.glob(File.join(Chef::Config[:data_bag_path], "*")).map{|f|File.basename(f)}.sort
        names.inject({}) {|h, n| h[n] = n; h}
      else
        if inflate
          # Can't search for all data bags like other objects, fall back to N+1 :(
          list(false).inject({}) do |response, bag_and_uri|
            response[bag_and_uri.first] = load(bag_and_uri.first)
            response
          end
        else
          Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("data")
        end
      end
    end

    # Load a Data Bag by name via either the RESTful API or local data_bag_path if run in solo mode
    def self.load(name)
      if Chef::Config[:solo]
        unless File.directory?(Chef::Config[:data_bag_path])
          raise Chef::Exceptions::InvalidDataBagPath, "Data bag path '#{Chef::Config[:data_bag_path]}' is invalid"
        end

        Dir.glob(File.join(Chef::Config[:data_bag_path], "#{name}", "*.json")).inject({}) do |bag, f|
          item = Chef::JSONCompat.from_json(IO.read(f))
          bag[item['id']] = item
          bag
        end
      else
        Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("data/#{name}")
      end
    end

    def destroy
      chef_server_rest.delete_rest("data/#{@name}")
    end

    # Save the Data Bag via RESTful API
    def save
      begin
        if Chef::Config[:why_run]
          Chef::Log.warn("In whyrun mode, so NOT performing data bag save.")
        else
          chef_server_rest.put_rest("data/#{@name}", self)
        end
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        chef_server_rest.post_rest("data", self)
      end
      self
    end

    #create a data bag via RESTful API
    def create
      chef_server_rest.post_rest("data", self)
      self
    end

    # As a string
    def to_s
      "data_bag[#{@name}]"
    end

  end
end

