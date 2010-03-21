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
require 'chef/cookbook'
require 'chef/cookbook/metadata'

class Chef
  class CookbookLoader
    
    attr_accessor :cookbook, :metadata
    
    include Enumerable
    
    def initialize()
      @cookbook = Hash.new
      @metadata = Hash.new
      @ignore_regexes = Hash.new { |hsh, key| hsh[key] = Array.new }
      load_cookbooks
    end
    
    def load_cookbooks
      cookbook_settings = Hash.new
      [Chef::Config.cookbook_path].flatten.each do |cb_path|
        Dir[File.join(cb_path, "*")].each do |cookbook|
          next unless File.directory?(cookbook)          
          cookbook_name = File.basename(cookbook).to_sym
          unless cookbook_settings.has_key?(cookbook_name)
            cookbook_settings[cookbook_name] = { 
              :attribute_files  => Hash.new,
              :definition_files => Hash.new,
              :recipe_files     => Hash.new,
              :template_files   => Hash.new,
              :remote_files     => Hash.new,
              :lib_files        => Hash.new,
              :resource_files   => Hash.new,
              :provider_files   => Hash.new,
              :metadata_files   => Array.new
            }
          end
          ignore_regexes = load_ignore_file(File.join(cookbook, "ignore"))
          @ignore_regexes[cookbook_name].concat(ignore_regexes)
          
          load_files_unless_basename(
            File.join(cookbook, "attributes", "*.rb"), 
            cookbook_settings[cookbook_name][:attribute_files]
          )
          load_files_unless_basename(
            File.join(cookbook, "definitions", "*.rb"), 
            cookbook_settings[cookbook_name][:definition_files]
          )
          load_files_unless_basename(
            File.join(cookbook, "recipes", "*.rb"), 
            cookbook_settings[cookbook_name][:recipe_files]
          )
          load_files_unless_basename(
            File.join(cookbook, "libraries", "*.rb"),               
            cookbook_settings[cookbook_name][:lib_files]
          )
          load_cascading_files(
            "*",
            File.join(cookbook, "templates"),
            cookbook_settings[cookbook_name][:template_files]
          )
          load_cascading_files(
            "*",
            File.join(cookbook, "files"),
            cookbook_settings[cookbook_name][:remote_files]
          )
          load_cascading_files(
            "*.rb",
            File.join(cookbook, "resources"),
            cookbook_settings[cookbook_name][:resource_files]
          )
          load_cascading_files(
            "*.rb",
            File.join(cookbook, "providers"),
            cookbook_settings[cookbook_name][:provider_files]
          )

          if File.exists?(File.join(cookbook, "metadata.json"))
            cookbook_settings[cookbook_name][:metadata_files] << File.join(cookbook, "metadata.json")
          end
        end
      end
      remove_ignored_files_from(cookbook_settings)
      
      cookbook_settings.each_key do |cookbook|
        @cookbook[cookbook] = Chef::Cookbook.new(cookbook)
        @cookbook[cookbook].attribute_files = cookbook_settings[cookbook][:attribute_files].values
        @cookbook[cookbook].definition_files = cookbook_settings[cookbook][:definition_files].values
        @cookbook[cookbook].recipe_files = cookbook_settings[cookbook][:recipe_files].values
        @cookbook[cookbook].template_files = cookbook_settings[cookbook][:template_files].values
        @cookbook[cookbook].remote_files = cookbook_settings[cookbook][:remote_files].values
        @cookbook[cookbook].lib_files = cookbook_settings[cookbook][:lib_files].values
        @cookbook[cookbook].resource_files = cookbook_settings[cookbook][:resource_files].values
        @cookbook[cookbook].provider_files = cookbook_settings[cookbook][:provider_files].values
        @metadata[cookbook] = Chef::Cookbook::Metadata.new(@cookbook[cookbook])
        cookbook_settings[cookbook][:metadata_files].each do |meta_json|
          @metadata[cookbook].from_json(IO.read(meta_json))
        end
      end
    end
    
    def [](cookbook)
      if @cookbook.has_key?(cookbook.to_sym)
        @cookbook[cookbook.to_sym]
      else
        raise ArgumentError, "Cannot find a cookbook named #{cookbook.to_s}; did you forget to add metadata to a cookbook? (http://wiki.opscode.com/display/chef/Metadata)"
      end
    end
    
    def each
      @cookbook.keys.sort { |a,b| a.to_s <=> b.to_s }.each do |cname|
        yield @cookbook[cname]
      end
    end

    private
    
      def load_ignore_file(ignore_file)
        results = Array.new
        if File.exists?(ignore_file) && File.readable?(ignore_file)
          IO.foreach(ignore_file) do |line|
            next if line =~ /^#/
            next if line =~ /^\w*$/
            line.chomp!
            results << Regexp.new(line)
          end
        end
        results
      end
      
      def remove_ignored_files_from(cookbook_settings)
        file_types_to_inspect = [ :attribute_files, :definition_files, :recipe_files, :template_files, 
                                  :remote_files, :lib_files, :resource_files, :provider_files]
        
        @ignore_regexes.each do |cookbook_name, regexes|
          regexes.each do |regex|
            settings = cookbook_settings[cookbook_name]
            file_types_to_inspect.each do |file_type|
              settings[file_type].delete_if { |uniqname, fullpath| fullpath.match(regex) }
            end
          end
        end
      end
      
      def load_cascading_files(file_glob, base_path, result_hash)
        rm_base_path = /^#{base_path}\/(.+)$/
        # To handle dotfiles like .ssh
        Dir.glob(File.join(base_path, "**/#{file_glob}"), File::FNM_DOTMATCH).each do |file|
          result_hash[rm_base_path.match(file)[1]] = file
        end
      end
      
      def load_files_unless_basename(file_glob, result_hash)
        Dir[file_glob].each do |file|
          result_hash[File.basename(file)] = file
        end
      end
      
  end
end
