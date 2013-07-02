require 'rake'
require 'rake/tasklib'
require 'chef/cookbook/syntax_check'

class Chef
  module Tasks
    class CookbookSyntaxCheckTask < ::Rake::TaskLib
      attr_accessor :name, :cookbook_path, :cache_path

      def initialize(name = :cookbook_syntax_check)
        @name = name
        @cookbook_path = Dir.pwd
        @cache_path = File.join(ENV['HOME'], '.chef', 'checksums')
        yield self if block_given?
        define
      end

      def define
        desc "Check Syntax of Chef cookbook"
        task(name) do
          syntax_checker = Chef::Cookbook::SyntaxCheck.new(cookbook_path)
          syntax_checker.validated_files.instance_variable_set('@cache_path', cache_path) # TODO: fix SyntaxCheck to allow configurable cache_path

          fail "invalid ruby files" unless syntax_checker.validate_ruby_files
          fail "invalid templates" unless syntax_checker.validate_templates
        end
      end

    end
  end
end
