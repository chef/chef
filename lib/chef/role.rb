#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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
require 'chef/run_list'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/search/query'

class Chef
  class Role

    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate

    attr_accessor :chef_server_rest

    # Create a new Chef::Role object.
    def initialize(chef_server_rest: nil)
      @name = ''
      @description = ''
      @default_attributes = Mash.new
      @override_attributes = Mash.new
      @env_run_lists = {"_default" => Chef::RunList.new}
      @chef_server_rest = chef_server_rest
    end

    def chef_server_rest
      @chef_server_rest ||= Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def self.chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

    def name(arg=nil)
      set_or_return(
        :name,
        arg,
        :regex => /^[\-[:alnum:]_]+$/
      )
    end

    def description(arg=nil)
      set_or_return(
        :description,
        arg,
        :kind_of => String
      )
    end

    def run_list(*args)
      if (args.length > 0)
        @env_run_lists["_default"].reset!(args)
      end
      @env_run_lists["_default"]
    end

    alias_method :recipes, :run_list

    # For run_list expansion
    def run_list_for(environment)
      if env_run_lists[environment].nil?
        env_run_lists["_default"]
      else
        env_run_lists[environment]
      end
    end

    def active_run_list_for(environment)
      @env_run_lists.has_key?(environment) ? environment : '_default'
    end

    # Per environment run lists
    def env_run_lists(env_run_lists=nil)
      if (!env_run_lists.nil?)
        unless env_run_lists.key?("_default")
          msg = "_default key is required in env_run_lists.\n"
          msg << "(env_run_lists: #{env_run_lists.inspect})"
          raise Chef::Exceptions::InvalidEnvironmentRunListSpecification, msg
        end
        @env_run_lists.clear
        env_run_lists.each { |k,v| @env_run_lists[k] = Chef::RunList.new(*Array(v))}
      end
      @env_run_lists
    end

    alias :env_run_list :env_run_lists

    def default_attributes(arg=nil)
      set_or_return(
        :default_attributes,
        arg,
        :kind_of => Hash
      )
    end

    def override_attributes(arg=nil)
      set_or_return(
        :override_attributes,
        arg,
        :kind_of => Hash
      )
    end

    def to_hash
      env_run_lists_without_default = @env_run_lists.dup
      env_run_lists_without_default.delete("_default")
      result = {
        "name" => @name,
        "description" => @description,
        'json_class' => self.class.name,
        "default_attributes" => @default_attributes,
        "override_attributes" => @override_attributes,
        "chef_type" => "role",

        #Render to_json correctly for run_list items (both run_list and evn_run_lists)
        #so malformed json does not result
        "run_list" => run_list.run_list.map { |item| item.to_s },
        "env_run_lists" => env_run_lists_without_default.inject({}) do |accumulator, (k, v)|
          accumulator[k] = v.map { |x| x.to_s }
          accumulator
        end
      }
      result
    end

    # Serialize this object as a hash
    def to_json(*a)
      Chef::JSONCompat.to_json(to_hash, *a)
    end

    def update_from!(o)
      description(o.description)
      recipes(o.recipes) if defined?(o.recipes)
      default_attributes(o.default_attributes)
      override_attributes(o.override_attributes)
      env_run_lists(o.env_run_lists) unless o.env_run_lists.nil?
      self
    end

    # Create a Chef::Role from JSON
    def self.json_create(o)
      role = new
      role.name(o["name"])
      role.description(o["description"])
      role.default_attributes(o["default_attributes"])
      role.override_attributes(o["override_attributes"])

      # _default run_list is in 'run_list' for newer clients, and
      # 'recipes' for older clients.
      env_run_list_hash = {"_default" => (o.has_key?("run_list") ? o["run_list"] : o["recipes"])}

      # Clients before 0.10 do not include env_run_lists, so only
      # merge if it's there.
      if o["env_run_lists"]
        env_run_list_hash.merge!(o["env_run_lists"])
      end
      role.env_run_lists(env_run_list_hash)

      role
    end

    # Get the list of all roles from the API.
    def self.list(inflate=false)
      if inflate
        response = Hash.new
        Chef::Search::Query.new.search(:role) do |n|
          response[n.name] = n unless n.nil?
        end
        response
      else
        chef_server_rest.get_rest("roles")
      end
    end

    # Load a role by name from the API
    def self.load(name)
      chef_server_rest.get_rest("roles/#{name}")
    end

    def environment(env_name)
      chef_server_rest.get_rest("roles/#{@name}/environments/#{env_name}")
    end

    def environments
      chef_server_rest.get_rest("roles/#{@name}/environments")
    end

    # Remove this role via the REST API
    def destroy
      chef_server_rest.delete_rest("roles/#{@name}")
    end

    # Save this role via the REST API
    def save
      begin
        chef_server_rest.put_rest("roles/#{@name}", self)
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        chef_server_rest.post_rest("roles", self)
      end
      self
    end

    # Create the role via the REST API
    def create
      chef_server_rest.post_rest("roles", self)
      self
    end

    # As a string
    def to_s
      "role[#{@name}]"
    end

    # Load a role from disk - prefers to load the JSON, but will happily load
    # the raw rb files as well. Can search within directories in the role_path.
    def self.from_disk(name)
      paths = Array(Chef::Config[:role_path])
      paths.each do |path|
        roles_files = Dir.glob(File.join(Chef::Util::PathHelper.escape_glob(path), "**", "**"))
        js_files = roles_files.select { |file| file.match /\/#{name}\.json$/ }
        rb_files = roles_files.select { |file| file.match /\/#{name}\.rb$/ }
        if js_files.count > 1 or rb_files.count > 1
          raise Chef::Exceptions::DuplicateRole, "Multiple roles of same type found named #{name}"
        end
        js_path, rb_path = js_files.first, rb_files.first

        if js_path && File.exists?(js_path)
          # from_json returns object.class => json_class in the JSON.
          return Chef::JSONCompat.from_json(IO.read(js_path))
        elsif rb_path && File.exists?(rb_path)
          role = Chef::Role.new
          role.name(name)
          role.from_file(rb_path)
          return role
        end
      end

      raise Chef::Exceptions::RoleNotFound, "Role '#{name}' could not be loaded from disk"
    end

  end
end
