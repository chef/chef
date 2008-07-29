#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# 

class Chef
  class CookbookLoader
    
    attr_accessor :cookbook
    
    include Enumerable
    
    def initialize()
      @cookbook = Hash.new
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
            File.join(cookbook, "templates", "*.erb"), 
            cookbook_settings[cookbook_name][:template_files],
            cookbook_settings[cookbook_name][:ignore_regexes]
          )
          load_files_unless_basename(
             File.join(cookbook, "files", "*"), 
             cookbook_settings[cookbook_name][:remote_files],
             cookbook_settings[cookbook_name][:ignore_regexes]
           )
        end
      end
      cookbook_settings.each_key do |cookbook|
        @cookbook[cookbook] = Chef::Cookbook.new(cookbook)
        @cookbook[cookbook].attribute_files = cookbook_settings[cookbook][:attribute_files]
        @cookbook[cookbook].definition_files = cookbook_settings[cookbook][:definition_files]
        @cookbook[cookbook].recipe_files = cookbook_settings[cookbook][:recipe_files]
        @cookbook[cookbook].template_files = cookbook_settings[cookbook][:template_files]
        @cookbook[cookbook].remote_files = cookbook_settings[cookbook][:remote_files]
      end
    end
    
    def [](cookbook)
      if @cookbook.has_key?(cookbook.to_sym)
        @cookbook[cookbook.to_sym]
      else
        raise ArgumentError, "Cannot find a cookbook named #{cookbook.to_s}"
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
    
      def load_files_unless_basename(file_glob, result_array, ignore_regexes)
        Dir[file_glob].each do |file|
          skip = false
          ignore_regexes.each do |exp|
            skip = true if exp.match(file)
          end
          next if skip
          file_basename = File.basename(file)
          # If we've seen a file with this basename before, skip it.
          unless result_array.detect { |f| File.basename(f) == file_basename }  
            result_array << file
          end
        end
      end
      
  end
end