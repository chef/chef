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
      @cookbooks_paths = Hash.new {|h,k| h[k] = []} # for deprecation warnings
      @chefignores = {}
      @repo_paths = repo_paths.map do |repo_path|
        repo_path = File.expand_path(repo_path)
      end

      # Used to track which cookbooks appear in multiple places in the cookbook repos
      # and are merged in to a single cookbook by file shadowing. This behavior is
      # deprecated, so users of this class may issue warnings to the user by checking
      # this variable
      @merged_cookbooks = []
    end

    def merged_cookbook_paths # for deprecation warnings
      merged_cookbook_paths = {}
      @merged_cookbooks.each {|c| merged_cookbook_paths[c] = @cookbooks_paths[c]}
      merged_cookbook_paths
    end

    def load_cookbooks
      @repo_paths.each do |repo_path|
        Dir[File.join(repo_path, "*")].each do |cookbook_path|
          load_cookbook(File.basename(cookbook_path), [repo_path])
        end
      end
      @cookbooks_by_name
    end

    def load_cookbook(cookbook_name, repo_paths=nil)
      repo_paths ||= @repo_paths
      repo_paths.each do |repo_path|
        @chefignores[repo_path] ||= Cookbook::Chefignore.new(repo_path)
        cookbook_path = File.join(repo_path, cookbook_name.to_s)
        next unless File.directory?(cookbook_path) and Dir[File.join(repo_path, "*")].include?(cookbook_path)
        loader = Cookbook::CookbookVersionLoader.new(cookbook_path, @chefignores[repo_path])
        loader.load_cookbooks
        next if loader.empty?
        cookbook_name = loader.cookbook_name
        @cookbooks_paths[cookbook_name] << cookbook_path # for deprecation warnings
        if @loaded_cookbooks.key?(cookbook_name)
          @merged_cookbooks << cookbook_name # for deprecation warnings
          @loaded_cookbooks[cookbook_name].merge!(loader)
        else
          @loaded_cookbooks[cookbook_name] = loader
        end
      end

      if @loaded_cookbooks.has_key?(cookbook_name)
        cookbook_version = @loaded_cookbooks[cookbook_name].cookbook_version
        @cookbooks_by_name[cookbook_name] = cookbook_version
        @metadata[cookbook_name] = cookbook_version.metadata
      end
      @cookbooks_by_name[cookbook_name]
    end

    def [](cookbook)
      if @cookbooks_by_name.has_key?(cookbook.to_sym) or load_cookbook(cookbook.to_sym)
        @cookbooks_by_name[cookbook.to_sym]
      else
        raise Exceptions::CookbookNotFoundInRepo, "Cannot find a cookbook named #{cookbook.to_s}; did you forget to add metadata to a cookbook? (http://wiki.opscode.com/display/chef/Metadata)"
      end
    end

    alias :fetch :[]

    def has_key?(cookbook_name)
      not self[cookbook_name.to_sym].nil?
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
