#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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

require "chef/config"
require "chef/exceptions"
require "chef/cookbook/cookbook_version_loader"
require "chef/cookbook_version"
require "chef/cookbook/chefignore"
require "chef/cookbook/metadata"

#
# CookbookLoader class loads the cookbooks lazily as read
#
class Chef
  class CookbookLoader

    attr_reader :cookbooks_by_name
    attr_reader :merged_cookbooks
    attr_reader :cookbook_paths
    attr_reader :metadata

    include Enumerable

    def initialize(*repo_paths)
      repo_paths = repo_paths.flatten
      raise ArgumentError, "You must specify at least one cookbook repo path" if repo_paths.empty?
      @cookbooks_by_name = Mash.new
      @loaded_cookbooks = {}
      @metadata = Mash.new
      @chefignores = {}
      @repo_paths = repo_paths.map do |repo_path|
        File.expand_path(repo_path)
      end

      @preloaded_cookbooks = false
      @loaders_by_name = {}
    end

    def load_cookbooks
      preload_cookbooks
      @loaders_by_name.each_key do |cookbook_name|
        load_cookbook(cookbook_name)
      end
      @cookbooks_by_name
    end

    def load_cookbook(cookbook_name)
      preload_cookbooks

      return @cookbooks_by_name[cookbook_name] if @cookbooks_by_name.key?(cookbook_name)

      return nil unless @loaders_by_name.key?(cookbook_name.to_s)

      cookbook_loaders_for(cookbook_name).each do |loader|
        loader.load

        next if loader.empty?

        if @loaded_cookbooks.key?(cookbook_name)
          raise Chef::Exceptions::CookbookMergingError, "Cookbook merging is no longer supported, the cookbook named #{cookbook_name} can only appear once in the cookbook_path"
        else
          @loaded_cookbooks[cookbook_name] = loader
        end
      end

      if @loaded_cookbooks.key?(cookbook_name)
        cookbook_version = @loaded_cookbooks[cookbook_name].cookbook_version
        @cookbooks_by_name[cookbook_name] = cookbook_version
        @metadata[cookbook_name] = cookbook_version.metadata
      end
      @cookbooks_by_name[cookbook_name]
    end

    def [](cookbook)
      if @cookbooks_by_name.key?(cookbook.to_sym) || load_cookbook(cookbook.to_sym)
        @cookbooks_by_name[cookbook.to_sym]
      else
        raise Exceptions::CookbookNotFoundInRepo, "Cannot find a cookbook named #{cookbook}; did you forget to add metadata to a cookbook? (https://docs.chef.io/config_rb_metadata.html)"
      end
    end

    alias :fetch :[]

    def has_key?(cookbook_name)
      not self[cookbook_name.to_sym].nil?
    end
    alias :cookbook_exists? :has_key?
    alias :key? :has_key?

    def each
      @cookbooks_by_name.keys.sort_by(&:to_s).each do |cname|
        yield(cname, @cookbooks_by_name[cname])
      end
    end

    def each_key(&block)
      cookbook_names.each(&block)
    end

    def each_value(&block)
      values.each(&block)
    end

    def cookbook_names
      @cookbooks_by_name.keys.sort
    end

    def values
      @cookbooks_by_name.values
    end
    alias :cookbooks :values

    private

    def preload_cookbooks
      return false if @preloaded_cookbooks

      all_directories_in_repo_paths.each do |cookbook_path|
        preload_cookbook(cookbook_path)
      end
      @preloaded_cookbooks = true
      true
    end

    def preload_cookbook(cookbook_path)
      repo_path = File.dirname(cookbook_path)
      @chefignores[repo_path] ||= Cookbook::Chefignore.new(repo_path)
      loader = Cookbook::CookbookVersionLoader.new(cookbook_path, @chefignores[repo_path])
      add_cookbook_loader(loader)
    end

    def all_directories_in_repo_paths
      @all_directories_in_repo_paths ||=
        all_files_in_repo_paths.select { |path| File.directory?(path) }
    end

    def all_files_in_repo_paths
      @all_files_in_repo_paths ||=
        begin
          @repo_paths.inject([]) do |all_children, repo_path|
            all_children + Dir[File.join(Chef::Util::PathHelper.escape_glob_dir(repo_path), "*")]
          end
        end
    end

    def add_cookbook_loader(loader)
      cookbook_name = loader.cookbook_name

      @loaders_by_name[cookbook_name.to_s] ||= []
      @loaders_by_name[cookbook_name.to_s] << loader
      loader
    end

    def cookbook_loaders_for(cookbook_name)
      @loaders_by_name[cookbook_name.to_s]
    end

  end
end
