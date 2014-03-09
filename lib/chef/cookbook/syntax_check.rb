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

require 'pathname'
require 'stringio'
require 'erubis'
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
        # creating a file in the +cache_path+ directory.
        def initialize(cache_path=Chef::Config[:syntax_check_cache_path])
          @cache_path = cache_path
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
        @chefignore ||= Chefignore.new(cookbook_path)

        @validated_files = PersistentSet.new
      end

      def remove_ignored_files(file_list)
        return file_list unless @chefignore.ignores.length > 0
        file_list.reject do |full_path|
          cookbook_pn = Pathname.new cookbook_path
          full_pn = Pathname.new full_path
          relative_pn = full_pn.relative_path_from cookbook_pn
          @chefignore.ignored? relative_pn.to_s
        end
      end

      def ruby_files
        remove_ignored_files Dir[File.join(cookbook_path, '**', '*.rb')]
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
        remove_ignored_files Dir[File.join(cookbook_path, '**', '*.erb')]
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
        if validate_inline?
          validate_erb_file_inline(erb_file)
        else
          validate_erb_via_subcommand(erb_file)
        end
      end

      def validate_ruby_file(ruby_file)
        Chef::Log.debug("Testing #{ruby_file} for syntax errors...")
        if validate_inline?
          validate_ruby_file_inline(ruby_file)
        else
          validate_ruby_by_subcommand(ruby_file)
        end
      end

      # Whether or not we're running on a version of ruby that can support
      # inline validation. Inline validation relies on the `RubyVM` features
      # introduced with ruby 1.9, so 1.8 cannot be supported.
      def validate_inline?
        defined?(RubyVM::InstructionSequence)
      end

      # Validate the ruby code in an erb template. Uses RubyVM to do syntax
      # checking, so callers should check #validate_inline? before calling.
      def validate_erb_file_inline(erb_file)
        old_stderr = $stderr

        engine = Erubis::Eruby.new
        engine.convert!(IO.read(erb_file))

        ruby_code = engine.src

        # Even when we're compiling the code w/ RubyVM, syntax errors just
        # print to $stderr. We want to capture this and handle the printing
        # ourselves, so we must temporarily swap $stderr to capture the output.
        tmp_stderr = $stderr = StringIO.new

        abs_path = File.expand_path(erb_file)
        RubyVM::InstructionSequence.new(ruby_code, erb_file, abs_path, 0)

        true
      rescue SyntaxError
        $stderr = old_stderr
        invalid_erb_file(erb_file, tmp_stderr.string)
        false
      ensure
        # be paranoid about setting stderr back to the old value.
        $stderr = old_stderr if defined?(old_stderr) && old_stderr
      end

      # Validate the ruby code in an erb template. Pipes the output of `erubis
      # -x` to `ruby -c`, so it works with any ruby version, but is much slower
      # than the inline version.
      # --
      # TODO: This can be removed when ruby 1.8 support is dropped.
      def validate_erb_via_subcommand(erb_file)
        result = shell_out("erubis -x #{erb_file} | #{ruby} -c")
        result.error!
        true
      rescue Mixlib::ShellOut::ShellCommandFailed
        invalid_erb_file(erb_file, result.stderr)
        false
      end

      # Debug a syntax error in a template.
      def invalid_erb_file(erb_file, error_message)
        file_relative_path = erb_file[/^#{Regexp.escape(cookbook_path+File::Separator)}(.*)/, 1]
        Chef::Log.fatal("Erb template #{file_relative_path} has a syntax error:")
        error_message.each_line { |l| Chef::Log.fatal(l.chomp) }
        nil
      end

      # Validate the syntax of a ruby file. Uses (Ruby 1.9+ only) RubyVM to
      # compile the code without evaluating it or spawning a new process.
      # Callers should check #validate_inline? before calling.
      def validate_ruby_file_inline(ruby_file)
        # Even when we're compiling the code w/ RubyVM, syntax errors just
        # print to $stderr. We want to capture this and handle the printing
        # ourselves, so we must temporarily swap $stderr to capture the output.
        old_stderr = $stderr
        tmp_stderr = $stderr = StringIO.new
        abs_path = File.expand_path(ruby_file)
        file_content = IO.read(abs_path)
        RubyVM::InstructionSequence.new(file_content, ruby_file, abs_path, 0)
        true
      rescue SyntaxError
        $stderr = old_stderr
        invalid_ruby_file(ruby_file, tmp_stderr.string)
        false
      ensure
        # be paranoid about setting stderr back to the old value.
        $stderr = old_stderr if defined?(old_stderr) && old_stderr
      end

      # Validate the syntax of a ruby file by shelling out to `ruby -c`. Should
      # work for all ruby versions, but is slower and uses more resources than
      # the inline strategy.
      def validate_ruby_by_subcommand(ruby_file)
        result = shell_out("#{ruby} -c #{ruby_file}")
        result.error!
        true
      rescue Mixlib::ShellOut::ShellCommandFailed
        invalid_ruby_file(ruby_file, result.stderr)
        false
      end

      # Debugs ruby syntax errors by printing the path to the file and any
      # diagnostic info given in +error_message+
      def invalid_ruby_file(ruby_file, error_message)
        file_relative_path = ruby_file[/^#{Regexp.escape(cookbook_path+File::Separator)}(.*)/, 1]
        Chef::Log.fatal("Cookbook file #{file_relative_path} has a ruby syntax error:")
        error_message.each_line { |l| Chef::Log.fatal(l.chomp) }
        false
      end

      # Returns the full path to the running ruby.
      def ruby
        Gem.ruby
      end

    end
  end
end
