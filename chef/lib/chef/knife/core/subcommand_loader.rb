# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2009, 2011 Opscode, Inc.
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

require 'chef/version'
class Chef
  class Knife
    class SubcommandLoader

      attr_reader :chef_config_dir
      attr_reader :env

      def initialize(chef_config_dir, env=ENV)
        @chef_config_dir, @env = chef_config_dir, env
        @forced_activate = {}
      end

      # Load all the sub-commands
      def load_commands
        subcommand_files.each { |subcommand| Kernel.load subcommand }
        true
      end

      # Returns an Array of paths to knife commands located in chef_config_dir/plugins/knife/
      # and ~/.chef/plugins/knife/
      def site_subcommands
        user_specific_files = []

        if chef_config_dir
          user_specific_files.concat Dir.glob(File.expand_path("plugins/knife/*.rb", chef_config_dir))
        end

        # finally search ~/.chef/plugins/knife/*.rb
        user_specific_files.concat Dir.glob(File.join(env['HOME'], '.chef', 'plugins', 'knife', '*.rb')) if env['HOME']

        user_specific_files
      end

      # Returns a Hash of paths to knife commands built-in to chef, or installed via gem.
      # If rubygems is not installed, falls back to globbing the knife directory.
      # The Hash is of the form {"relative/path" => "/absolute/path"}
      #--
      # Note: the "right" way to load the plugins is to require the relative path, i.e.,
      #   require 'chef/knife/command'
      # but we're getting frustrated by bugs at every turn, and it's slow besides. So
      # subcommand loader has been modified to load the plugins by using Kernel.load
      # with the absolute path.
      def gem_and_builtin_subcommands
        # search all gems for chef/knife/*.rb
        require 'rubygems'
        find_subcommands_via_rubygems
      rescue LoadError
        find_subcommands_via_dirglob
      end

      def subcommand_files
        @subcommand_files ||= (gem_and_builtin_subcommands.values + site_subcommands).flatten.uniq
      end

      def find_subcommands_via_dirglob
        # The "require paths" of the core knife subcommands bundled with chef
        files = Dir[File.expand_path('../../../knife/*.rb', __FILE__)]
        subcommand_files = {}
        files.each do |knife_file|
          rel_path = knife_file[/#{CHEF_ROOT}#{Regexp.escape(File::SEPARATOR)}(.*)\.rb/,1]
          subcommand_files[rel_path] = knife_file
        end
        subcommand_files
      end

      def find_subcommands_via_rubygems
        files = find_files_latest_gems 'chef/knife/*.rb'
        subcommand_files = {}
        files.each do |file|
          rel_path = file[/(#{Regexp.escape File.join('chef', 'knife', '')}.*)\.rb/, 1]
          subcommand_files[rel_path] = file
        end

        subcommand_files.merge(find_subcommands_via_dirglob)
      end

      private

      def find_files_latest_gems(glob, check_load_path=true)
        files = []

        if check_load_path
          files = $LOAD_PATH.map { |load_path|
            Dir["#{File.expand_path glob, load_path}#{Gem.suffix_pattern}"]
          }.flatten.select { |file| File.file? file.untaint }
        end

        gem_files = latest_gem_specs.map do |spec|
          # Gem::Specification#matches_for_glob wasn't added until RubyGems 1.8
          if spec.respond_to? :matches_for_glob
            spec.matches_for_glob("#{glob}#{Gem.suffix_pattern}")
          else
            check_spec_for_glob(spec, glob)
          end
        end.flatten
        
        files.concat gem_files
        files.uniq! if check_load_path

        return files
      end

      def latest_gem_specs
        @latest_gem_specs ||= if Gem::Specification.respond_to? :latest_specs
          Gem::Specification.latest_specs
        else
          Gem.source_index.latest_specs
        end
      end

      def check_spec_for_glob(spec, glob)
        dirs = if spec.require_paths.size > 1 then
          "{#{spec.require_paths.join(',')}}"
        else
          spec.require_paths.first
        end
      
        glob = File.join("#{spec.full_gem_path}/#{dirs}", glob)
 
        Dir[glob].map { |f| f.untaint }
      end
    end
  end
end
