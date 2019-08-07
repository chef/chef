#
# Author:: Stephen Delano (<stephen@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
# Author:: John Keiser (<jkeiser@ospcode.com>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
# Copyright:: Copyright 2010-2018, Chef Software Inc.
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
require_relative "mash"
require_relative "mixin/params_validate"
require_relative "mixin/from_file"
require_relative "version_constraint"
require_relative "server_api"
require_relative "dist"

class Chef
  class Environment

    DEFAULT = "default".freeze

    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::FromFile

    COMBINED_COOKBOOK_CONSTRAINT = /(.+)(?:[\s]+)((?:#{Chef::VersionConstraint::OPS.join('|')})(?:[\s]+).+)$/.freeze

    def initialize(chef_server_rest: nil)
      @name = ""
      @description = ""
      @default_attributes = Mash.new
      @override_attributes = Mash.new
      @cookbook_versions = {}
      @chef_server_rest = chef_server_rest
    end

    def chef_server_rest
      @chef_server_rest ||= Chef::ServerAPI.new(Chef::Config[:chef_server_url])
    end

    def self.chef_server_rest
      Chef::ServerAPI.new(Chef::Config[:chef_server_url])
    end

    def name(arg = nil)
      set_or_return(
        :name,
        arg,
        { regex: /^[\-[:alnum:]_]+$/, kind_of: String }
      )
    end

    def description(arg = nil)
      set_or_return(
        :description,
        arg,
        kind_of: String
      )
    end

    def default_attributes(arg = nil)
      set_or_return(
        :default_attributes,
        arg,
        kind_of: Hash
      )
    end

    def default_attributes=(attrs)
      default_attributes(attrs)
    end

    def override_attributes(arg = nil)
      set_or_return(
        :override_attributes,
        arg,
        kind_of: Hash
      )
    end

    def override_attributes=(attrs)
      override_attributes(attrs)
    end

    def cookbook_versions(arg = nil)
      set_or_return(
        :cookbook_versions,
        arg,
        {
          kind_of: Hash,
          callbacks: {
            "should be a valid set of cookbook version requirements" => lambda { |cv| Chef::Environment.validate_cookbook_versions(cv) },
          },
        }
      )
    end

    def cookbook(cookbook, version)
      validate({
        version: version,
      }, {
        version: {
          callbacks: { "should be a valid version requirement" => lambda { |v| Chef::Environment.validate_cookbook_version(v) } },
        },
      })
      @cookbook_versions[cookbook] = version
    end

    def to_h
      result = {
        "name" => @name,
        "description" => @description,
        "cookbook_versions" => @cookbook_versions,
        "json_class" => self.class.name,
        "chef_type" => "environment",
        "default_attributes" => @default_attributes,
        "override_attributes" => @override_attributes,
      }
      result
    end

    alias_method :to_hash, :to_h

    def to_json(*a)
      Chef::JSONCompat.to_json(to_h, *a)
    end

    def update_from!(o)
      description(o.description)
      cookbook_versions(o.cookbook_versions)
      default_attributes(o.default_attributes)
      override_attributes(o.override_attributes)
      self
    end

    def update_attributes_from_params(params)
      unless params[:default_attributes].nil? || params[:default_attributes].size == 0
        default_attributes(Chef::JSONCompat.from_json(params[:default_attributes]))
      end
      unless params[:override_attributes].nil? || params[:override_attributes].size == 0
        override_attributes(Chef::JSONCompat.from_json(params[:override_attributes]))
      end
    end

    def update_from_params(params)
      # reset because everything we need will be in the params, this is necessary because certain constraints
      # may have been removed in the params and need to be removed from cookbook_versions as well.
      bkup_cb_versions = cookbook_versions
      cookbook_versions({})
      valid = true

      begin
        name(params[:name])
      rescue Chef::Exceptions::ValidationFailed => e
        invalid_fields[:name] = e.message
        valid = false
      end
      description(params[:description])

      unless params[:cookbook_version].nil?
        params[:cookbook_version].each do |index, cookbook_constraint_spec|
          unless cookbook_constraint_spec.nil? || cookbook_constraint_spec.size == 0
            valid &&= update_cookbook_constraint_from_param(index, cookbook_constraint_spec)
          end
        end
      end

      update_attributes_from_params(params)

      valid = validate_required_attrs_present && valid
      cookbook_versions(bkup_cb_versions) unless valid # restore the old cookbook_versions if valid is false
      valid
    end

    def update_cookbook_constraint_from_param(index, cookbook_constraint_spec)
      valid = true
      md = cookbook_constraint_spec.match(COMBINED_COOKBOOK_CONSTRAINT)
      if md.nil? || md[2].nil?
        valid = false
        add_cookbook_constraint_error(index, cookbook_constraint_spec)
      elsif self.class.validate_cookbook_version(md[2])
        cookbook_versions[md[1]] = md[2]
      else
        valid = false
        add_cookbook_constraint_error(index, cookbook_constraint_spec)
      end
      valid
    end

    def add_cookbook_constraint_error(index, cookbook_constraint_spec)
      invalid_fields[:cookbook_version] ||= {}
      invalid_fields[:cookbook_version][index] = "#{cookbook_constraint_spec} is not a valid cookbook constraint"
    end

    def invalid_fields
      @invalid_fields ||= {}
    end

    def validate_required_attrs_present
      if name.nil? || name.size == 0
        invalid_fields[:name] ||= "name cannot be empty"
        false
      else
        true
      end
    end

    def self.from_hash(o)
      environment = new
      environment.name(o["name"])
      environment.description(o["description"])
      environment.cookbook_versions(o["cookbook_versions"])
      environment.default_attributes(o["default_attributes"])
      environment.override_attributes(o["override_attributes"])
      environment
    end

    def self.list(inflate = false)
      if inflate
        response = {}
        Chef::Search::Query.new.search(:environment) do |e|
          response[e.name] = e unless e.nil?
        end
        response
      else
        chef_server_rest.get("environments")
      end
    end

    def self.load(name)
      if Chef::Config[:solo_legacy_mode]
        load_from_file(name)
      else
        from_hash(chef_server_rest.get("environments/#{name}"))
      end
    end

    def self.load_from_file(name)
      unless File.directory?(Chef::Config[:environment_path])
        raise Chef::Exceptions::InvalidEnvironmentPath, "Environment path '#{Chef::Config[:environment_path]}' is invalid"
      end

      js_file = File.join(Chef::Config[:environment_path], "#{name}.json")
      rb_file = File.join(Chef::Config[:environment_path], "#{name}.rb")

      if File.exists?(js_file)
        # from_json returns object.class => json_class in the JSON.
        hash = Chef::JSONCompat.parse(IO.read(js_file))
        from_hash(hash)
      elsif File.exists?(rb_file)
        environment = Chef::Environment.new
        environment.name(name)
        environment.from_file(rb_file)
        environment
      else
        raise Chef::Exceptions::EnvironmentNotFound, "Environment '#{name}' could not be loaded from disk"
      end
    end

    def destroy
      chef_server_rest.delete("environments/#{@name}")
    end

    def save
      begin
        chef_server_rest.put("environments/#{@name}", self)
      rescue Net::HTTPClientException => e
        raise e unless e.response.code == "404"

        chef_server_rest.post("environments", self)
      end
      self
    end

    def create
      chef_server_rest.post("environments", self)
      self
    end

    def self.load_filtered_recipe_list(environment)
      chef_server_rest.get("environments/#{environment}/recipes")
    end

    def to_s
      @name
    end

    def self.validate_cookbook_versions(cv)
      return false unless cv.is_a?(Hash)

      cv.each_value do |version|
        return false unless Chef::Environment.validate_cookbook_version(version)
      end
      true
    end

    def self.validate_cookbook_version(version)
      if Chef::Config[:solo_legacy_mode]
        raise Chef::Exceptions::IllegalVersionConstraint,
          "Environment cookbook version constraints not allowed in #{Chef::Dist::SOLO}"
      else
        Chef::VersionConstraint.new version
        true
      end
    rescue ArgumentError
      false
    end

  end
end
