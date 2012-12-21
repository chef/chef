#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/mixin/shell_out'
require 'chef/mixin/checksum'

class Chef
  class Cookbook
    # == Chef::Cookbook::SyntaxCheck
    # Encapsulates the process of validating the ruby syntax of files in Chef
    # cookbooks.
    class SyntaxCheck

      # == Chef::Cookbook::SyntaxCheck::PersistentSet
      # Implements set behavior with disk-based persistence. Objects in the set
      # are expected to be strings containing only characters that are valid in
      # filenames.
      #
      # This class is used to track which files have been syntax checked so
      # that known good files are not rechecked.
      class PersistentSet

        attr_reader :cache_path

        # Create a new PersistentSet. Values in the set are persisted by
        # creating a file in the +cache_path+ directory. If not given, the
        # value of Chef::Config[:syntax_check_cache_path] is used; if that
        # value is not configured, the value of
        # Chef::Config[:cache_options][:path] is used.
        #--
        # history: prior to Chef 11, the cache implementation was based on
        # moneta and configured via cache_options[:path]. Knife configs
        # generated with Chef 11 will have `syntax_check_cache_path`, but older
        # configs will have `cache_options[:path]`. `cache_options` is marked
        # deprecated in chef/config.rb but doesn't currently trigger a warning.
        # See also: CHEF-3715
        def initialize(cache_path=nil)
          @cache_path = cache_path || Chef::Config[:syntax_check_cache_path] || Chef::Config[:cache_options][:path]
          @cache_path_created = false
        end

        # Adds +value+ to the set's collection.
        def add(value)
          ensure_cache_path_created
          FileUtils.touch(File.join(cache_path, value))
        end

        # Returns true if the set includes +value+
        def include?(value)
          File.exist?(File.join(cache_path, value))
        end

        private

        def ensure_cache_path_created
          return true if @cache_path_created
          FileUtils.mkdir_p(cache_path)
          @cache_path_created = true
        end

      end

      include Chef::Mixin::ShellOut
      include Chef::Mixin::Checksum

      attr_reader :cookbook_path

      # A PersistentSet object that tracks which files have already been
      # validated.
      attr_reader :validated_files

      # Creates a new SyntaxCheck given the +cookbook_name+ and a +cookbook_path+.
      # If no +cookbook_path+ is given, +Chef::Config.cookbook_path+ is used.
      def self.for_cookbook(cookbook_name, cookbook_path=nil)
        cookbook_path ||= Chef::Config.cookbook_path
        unless cookbook_path
          raise ArgumentError, "Cannot find cookbook #{cookbook_name} unless Chef::Config.cookbook_path is set or an explicit cookbook path is given"
        end
        new(File.join(cookbook_path, cookbook_name.to_s))
      end

      # Create a new SyntaxCheck object
      # === Arguments
      # cookbook_path::: the (on disk) path to the cookbook
      def initialize(cookbook_path)
        @cookbook_path = cookbook_path
        @validated_files = PersistentSet.new
      end

      def ruby_files
        Dir[File.join(cookbook_path, '**', '*.rb')]
      end

      def untested_ruby_files
        ruby_files.reject do |file|
          if validated?(file)
            Chef::Log.debug("Ruby file #{file} is unchanged, skipping syntax check")
            true
          else
            false
          end
        end
      end

      def template_files
        Dir[File.join(cookbook_path, '**', '*.erb')]
      end

      def untested_template_files
        template_files.reject do |file| 
          if validated?(file)
            Chef::Log.debug("Template #{file} is unchanged, skipping syntax check")
            true
          else
            false
          end
        end
      end

      def validated?(file)
        validated_files.include?(checksum(file))
      end

      def validated(file)
        validated_files.add(checksum(file))
      end

      def validate_ruby_files
        untested_ruby_files.each do |ruby_file|
          return false unless validate_ruby_file(ruby_file)
          validated(ruby_file)
        end
      end

      def validate_templates
        untested_template_files.each do |template|
          return false unless validate_template(template)
          validated(template)
        end
      end

      def validate_template(erb_file)
        Chef::Log.debug("Testing template #{erb_file} for syntax errors...")
        result = shell_out("erubis -x #{erb_file} | ruby -c")
        result.error!
        true
      rescue Mixlib::ShellOut::ShellCommandFailed
        file_relative_path = erb_file[/^#{Regexp.escape(cookbook_path+File::Separator)}(.*)/, 1]
        Chef::Log.fatal("Erb template #{file_relative_path} has a syntax error:")
        result.stderr.each_line { |l| Chef::Log.fatal(l.chomp) }
        false
      end

      def validate_ruby_file(ruby_file)
        Chef::Log.debug("Testing #{ruby_file} for syntax errors...")
        result = shell_out("ruby -c #{ruby_file}")
        result.error!
        true
      rescue Mixlib::ShellOut::ShellCommandFailed
        file_relative_path = ruby_file[/^#{Regexp.escape(cookbook_path+File::Separator)}(.*)/, 1]
        Chef::Log.fatal("Cookbook file #{file_relative_path} has a ruby syntax error:")
        result.stderr.each_line { |l| Chef::Log.fatal(l.chomp) }
        false
      end

    end
  end
end
