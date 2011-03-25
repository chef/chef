#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

require 'chef/config'
require 'chef/exceptions'
require 'chef/cookbook/cookbook_version_loader'
require 'chef/cookbook_version'
require 'chef/cookbook/chefignore'
require 'chef/cookbook/metadata'

class Chef
  class CookbookLoader

    attr_accessor :metadata
    attr_reader :cookbooks_by_name

    include Enumerable

    def initialize(*repo_paths)
      @repo_paths = repo_paths.flatten
      raise ArgumentError, "You must specify at least one cookbook repo path" if @repo_paths.empty?
      @cookbooks_by_name = Mash.new
      @loaded_cookbooks = {}
      @metadata = Mash.new
      load_cookbooks
    end

    def load_cookbooks
      cookbook_settings = Hash.new
      @repo_paths.each do |repo_path|
        repo_path = File.expand_path(repo_path)
        chefignore = Cookbook::Chefignore.new(repo_path)
        Dir[File.join(repo_path, "*")].each do |cookbook_path|
          next unless File.directory?(cookbook_path)
          loader = Cookbook::CookbookVersionLoader.new(cookbook_path, chefignore)
          loader.load_cookbooks
          next if loader.empty?
          if @loaded_cookbooks.key?(loader.cookbook_name)
            @loaded_cookbooks[loader.cookbook_name].merge!(loader)
          else
            @loaded_cookbooks[loader.cookbook_name] = loader
          end
        end
      end

      @loaded_cookbooks.each do |cookbook, loader|
        cookbook_version = loader.cookbook_version
        @cookbooks_by_name[cookbook] = cookbook_version
        @metadata[cookbook] = cookbook_version.metadata
      end
      @cookbooks_by_name
    end

    def [](cookbook)
      if @cookbooks_by_name.has_key?(cookbook.to_sym)
        @cookbooks_by_name[cookbook.to_sym]
      else
        raise Exceptions::CookbookNotFoundInRepo, "Cannot find a cookbook named #{cookbook.to_s}; did you forget to add metadata to a cookbook? (http://wiki.opscode.com/display/chef/Metadata)"
      end
    end

    alias :fetch :[]

    def has_key?(cookbook_name)
      @cookbooks_by_name.has_key?(cookbook_name)
    end
    alias :cookbook_exists? :has_key?
    alias :key? :has_key?

    def each
      @cookbooks_by_name.keys.sort { |a,b| a.to_s <=> b.to_s }.each do |cname|
        yield(cname, @cookbooks_by_name[cname])
      end
    end

    def cookbook_names
      @cookbooks_by_name.keys.sort
    end

    def values
      @cookbooks_by_name.values
    end
    alias :cookbooks :values

  end
end
