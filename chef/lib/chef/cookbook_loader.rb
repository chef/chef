#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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
      load_cookbooks
    end
    
    def load_cookbooks
      cookbook_settings = Hash.new
      Chef::Config.cookbook_path.each do |cb_path|
        Dir[File.join(cb_path, "*")].each do |cookbook|
          next unless File.directory?(cookbook)          
          cookbook_name = File.basename(cookbook).to_sym
          unless cookbook_settings.has_key?(cookbook_name)
            cookbook_settings[cookbook_name] = { 
              :ignore_regexes => Array.new,
              :attribute_files => Array.new,
              :definition_files => Array.new,
              :recipe_files => Array.new,
              :template_files => Array.new,
              :remote_files => Array.new,
              :lib_files => Array.new,
              :resource_files => Array.new,
              :provider_files => Array.new,
              :metadata_files => Array.new
            }
          end
          ignore_regexes = load_ignore_file(File.join(cookbook, "ignore"))
          cookbook_settings[cookbook_name][:ignore_regexes].concat(ignore_regexes)
          load_files_unless_basename(
            File.join(cookbook, "attributes", "*.rb"), 
            cookbook_settings[cookbook_name][:attribute_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_files_unless_basename(
            File.join(cookbook, "definitions", "*.rb"), 
            cookbook_settings[cookbook_name][:definition_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_files_unless_basename(
            File.join(cookbook, "recipes", "*.rb"), 
            cookbook_settings[cookbook_name][:recipe_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_files_unless_basename(
            File.join(cookbook, "libraries", "*.rb"),               
            cookbook_settings[cookbook_name][:lib_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_cascading_files(
            "*.erb",
            File.join(cookbook, "templates"),
            cookbook_settings[cookbook_name][:template_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_cascading_files(
            "*",
            File.join(cookbook, "files"),
            cookbook_settings[cookbook_name][:remote_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_cascading_files(
            "*.rb",
            File.join(cookbook, "resources"),
            cookbook_settings[cookbook_name][:resource_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_cascading_files(
            "*.rb",
            File.join(cookbook, "providers"),
            cookbook_settings[cookbook_name][:provider_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )

          if File.exists?(File.join(cookbook, "metadata.json"))
            cookbook_settings[cookbook_name][:metadata_files] << File.join(cookbook, "metadata.json")
          end
        end
      end
      cookbook_settings.each_key do |cookbook|
        @cookbook[cookbook] = Chef::Cookbook.new(cookbook)
        @cookbook[cookbook].attribute_files = cookbook_settings[cookbook][:attribute_files]
        @cookbook[cookbook].definition_files = cookbook_settings[cookbook][:definition_files]
        @cookbook[cookbook].recipe_files = cookbook_settings[cookbook][:recipe_files]
        @cookbook[cookbook].template_files = cookbook_settings[cookbook][:template_files]
        @cookbook[cookbook].remote_files = cookbook_settings[cookbook][:remote_files]
        @cookbook[cookbook].lib_files = cookbook_settings[cookbook][:lib_files]
        @cookbook[cookbook].resource_files = cookbook_settings[cookbook][:resource_files]
        @cookbook[cookbook].provider_files = cookbook_settings[cookbook][:provider_files]
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
      @cookbook.each_value do |cobject|
        yield cobject
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
      
      def load_cascading_files(file_glob, base_path, result_array, ignore_regexes)
        # To handle dotfiles like .ssh
        Dir.glob(File.join(base_path, "**/#{file_glob}"), File::FNM_DOTMATCH).each do |file|
          next if skip_file(file, ignore_regexes)
          file =~ /^#{base_path}\/(.+)$/
          singlecopy = $1
          unless result_array.detect { |f| f =~ /#{singlecopy}$/ }
            result_array << file
          end
        end
      end
      
      def load_files_unless_basename(file_glob, result_array, ignore_regexes)
        Dir[file_glob].each do |file|
          next if skip_file(file, ignore_regexes)
          file_basename = File.basename(file)
          # If we've seen a file with this basename before, skip it.
          unless result_array.detect { |f| File.basename(f) == file_basename }  
            result_array << file
          end
        end
      end
      
      def skip_file(file, ignore_regexes)
        skip = false
        ignore_regexes.each do |exp|
          skip = true if exp.match(file)
        end
        skip
      end
      
  end
end
